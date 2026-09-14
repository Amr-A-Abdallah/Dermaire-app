import os
import uuid
from datetime import datetime, timedelta, timezone
from typing import Optional, Tuple
from app.core.config import settings

class AzureBlobService:
    def __init__(self):
        self.is_live = settings.is_blob_live
        if self.is_live:
            from azure.storage.blob import BlobServiceClient
            self.client = BlobServiceClient.from_connection_string(settings.AZURE_STORAGE_CONNECTION_STRING)
            self.container_client = self.client.get_container_client(settings.AZURE_STORAGE_CONTAINER)
            try:
                self.container_client.create_container()
            except Exception:
                pass
        else:
            self.local_upload_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "uploads"))
            os.makedirs(self.local_upload_dir, exist_ok=True)

    def upload_image(self, file_bytes: bytes, original_filename: str, content_type: str = "image/jpeg") -> Tuple[str, str]:
        ext = os.path.splitext(original_filename)[1] or ".jpg"
        blob_name = f"skin_photos/{uuid.uuid4()}{ext}"

        if self.is_live:
            from azure.storage.blob import ContentSettings
            blob_client = self.container_client.get_blob_client(blob_name)
            blob_client.upload_blob(file_bytes, overwrite=True, content_settings=ContentSettings(content_type=content_type))
            sas_url = self.generate_sas_url(blob_name)
            return blob_name, sas_url
        else:
            local_path = os.path.join(self.local_upload_dir, os.path.basename(blob_name))
            with open(local_path, "wb") as f:
                f.write(file_bytes)
            return blob_name, f"/api/v1/static/uploads/{os.path.basename(blob_name)}"

    def generate_sas_url(self, blob_name: str, expiry_minutes: int = 30) -> str:
        if not self.is_live:
            return f"/api/v1/static/uploads/{os.path.basename(blob_name)}"

        from azure.storage.blob import generate_blob_sas, BlobSasPermissions
        sas_token = generate_blob_sas(
            account_name=self.client.account_name,
            container_name=settings.AZURE_STORAGE_CONTAINER,
            blob_name=blob_name,
            account_key=self.client.credential.account_key,
            permission=BlobSasPermissions(read=True),
            expiry=datetime.now(timezone.utc) + timedelta(minutes=expiry_minutes)
        )
        return f"https://{self.client.account_name}.blob.core.windows.net/{settings.AZURE_STORAGE_CONTAINER}/{blob_name}?{sas_token}"

azure_blob_service = AzureBlobService()
