from datetime import datetime
from typing import List, Optional, Any, Dict
from pydantic import BaseModel, EmailStr, Field, ConfigDict

# ==================== User & Auth Schemas ====================

class UserRegister(BaseModel):
    email: EmailStr
    password: str = Field(..., min_length=8, description="Password must be at least 8 characters with letters and numbers")
    full_name: str = Field(..., min_length=2, max_length=100)
    role: str = Field("patient", pattern="^(patient|doctor|admin|support)$")
    accept_safety: bool = Field(..., description="User must accept medical safety & responsibility terms")

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    expires_in: int
    user_id: str
    role: str
    full_name: str

class AcceptSafetyRequest(BaseModel):
    accepted: bool = Field(True)
    policy_version: str = Field("1.0")

class SkinProfileUpdate(BaseModel):
    skin_type: Optional[str] = Field(None, pattern="^(dry|oily|combination|normal|sensitive)$")
    selected_goal: Optional[str] = Field(None, max_length=100)
    skin_concerns: Optional[List[str]] = Field(None)

class UserOut(BaseModel):
    id: str
    email: EmailStr
    full_name: str
    role: str
    safety_accepted: bool
    safety_accepted_at: Optional[datetime] = None
    skin_type: Optional[str] = None
    selected_goal: str
    skin_concerns: List[str]
    tokens_balance: int
    baseline_checkins_count: int
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)

# ==================== Product Schemas ====================

class ProductCreate(BaseModel):
    name: str = Field(..., min_length=2, max_length=150)
    brand: Optional[str] = Field(None, max_length=100)
    category: str = Field("treatment", pattern="^(cleanser|toner|serum|moisturizer|treatment|sunscreen|other)$")
    product_type: Optional[str] = Field(None, max_length=100)
    active_ingredients: List[str] = Field(default_factory=list)
    skin_concerns: List[str] = Field(default_factory=list)
    usage_instructions: str = Field("", max_length=1000)
    frequency_per_week: int = Field(7, ge=1, le=14)
    time_of_use: str = Field("evening", pattern="^(morning|evening|both|asNeeded)$")
    tags: List[str] = Field(default_factory=list)
    in_routine: bool = True
    in_experiment: bool = False
    notes: Optional[str] = Field(None, max_length=1000)

class ProductUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=2, max_length=150)
    brand: Optional[str] = Field(None, max_length=100)
    category: Optional[str] = Field(None, pattern="^(cleanser|toner|serum|moisturizer|treatment|sunscreen|other)$")
    product_type: Optional[str] = None
    active_ingredients: Optional[List[str]] = None
    skin_concerns: Optional[List[str]] = None
    usage_instructions: Optional[str] = None
    frequency_per_week: Optional[int] = Field(None, ge=1, le=14)
    time_of_use: Optional[str] = Field(None, pattern="^(morning|evening|both|asNeeded)$")
    status: Optional[str] = Field(None, pattern="^(active|inactive|archived)$")
    in_routine: Optional[bool] = None
    in_experiment: Optional[bool] = None
    notes: Optional[str] = None
    rating: Optional[float] = Field(None, ge=1.0, le=5.0)

class ProductOut(BaseModel):
    id: str
    user_id: str
    name: str
    brand: Optional[str] = None
    category: str
    product_type: Optional[str] = None
    active_ingredients: List[str]
    skin_concerns: List[str]
    usage_instructions: str
    frequency_per_week: int
    time_of_use: str
    status: str
    rating: Optional[float] = None
    in_routine: bool
    in_experiment: bool
    tags: List[str]
    notes: Optional[str] = None
    image_url: Optional[str] = None
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)

class ProductInteractionCheckRequest(BaseModel):
    ingredients: List[str] = Field(..., min_length=2, description="List of active ingredients to evaluate")

class ConflictItem(BaseModel):
    ingredient_a: str
    ingredient_b: str
    severity: str # conflict, caution, safe
    reason: str
    recommendation: str

class ProductInteractionCheckResponse(BaseModel):
    is_safe: bool
    risk_level: str # safe, conflict, unknown
    conflicts: List[ConflictItem]
    advice: str

# ==================== Experiment Schemas ====================

class ExperimentCreate(BaseModel):
    product_id: Optional[str] = None
    target_days: int = Field(28, ge=7, le=90)
    primary_concern: str = Field("texture", max_length=100)

class ExperimentUpdate(BaseModel):
    status: Optional[str] = Field(None, pattern="^(baseline|active|paused|completed)$")
    current_day: Optional[int] = Field(None, ge=1, le=90)

class ExperimentOut(BaseModel):
    id: str
    user_id: str
    product_id: Optional[str] = None
    target_days: int
    current_day: int
    status: str
    primary_concern: str
    redness_delta_percent: float
    texture_delta_percent: float
    hydration_delta_percent: float
    start_date: datetime
    end_date: Optional[datetime] = None
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)

# ==================== CheckIn Schemas ====================

class CheckInCreate(BaseModel):
    experiment_id: Optional[str] = None
    time_of_day: str = Field("Morning", pattern="^(Morning|Evening)$")
    hydration_score: float = Field(75.0, ge=0.0, le=100.0)
    texture_score: float = Field(80.0, ge=0.0, le=100.0)
    redness_score: float = Field(20.0, ge=0.0, le=100.0)
    notes: Optional[str] = Field(None, max_length=1500)

class CheckInResponse(BaseModel):
    id: str
    user_id: str
    experiment_id: Optional[str] = None
    date_str: str
    time_of_day: str
    hydration_score: float
    texture_score: float
    redness_score: float
    notes: Optional[str] = None
    image_sas_url: Optional[str] = None
    ai_vision_analysis: Optional[Dict[str, Any]] = None
    tokens_earned: int = 1
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)

# ==================== Doctor & Consent Schemas ====================

class GenerateQrResponse(BaseModel):
    access_token: str
    qr_payload: str
    expires_at: datetime
    instructions: str

class ClaimAccessRequest(BaseModel):
    access_token: str

class ClinicalNoteCreate(BaseModel):
    content: str = Field(..., min_length=10, max_length=1500, description="Clinical note must be between 10 and 1500 characters")
    priority: str = Field("routine", pattern="^(routine|review|urgent)$")
    follow_up: Optional[str] = Field(None, max_length=100)

class ClinicalNoteOut(BaseModel):
    id: str
    doctor_id: str
    patient_id: str
    content: str
    priority: str
    follow_up: Optional[str] = None
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)

class DoctorPatientOut(BaseModel):
    patient_id: str
    full_name: str
    email: EmailStr
    skin_type: Optional[str] = None
    selected_goal: str
    last_check_in: str
    active_experiment: Optional[str] = None
    priority: str
    active_products_count: int
    notes: List[ClinicalNoteOut]

class AuditLogOut(BaseModel):
    id: str
    actor_id: str
    action: str
    target_resource: str
    details: Dict[str, Any]
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)

# ==================== Rewards Schemas ====================

class RewardBalanceOut(BaseModel):
    tokens_balance: int
    can_redeem: bool
    rewards_available: List[Dict[str, Any]]

class RewardRedeemRequest(BaseModel):
    reward_id: str = Field(..., description="ID or title of the reward tier")

class RewardRedemptionOut(BaseModel):
    id: str
    reward_title: str
    tokens_spent: int
    remaining_balance: int
    created_at: datetime

# ==================== Chat & AI Schemas ====================

class ChatMessageRequest(BaseModel):
    message: str = Field(..., min_length=1, max_length=2000)
    session_id: Optional[str] = None

class ChatMessageResponse(BaseModel):
    reply: str
    kind: str # education, uncertainty, escalation
    escalation_triggered: bool
    safety_details: Optional[Dict[str, Any]] = None
    azure_model_used: str
