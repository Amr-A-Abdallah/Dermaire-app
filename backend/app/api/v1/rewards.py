from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.core.exceptions import DermaireException
from app.api.deps import get_current_user, record_audit
from app.models import User, RewardRedemption
from app.schemas import RewardBalanceOut, RewardRedeemRequest, RewardRedemptionOut

router = APIRouter(prefix="/rewards", tags=["Rewards & Gamification"])

AVAILABLE_REWARDS = [
    {"id": "travel_serum", "title": "Travel-size Hydrating Serum", "cost": 10, "category": "product"},
    {"id": "dermatologist_review", "title": "Expert Clinician Fast-Track Review", "cost": 25, "category": "clinical"},
    {"id": "advanced_analytics", "title": "AI Skin Barrier Deep Analysis Report", "cost": 15, "category": "digital"}
]

@router.get("/balance", response_model=RewardBalanceOut)
def get_rewards_balance(current_user: User = Depends(get_current_user)):
    return RewardBalanceOut(
        tokens_balance=current_user.tokens_balance,
        can_redeem=current_user.tokens_balance >= 10,
        rewards_available=AVAILABLE_REWARDS
    )

@router.post("/redeem", response_model=RewardRedemptionOut, status_code=status.HTTP_201_CREATED)
def redeem_reward(
    payload: RewardRedeemRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    reward = next((r for r in AVAILABLE_REWARDS if r["id"] == payload.reward_id or r["title"] == payload.reward_id), None)
    if not reward:
        raise DermaireException("Selected reward item is not available.")

    cost = reward["cost"]
    if current_user.tokens_balance < cost:
        raise DermaireException(
            message=f"Insufficient tokens. You have {current_user.tokens_balance} tokens, but {cost} are required.",
            error_code="INSUFFICIENT_TOKENS",
            status_code=status.HTTP_400_BAD_REQUEST
        )

    current_user.tokens_balance -= cost
    redemption = RewardRedemption(
        user_id=current_user.id,
        reward_title=reward["title"],
        tokens_spent=cost
    )
    db.add(redemption)
    db.commit()
    db.refresh(redemption)

    record_audit(db, current_user.id, "REWARD_REDEEMED", "reward_redemptions", {
        "reward_id": reward["id"],
        "tokens_spent": cost,
        "remaining": current_user.tokens_balance
    })

    return RewardRedemptionOut(
        id=redemption.id,
        reward_title=redemption.reward_title,
        tokens_spent=redemption.tokens_spent,
        remaining_balance=current_user.tokens_balance,
        created_at=redemption.created_at
    )
