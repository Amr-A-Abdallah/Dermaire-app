from datetime import datetime, timezone
from typing import Any, Dict, List, Optional
from fastapi import Request, status
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError
from starlette.exceptions import HTTPException as StarletteHTTPException

class DermaireException(Exception):
    def __init__(
        self,
        message: str,
        error_code: str = "DERMAIRE_ERROR",
        status_code: int = status.HTTP_400_BAD_REQUEST,
        details: Optional[List[Dict[str, Any]]] = None
    ):
        super().__init__(message)
        self.message = message
        self.error_code = error_code
        self.status_code = status_code
        self.details = details or []

class EntityNotFoundException(DermaireException):
    def __init__(self, entity_name: str, entity_id: Any):
        super().__init__(
            message=f"{entity_name} with id '{entity_id}' was not found.",
            error_code="RESOURCE_NOT_FOUND",
            status_code=status.HTTP_404_NOT_FOUND
        )

class InvalidCredentialsException(DermaireException):
    def __init__(self, message: str = "Invalid email or password"):
        super().__init__(
            message=message,
            error_code="INVALID_CREDENTIALS",
            status_code=status.HTTP_401_UNAUTHORIZED
        )

class PermissionDeniedException(DermaireException):
    def __init__(self, message: str = "You do not have permission to access this clinical resource."):
        super().__init__(
            message=message,
            error_code="PERMISSION_DENIED",
            status_code=status.HTTP_403_FORBIDDEN
        )

class ClinicalConsentRequiredException(DermaireException):
    def __init__(self, message: str = "Active patient consent is required to access or export health records."):
        super().__init__(
            message=message,
            error_code="CLINICAL_CONSENT_REQUIRED",
            status_code=status.HTTP_403_FORBIDDEN
        )

class IngredientConflictException(DermaireException):
    def __init__(self, ingredient_a: str, ingredient_b: str, reason: str):
        super().__init__(
            message=f"Conflict detected between '{ingredient_a}' and '{ingredient_b}': {reason}",
            error_code="INGREDIENT_CONFLICT",
            status_code=status.HTTP_409_CONFLICT,
            details=[{"ingredient_a": ingredient_a, "ingredient_b": ingredient_b, "reason": reason}]
        )

class SafetyRedFlagException(DermaireException):
    def __init__(self, message: str, detected_symptom: str):
        super().__init__(
            message=message,
            error_code="URGENT_RED_FLAG_ESCALATION",
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            details=[{"symptom": detected_symptom, "guidance": "Seek urgent medical attention immediately."}]
        )

def create_error_response(
    status_code: int,
    error_code: str,
    message: str,
    path: str,
    details: Optional[List[Dict[str, Any]]] = None
) -> JSONResponse:
    return JSONResponse(
        status_code=status_code,
        content={
            "success": False,
            "statusCode": status_code,
            "errorCode": error_code,
            "message": message,
            "details": details or [],
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "path": path,
        }
    )

async def dermaire_exception_handler(request: Request, exc: DermaireException) -> JSONResponse:
    return create_error_response(
        status_code=exc.status_code,
        error_code=exc.error_code,
        message=exc.message,
        path=request.url.path,
        details=exc.details
    )

async def validation_exception_handler(request: Request, exc: RequestValidationError) -> JSONResponse:
    formatted_errors = []
    for err in exc.errors():
        loc = " -> ".join([str(l) for l in err.get("loc", [])])
        formatted_errors.append({
            "field": loc,
            "issue": err.get("msg", "Invalid input value"),
            "type": err.get("type", "value_error")
        })
    return create_error_response(
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        error_code="VALIDATION_ERROR",
        message="Request input validation failed. Please check the details provided.",
        path=request.url.path,
        details=formatted_errors
    )

async def starlette_http_exception_handler(request: Request, exc: StarletteHTTPException) -> JSONResponse:
    return create_error_response(
        status_code=exc.status_code,
        error_code="HTTP_ERROR",
        message=str(exc.detail),
        path=request.url.path
    )

async def unhandled_exception_handler(request: Request, exc: Exception) -> JSONResponse:
    return create_error_response(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        error_code="INTERNAL_SERVER_ERROR",
        message="An unexpected server error occurred. Our engineering team has been notified.",
        path=request.url.path,
        details=[{"debug": str(exc)}]
    )
