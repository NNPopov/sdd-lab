# FEATURE: revise_post — domain entities.
import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict


class PostForRevision(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    uuid: uuid.UUID
    status: str
    created_by_user_id: int


class RevisionLogEntry(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    event_type: str
    action: str | None
    message: str | None
    created_at: datetime


class RevisedPostResult(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    post_uuid: uuid.UUID
    title: str
    text: str
    status: str
    updated_at: datetime
    log_entry: RevisionLogEntry
