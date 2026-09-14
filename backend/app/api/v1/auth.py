from datetime import datetime, timezone
from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.core.security import get_password_hash, verify_password, create_access_token
from app.core.config import settings
from app.core.exceptions import DermaireException, InvalidCredentialsException
from app.models import User
from app.schemas import UserRegister, UserLogin, TokenResponse, UserOut, AcceptSafetyRequest
from app.api.deps import get_current_user, record_audit

router = APIRouter(prefix="/auth", tags=["Authentication & Medical Safety"])

@router.post("/register", response_model=TokenResponse, status_code=status.HTTP_201_CREATED)
def register_user(payload: UserRegister, db: Session = Depends(get_db)):
    if not payload.accept_safety:
        raise DermaireException(
            message="Medical responsibility acceptance is mandatory to use Dermaire personal skin lab.",
            error_code="SAFETY_ACCEPTANCE_REQUIRED",
            status_code=status.HTTP_400_BAD_REQUEST
        )

    existing = db.query(User).filter(User.email == payload.email).first()
    if existing:
        raise DermaireException(
            message="An account with this email address already exists.",
            error_code="EMAIL_ALREADY_EXISTS",
            status_code=status.HTTP_409_CONFLICT
        )

    user = User(
        email=payload.email,
        hashed_password=get_password_hash(payload.password),
        full_name=payload.full_name,
        role=payload.role,
        safety_accepted=True,
        safety_accepted_at=datetime.now(timezone.utc),
        safety_policy_version="1.0",
        tokens_balance=6,
        baseline_checkins_count=2
    )
    db.add(user)
    db.commit()
    db.refresh(user)

    record_audit(db, user.id, "USER_REGISTERED", "users", {"email": user.email, "role": user.role})

    token = create_access_token(subject=user.id, role=user.role)
    return TokenResponse(
        access_token=token,
        token_type="bearer",
        expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
        user_id=user.id,
        role=user.role,
        full_name=user.full_name
    )

@router.post("/login", response_model=TokenResponse)
def login_user(payload: UserLogin, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == payload.email).first()
    if not user or not verify_password(payload.password, user.hashed_password):
        raise InvalidCredentialsException("Incorrect email or password. Please verify your credentials.")

    token = create_access_token(subject=user.id, role=user.role)
    record_audit(db, user.id, "USER_LOGGED_IN", "users", {"role": user.role})

    return TokenResponse(
        access_token=token,
        token_type="bearer",
        expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
        user_id=user.id,
        role=user.role,
        full_name=user.full_name
    )

@router.post("/accept-safety", response_model=UserOut)
def accept_safety_terms(
    payload: AcceptSafetyRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    current_user.safety_accepted = payload.accepted
    current_user.safety_accepted_at = datetime.now(timezone.utc)
    current_user.safety_policy_version = payload.policy_version
    db.commit()
    db.refresh(current_user)

    record_audit(db, current_user.id, "SAFETY_TERMS_ACCEPTED", "users", {"version": payload.policy_version})
    return current_user
