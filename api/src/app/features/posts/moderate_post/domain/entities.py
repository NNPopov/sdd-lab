# FEATURE: moderate_post — domain entities.
import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict


class PostForModeration(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    uuid: uuid.UUID
    status: str
    created_by_user_id: int


class ModerationLogEntry(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    event_type: str
    action: str | None
    message: str | None
    created_at: datetime


class ModeratedPostResult(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    post_uuid: uuid.UUID
    status: str
    log_entry: ModerationLogEntry
