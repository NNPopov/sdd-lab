# FEATURE: revise_post — request/response schemas.
import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict, model_validator


class RevisePostRequest(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    title: str | None = None
    text: str | None = None
    message: str | None = None

    @model_validator(mode="after")
    def at_least_one_field_required(self) -> "RevisePostRequest":
        if self.title is None and self.text is None:
            raise ValueError("At least one of title or text must be provided")
        return self


class RevisionLogEntrySchema(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    event_type: str
    action: str | None
    message: str | None
    created_at: datetime


class RevisePostResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    post_uuid: uuid.UUID
    title: str
    text: str
    status: str
    updated_at: datetime
    log_entry: RevisionLogEntrySchema
