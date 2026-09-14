from datetime import datetime, timezone
from typing import List, Optional
from fastapi import APIRouter, Depends, UploadFile, File, Form, status
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.api.deps import get_current_user, record_audit
from app.models import User, CheckIn, Experiment
from app.schemas import CheckInResponse
from app.services.azure_blob import azure_blob_service
from app.services.azure_vision import azure_vision_service

router = APIRouter(prefix="/checkins", tags=["Daily Skin Check-ins & Journal"])

@router.get("", response_model=List[CheckInResponse])
def get_checkins_history(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    checkins = db.query(CheckIn).filter(
        CheckIn.user_id == current_user.id
    ).order_by(CheckIn.created_at.desc()).all()

    results = []
    for c in checkins:
        sas_url = None
        if c.image_blob_name:
            sas_url = azure_blob_service.generate_sas_url(c.image_blob_name)
        results.append(CheckInResponse(
            id=c.id,
            user_id=c.user_id,
            experiment_id=c.experiment_id,
            date_str=c.date_str,
            time_of_day=c.time_of_day,
            hydration_score=c.hydration_score,
            texture_score=c.texture_score,
            redness_score=c.redness_score,
            notes=c.notes,
            image_sas_url=sas_url,
            ai_vision_analysis=c.ai_vision_analysis,
            tokens_earned=1,
            created_at=c.created_at
        ))
    return results

@router.post("", response_model=CheckInResponse, status_code=status.HTTP_201_CREATED)
async def submit_daily_checkin(
    time_of_day: str = Form("Morning"),
    hydration_score: float = Form(75.0),
    texture_score: float = Form(80.0),
    redness_score: float = Form(20.0),
    notes: Optional[str] = Form(None),
    experiment_id: Optional[str] = Form(None),
    photo: Optional[UploadFile] = File(None),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    blob_name = None
    sas_url = None
    ai_analysis = None

    if photo and photo.filename:
        photo_bytes = await photo.read()
        # Upload to Azure Blob with SAS
        blob_name, sas_url = azure_blob_service.upload_image(
            file_bytes=photo_bytes,
            original_filename=photo.filename,
            content_type=photo.content_type or "image/jpeg"
        )
        # Process visual features via Azure Vision
        ai_analysis = azure_vision_service.analyze_skin_image(photo_bytes)
        # Override scores if vision generated real measurements
        if "erythema_redness_score" in ai_analysis:
            redness_score = ai_analysis["erythema_redness_score"]
            texture_score = ai_analysis["surface_texture_score"]
            hydration_score = ai_analysis["estimated_hydration_score"]

    # Advance experiment if linked
    if experiment_id:
        exp = db.query(Experiment).filter(
            Experiment.id == experiment_id,
            Experiment.user_id == current_user.id
        ).first()
        if exp and exp.status == "active":
            exp.current_day = min(exp.target_days, exp.current_day + 1)
            # Recompute deltas
            exp.redness_delta_percent = round((redness_score - 30.0) / 30.0 * 100.0, 1)
            exp.texture_delta_percent = round((texture_score - 70.0) / 70.0 * 100.0, 1)

    now = datetime.now(timezone.utc)
    checkin = CheckIn(
        user_id=current_user.id,
        experiment_id=experiment_id,
        date_str=now.strftime("%b %d, %Y"),
        time_of_day=time_of_day,
        hydration_score=hydration_score,
        texture_score=texture_score,
        redness_score=redness_score,
        notes=notes,
        image_blob_name=blob_name,
        ai_vision_analysis=ai_analysis,
        created_at=now
    )
    db.add(checkin)

    # Award gamification token
    current_user.tokens_balance += 1

    db.commit()
    db.refresh(checkin)

    record_audit(db, current_user.id, "CHECKIN_COMPLETED", "checkins", {
        "checkin_id": checkin.id,
        "has_photo": bool(blob_name)
    })

    return CheckInResponse(
        id=checkin.id,
        user_id=checkin.user_id,
        experiment_id=checkin.experiment_id,
        date_str=checkin.date_str,
        time_of_day=checkin.time_of_day,
        hydration_score=checkin.hydration_score,
        texture_score=checkin.texture_score,
        redness_score=checkin.redness_score,
        notes=checkin.notes,
        image_sas_url=sas_url,
        ai_vision_analysis=checkin.ai_vision_analysis,
        tokens_earned=1,
        created_at=checkin.created_at
    )
