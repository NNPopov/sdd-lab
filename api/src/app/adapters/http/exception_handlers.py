# STABLE: Maps domain errors to HTTP responses. Change only when HTTP status mapping changes.
from fastapi import Request
from fastapi.responses import JSONResponse

from ...domain.errors import (
    DomainError,
    DuplicateValueDomainError,
    ForbiddenDomainError,
    NotFoundDomainError,
)

# Mapping: domain exception type -> HTTP status code
STATUS_MAP: dict[type[DomainError], int] = {
    NotFoundDomainError: 404,
    DuplicateValueDomainError: 409,  # Conflict
    ForbiddenDomainError: 403,
}


async def domain_error_handler(request: Request, exc: Exception) -> JSONResponse:
    assert isinstance(exc, DomainError)
    status_code = STATUS_MAP.get(type(exc), 500)

    return JSONResponse(
        status_code=status_code,
        content={
            "error": {
                "code": exc.code,
                "message": exc.message,
            }
        },
    )
