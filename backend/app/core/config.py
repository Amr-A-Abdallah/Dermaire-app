from typing import List
from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=True,
        extra="ignore"
    )

    # App Identity
    PROJECT_NAME: str = "Dermaire Skin Lab API"
    VERSION: str = "1.0.0"
    API_V1_STR: str = "/api/v1"
    IMAGINE_COP_EDITION: str = "Microsoft Imagine Cup 2027"
    ENVIRONMENT: str = "development"
    DEBUG: bool = True

    # Security & Authentication
    SECRET_KEY: str = "dermaire-super-secret-azure-imagine-cup-key-2027-change-in-production"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24  # 24 hours
    REFRESH_TOKEN_EXPIRE_DAYS: int = 30

    # CORS
    BACKEND_CORS_ORIGINS: List[str] = [
        "http://localhost",
        "http://localhost:3000",
        "http://localhost:8080",
        "http://127.0.0.1",
        "*"
    ]

    # Database (Defaults to SQLite for instant local zero-dependency run, can switch to Azure Postgres)
    DATABASE_URL: str = "sqlite:///./dermaire_dev.db"

    # Microsoft Azure Blob Storage (Skin photos & medical reports)
    AZURE_STORAGE_CONNECTION_STRING: str = ""
    AZURE_STORAGE_CONTAINER: str = "skin-records"
    AZURE_BLOB_SAS_EXPIRY_MINUTES: int = 30

    # Microsoft Azure AI Vision (Image Analysis 4.0)
    AZURE_VISION_ENDPOINT: str = ""
    AZURE_VISION_KEY: str = ""

    # Microsoft Azure OpenAI Service (GPT-4o Medical Assistant)
    AZURE_OPENAI_ENDPOINT: str = ""
    AZURE_OPENAI_API_KEY: str = ""
    AZURE_OPENAI_DEPLOYMENT_NAME: str = "gpt-4o"
    AZURE_OPENAI_API_VERSION: str = "2024-08-01-preview"

    # Microsoft Azure AI Content Safety (Emergency Red Flag Escalation)
    AZURE_CONTENT_SAFETY_ENDPOINT: str = ""
    AZURE_CONTENT_SAFETY_KEY: str = ""

    # Mock mode flag: automatically active when Azure credentials are not provided
    @property
    def is_blob_live(self) -> bool:
        return bool(self.AZURE_STORAGE_CONNECTION_STRING)

    @property
    def is_vision_live(self) -> bool:
        return bool(self.AZURE_VISION_ENDPOINT and self.AZURE_VISION_KEY)

    @property
    def is_openai_live(self) -> bool:
        return bool(self.AZURE_OPENAI_ENDPOINT and self.AZURE_OPENAI_API_KEY)

    @property
    def is_safety_live(self) -> bool:
        return bool(self.AZURE_CONTENT_SAFETY_ENDPOINT and self.AZURE_CONTENT_SAFETY_KEY)

settings = Settings()
