# STABLE: Core schemas. Base mixins re-exported from domain/shared/ for backward compat.
# Token/Health/TokenBlacklist schemas remain here until Phase 5 (auth slice extraction).
from datetime import datetime

from pydantic import BaseModel

# -------------- base schema mixins (canonical location: domain/shared/base_schemas.py) --------------
from ..domain.shared.base_schemas import PersistentDeletion, TimestampSchema, UUIDSchema  # noqa: F401


# -------------- health --------------
class HealthCheck(BaseModel):
    status: str
    environment: str
    version: str
    timestamp: str


class ReadyCheck(BaseModel):
    status: str
    environment: str
    version: str
    app: str
    database: str
    redis: str
    timestamp: str


# -------------- token --------------
class Token(BaseModel):
    access_token: str
    token_type: str


class TokenData(BaseModel):
    username_or_email: str


class TokenBlacklistBase(BaseModel):
    token: str
    expires_at: datetime


class TokenBlacklistRead(TokenBlacklistBase):
    id: int


class TokenBlacklistCreate(TokenBlacklistBase):
    pass


class TokenBlacklistUpdate(TokenBlacklistBase):
    pass
