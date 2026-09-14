from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.api.deps import get_current_user, record_audit
from app.models import User
from app.schemas import UserOut, SkinProfileUpdate

router = APIRouter(prefix="/users", tags=["User Profile & Skin Setup"])

@router.get("/me", response_model=UserOut)
def get_current_user_profile(current_user: User = Depends(get_current_user)):
    return current_user

@router.patch("/skin-profile", response_model=UserOut)
def update_skin_profile(
    payload: SkinProfileUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if payload.skin_type is not None:
        current_user.skin_type = payload.skin_type
    if payload.selected_goal is not None:
        current_user.selected_goal = payload.selected_goal
    if payload.skin_concerns is not None:
        current_user.skin_concerns = payload.skin_concerns

    db.commit()
    db.refresh(current_user)

    record_audit(db, current_user.id, "SKIN_PROFILE_UPDATED", "users", {
        "skin_type": current_user.skin_type,
        "selected_goal": current_user.selected_goal,
        "concerns": current_user.skin_concerns
    })
    return current_user
