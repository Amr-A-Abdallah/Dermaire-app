from datetime import datetime, timedelta, timezone
from typing import List, Optional
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.core.security import create_doctor_access_token, decode_token
from app.core.exceptions import (
    EntityNotFoundException, PermissionDeniedException, DermaireException
)
from app.api.deps import get_current_user, require_role, record_audit
from app.models import User, DoctorPatientAccess, ClinicalNote, CheckIn, Experiment, Product
from app.schemas import (
    GenerateQrResponse, ClaimAccessRequest, DoctorPatientOut,
    ClinicalNoteCreate, ClinicalNoteOut
)

router = APIRouter(prefix="/doctor", tags=["Doctor Portal, QR Access & Audit"])

@router.post("/generate-qr", response_model=GenerateQrResponse)
def generate_doctor_qr_access(
    minutes_valid: int = Query(60, ge=15, le=1440),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    token = create_doctor_access_token(current_user.id, minutes_valid=minutes_valid)
    expires_at = datetime.now(timezone.utc) + timedelta(minutes=minutes_valid)

    access_record = DoctorPatientAccess(
        patient_id=current_user.id,
        access_token=token,
        status="pending",
        export_consent=True,
        expires_at=expires_at
    )
    db.add(access_record)
    db.commit()

    record_audit(db, current_user.id, "DOCTOR_QR_GENERATED", "doctor_patient_access", {
        "expires_at": expires_at.isoformat(),
        "patient_id": current_user.id
    })

    return GenerateQrResponse(
        access_token=token,
        qr_payload=f"dermaire://doctor-access?token={token}",
        expires_at=expires_at,
        instructions="Present this QR code to your clinician. Access is temporary, encrypted, and can be revoked at any moment."
    )

@router.post("/claim", status_code=status.HTTP_200_OK)
def claim_patient_access(
    payload: ClaimAccessRequest,
    current_doctor: User = Depends(require_role(["doctor", "admin"])),
    db: Session = Depends(get_db)
):
    try:
        decoded = decode_token(payload.access_token)
        patient_id = decoded.get("patient_id")
        if not patient_id:
            raise DermaireException("Invalid QR access token payload.")
    except Exception:
        raise DermaireException("QR access code has expired or is invalid.")

    access_record = db.query(DoctorPatientAccess).filter(
        DoctorPatientAccess.access_token == payload.access_token
    ).first()
    if not access_record or access_record.status == "revoked":
        raise DermaireException("This access code is no longer valid or has been revoked by the patient.")

    if access_record.expires_at.replace(tzinfo=timezone.utc) < datetime.now(timezone.utc):
        access_record.status = "expired"
        db.commit()
        raise DermaireException("This clinical access code has expired.")

    access_record.doctor_id = current_doctor.id
    access_record.status = "active"
    db.commit()

    record_audit(db, current_doctor.id, "PATIENT_ACCESS_CLAIMED", "doctor_patient_access", {
        "patient_id": patient_id,
        "doctor_id": current_doctor.id
    })
    return {"success": True, "message": f"Access granted to patient record ({patient_id})."}

@router.delete("/revoke/{patient_id}", status_code=status.HTTP_200_OK)
def revoke_patient_access(
    patient_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # Patient can revoke their own access
    if current_user.id != patient_id and current_user.role != "admin":
        raise PermissionDeniedException("You can only revoke access for your own patient records.")

    records = db.query(DoctorPatientAccess).filter(
        DoctorPatientAccess.patient_id == patient_id,
        DoctorPatientAccess.status.in_(["active", "pending"])
    ).all()
    for r in records:
        r.status = "revoked"
    db.commit()

    record_audit(db, current_user.id, "PATIENT_ACCESS_REVOKED", "doctor_patient_access", {"patient_id": patient_id})
    return {"success": True, "message": "Clinician access revoked immediately."}

@router.get("/patients", response_model=List[DoctorPatientOut])
def list_authorized_patients(
    priority: Optional[str] = None,
    current_doctor: User = Depends(require_role(["doctor", "admin"])),
    db: Session = Depends(get_db)
):
    # Retrieve all active links for this doctor
    access_links = db.query(DoctorPatientAccess).filter(
        DoctorPatientAccess.doctor_id == current_doctor.id,
        DoctorPatientAccess.status == "active"
    ).all()

    patient_ids = [link.patient_id for link in access_links]
    patients = db.query(User).filter(User.id.in_(patient_ids)).all()

    results = []
    for p in patients:
        last_checkin = db.query(CheckIn).filter(CheckIn.user_id == p.id).order_by(CheckIn.created_at.desc()).first()
        active_exp = db.query(Experiment).filter(Experiment.user_id == p.id, Experiment.status == "active").first()
        active_products_cnt = db.query(Product).filter(Product.user_id == p.id, Product.status == "active").count()
        notes = db.query(ClinicalNote).filter(ClinicalNote.patient_id == p.id).order_by(ClinicalNote.created_at.desc()).all()

        p_priority = "routine"
        if notes and notes[0].priority:
            p_priority = notes[0].priority

        if priority and p_priority != priority:
            continue

        results.append(DoctorPatientOut(
            patient_id=p.id,
            full_name=p.full_name,
            email=p.email,
            skin_type=p.skin_type,
            selected_goal=p.selected_goal,
            last_check_in=last_checkin.date_str if last_checkin else "No check-ins yet",
            active_experiment=f"Day {active_exp.current_day} of {active_exp.target_days}" if active_exp else "Baseline",
            priority=p_priority,
            active_products_count=active_products_cnt,
            notes=[ClinicalNoteOut.model_validate(n) for n in notes]
        ))
    return results

@router.post("/patients/{patient_id}/notes", response_model=ClinicalNoteOut, status_code=status.HTTP_201_CREATED)
def add_clinical_note(
    patient_id: str,
    payload: ClinicalNoteCreate,
    current_doctor: User = Depends(require_role(["doctor", "admin"])),
    db: Session = Depends(get_db)
):
    # Verify doctor authorization
    authorized = db.query(DoctorPatientAccess).filter(
        DoctorPatientAccess.doctor_id == current_doctor.id,
        DoctorPatientAccess.patient_id == patient_id,
        DoctorPatientAccess.status == "active"
    ).first()
    if not authorized:
        raise PermissionDeniedException("You are not authorized to write notes for this patient.")

    note = ClinicalNote(
        doctor_id=current_doctor.id,
        patient_id=patient_id,
        content=payload.content,
        priority=payload.priority,
        follow_up=payload.follow_up
    )
    db.add(note)
    db.commit()
    db.refresh(note)

    record_audit(db, current_doctor.id, "CLINICAL_NOTE_ADDED", "clinical_notes", {
        "note_id": note.id,
        "patient_id": patient_id,
        "priority": payload.priority
    })

    return note
