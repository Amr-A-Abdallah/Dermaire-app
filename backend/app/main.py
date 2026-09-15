import os
from contextlib import asynccontextmanager
from fastapi import FastAPI, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.exceptions import RequestValidationError
from starlette.exceptions import HTTPException as StarletteHTTPException

from app.core.config import settings
from app.core.database import init_db
from app.core.exceptions import (
    DermaireException,
    dermaire_exception_handler,
    validation_exception_handler,
    starlette_http_exception_handler,
    unhandled_exception_handler
)
from app.api.v1.router import api_v1_router

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Initialize database tables
    init_db()
    # Ensure local upload directory exists
    os.makedirs(os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "uploads")), exist_ok=True)
    yield

app = FastAPI(
    title="Dermaire Personal Skin Lab API",
    version="1.0.0",
    description="""
## Dermaire Skin Lab Backend — Microsoft Imagine Cup 2027
Advanced Evidence-Based Clinical Skin Tracker & AI Assistant powered by:
- **Microsoft Azure Blob Storage** (Encrypted skin check-in photos with ephemeral SAS tokens)
- **Microsoft Azure AI Vision 4.0** (Erythema/Redness, texture smoothness, and lesion analysis)
- **Microsoft Azure OpenAI Service (GPT-4o)** (Responsible medical skin assistant)
- **Microsoft Azure AI Content Safety** (Real-time clinical emergency red-flag escalation)
- **PostgreSQL & Append-Only Clinical Audit Trails** (Doctor portal, consent, and tamper-evident logs)
    """,
    lifespan=lifespan,
    docs_url="/docs",
    redoc_url="/redoc",
    openapi_url="/openapi.json"
)

# CORS Middleware configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.BACKEND_CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Exception Handlers Registration
app.add_exception_handler(DermaireException, dermaire_exception_handler)
app.add_exception_handler(RequestValidationError, validation_exception_handler)
app.add_exception_handler(StarletteHTTPException, starlette_http_exception_handler)
app.add_exception_handler(Exception, unhandled_exception_handler)

from fastapi.responses import FileResponse

# Static files for local development fallback uploads and landing page
uploads_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "uploads"))
static_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "static"))
os.makedirs(uploads_dir, exist_ok=True)
os.makedirs(static_dir, exist_ok=True)
app.mount("/api/v1/static/uploads", StaticFiles(directory=uploads_dir), name="uploads")
app.mount("/static", StaticFiles(directory=static_dir), name="static")

@app.get("/", tags=["Showcase Landing Page"])
def serve_landing_page():
    index_path = os.path.join(static_dir, "index.html")
    if os.path.exists(index_path):
        return FileResponse(index_path)
    return {"message": "Dermaire Personal Skin Lab API is running. Visit /docs for Swagger UI."}

# Include API v1 Router
app.include_router(api_v1_router, prefix=settings.API_V1_STR)

@app.get("/health", tags=["System Health"])
def health_check():
    return {
        "status": "healthy",
        "project": settings.PROJECT_NAME,
        "edition": settings.IMAGINE_COP_EDITION,
        "azure_services": {
            "blob_storage": "Live" if settings.is_blob_live else "Local Mock / Offline Ready",
            "ai_vision": "Live" if settings.is_vision_live else "Local Mock / Offline Ready",
            "openai_gpt4o": "Live" if settings.is_openai_live else "Local Mock / Offline Ready",
            "content_safety": "Live" if settings.is_safety_live else "Local Rules / Offline Ready"
        }
    }
