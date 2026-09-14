from fastapi import APIRouter
from app.api.v1.auth import router as auth_router
from app.api.v1.users import router as users_router
from app.api.v1.products import router as products_router
from app.api.v1.experiments import router as experiments_router
from app.api.v1.checkins import router as checkins_router
from app.api.v1.doctor import router as doctor_router
from app.api.v1.rewards import router as rewards_router
from app.api.v1.chat import router as chat_router

api_v1_router = APIRouter()
api_v1_router.include_router(auth_router)
api_v1_router.include_router(users_router)
api_v1_router.include_router(products_router)
api_v1_router.include_router(experiments_router)
api_v1_router.include_router(checkins_router)
api_v1_router.include_router(doctor_router)
api_v1_router.include_router(rewards_router)
api_v1_router.include_router(chat_router)
