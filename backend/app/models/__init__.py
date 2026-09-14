import uuid
from datetime import datetime, timezone
from sqlalchemy import (
    Column, String, Integer, Float, Boolean, DateTime, Date,
    ForeignKey, Text, JSON, Enum as SQLEnum
)
from sqlalchemy.orm import relationship
from app.core.database import Base

def gen_uuid() -> str:
    return str(uuid.uuid4())

def utc_now() -> datetime:
    return datetime.now(timezone.utc)

class User(Base):
    __tablename__ = "users"

    id = Column(String(36), primary_key=True, default=gen_uuid)
    email = Column(String(255), unique=True, index=True, nullable=False)
    hashed_password = Column(String(255), nullable=False)
    full_name = Column(String(255), nullable=False)
    role = Column(String(50), default="patient", nullable=False) # patient, doctor, admin, support
    
    # Medical Safety acceptance
    safety_accepted = Column(Boolean, default=False)
    safety_accepted_at = Column(DateTime, nullable=True)
    safety_policy_version = Column(String(20), default="1.0")
    
    # Skin Profile
    skin_type = Column(String(50), nullable=True)
    selected_goal = Column(String(100), default="Reduce Acne")
    skin_concerns = Column(JSON, default=lambda: ["Redness"])
    
    # Gamification
    tokens_balance = Column(Integer, default=6)
    baseline_checkins_count = Column(Integer, default=2)

    created_at = Column(DateTime, default=utc_now)
    updated_at = Column(DateTime, default=utc_now, onupdate=utc_now)

    products = relationship("Product", back_populates="user", cascade="all, delete-orphan")
    experiments = relationship("Experiment", back_populates="user", cascade="all, delete-orphan")
    checkins = relationship("CheckIn", back_populates="user", cascade="all, delete-orphan")
    redemptions = relationship("RewardRedemption", back_populates="user", cascade="all, delete-orphan")

class Product(Base):
    __tablename__ = "products"

    id = Column(String(36), primary_key=True, default=gen_uuid)
    user_id = Column(String(36), ForeignKey("users.id"), nullable=False, index=True)
    name = Column(String(255), nullable=False)
    brand = Column(String(255), nullable=True)
    category = Column(String(50), nullable=False, default="treatment")
    product_type = Column(String(100), nullable=True)
    active_ingredients = Column(JSON, default=list)
    skin_concerns = Column(JSON, default=list)
    usage_instructions = Column(Text, default="")
    frequency_per_week = Column(Integer, default=7)
    time_of_use = Column(String(50), default="evening") # morning, evening, both, asNeeded
    status = Column(String(50), default="active") # active, inactive, archived
    start_date = Column(DateTime, nullable=True)
    end_date = Column(DateTime, nullable=True)
    notes = Column(Text, nullable=True)
    image_url = Column(String(500), nullable=True)
    tags = Column(JSON, default=list)
    rating = Column(Float, nullable=True)
    in_routine = Column(Boolean, default=True)
    in_experiment = Column(Boolean, default=False)
    created_at = Column(DateTime, default=utc_now)
    updated_at = Column(DateTime, default=utc_now, onupdate=utc_now)

    user = relationship("User", back_populates="products")

class Experiment(Base):
    __tablename__ = "experiments"

    id = Column(String(36), primary_key=True, default=gen_uuid)
    user_id = Column(String(36), ForeignKey("users.id"), nullable=False, index=True)
    product_id = Column(String(36), ForeignKey("products.id"), nullable=True)
    target_days = Column(Integer, default=28)
    current_day = Column(Integer, default=1)
    status = Column(String(50), default="active") # baseline, active, paused, completed
    primary_concern = Column(String(100), default="texture")
    redness_delta_percent = Column(Float, default=-8.0)
    texture_delta_percent = Column(Float, default=-12.0)
    hydration_delta_percent = Column(Float, default=15.0)
    start_date = Column(DateTime, default=utc_now)
    end_date = Column(DateTime, nullable=True)
    created_at = Column(DateTime, default=utc_now)

    user = relationship("User", back_populates="experiments")
    checkins = relationship("CheckIn", back_populates="experiment")

class CheckIn(Base):
    __tablename__ = "checkins"

    id = Column(String(36), primary_key=True, default=gen_uuid)
    user_id = Column(String(36), ForeignKey("users.id"), nullable=False, index=True)
    experiment_id = Column(String(36), ForeignKey("experiments.id"), nullable=True)
    date_str = Column(String(50), nullable=False) # e.g. "2026-09-14"
    time_of_day = Column(String(20), default="Morning") # Morning, Evening
    hydration_score = Column(Float, default=75.0)
    texture_score = Column(Float, default=80.0)
    redness_score = Column(Float, default=20.0)
    notes = Column(Text, nullable=True)
    image_blob_name = Column(String(255), nullable=True)
    ai_vision_analysis = Column(JSON, nullable=True)
    created_at = Column(DateTime, default=utc_now)

    user = relationship("User", back_populates="checkins")
    experiment = relationship("Experiment", back_populates="checkins")

class DoctorPatientAccess(Base):
    __tablename__ = "doctor_patient_access"

    id = Column(String(36), primary_key=True, default=gen_uuid)
    doctor_id = Column(String(36), ForeignKey("users.id"), nullable=True, index=True)
    patient_id = Column(String(36), ForeignKey("users.id"), nullable=False, index=True)
    access_token = Column(String(255), unique=True, index=True, nullable=False)
    status = Column(String(50), default="pending") # pending, active, revoked, expired
    export_consent = Column(Boolean, default=True)
    expires_at = Column(DateTime, nullable=False)
    created_at = Column(DateTime, default=utc_now)

class ClinicalNote(Base):
    __tablename__ = "clinical_notes"

    id = Column(String(36), primary_key=True, default=gen_uuid)
    doctor_id = Column(String(36), ForeignKey("users.id"), nullable=False, index=True)
    patient_id = Column(String(36), ForeignKey("users.id"), nullable=False, index=True)
    content = Column(Text, nullable=False)
    priority = Column(String(50), default="routine") # routine, review, urgent
    follow_up = Column(String(100), nullable=True)
    created_at = Column(DateTime, default=utc_now)

class AuditLog(Base):
    __tablename__ = "audit_logs"

    id = Column(String(36), primary_key=True, default=gen_uuid)
    actor_id = Column(String(36), nullable=False, index=True)
    action = Column(String(255), nullable=False)
    target_resource = Column(String(255), nullable=False)
    details = Column(JSON, default=dict)
    ip_address = Column(String(50), nullable=True)
    created_at = Column(DateTime, default=utc_now)

class RewardRedemption(Base):
    __tablename__ = "reward_redemptions"

    id = Column(String(36), primary_key=True, default=gen_uuid)
    user_id = Column(String(36), ForeignKey("users.id"), nullable=False, index=True)
    reward_title = Column(String(255), nullable=False)
    tokens_spent = Column(Integer, default=10)
    created_at = Column(DateTime, default=utc_now)

    user = relationship("User", back_populates="redemptions")
