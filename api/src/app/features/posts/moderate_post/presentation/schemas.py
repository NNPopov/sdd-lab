# FEATURE: moderate_post — request/response schemas.
import uuid
from datetime import datetime
from typing import Literal

from pydantic import BaseModel, ConfigDict, model_validator


class ModeratePostRequest(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    action: Literal["approved", "changes_requested"]
    message: str | None = None

    @model_validator(mode="after")
    def message_required_for_changes(self) -> "ModeratePostRequest":
        if self.action == "changes_requested" and self.message is None:
            raise ValueError("message is required when action is changes_requested")
        return self


class ModerationLogEntrySchema(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    event_type: str
    action: str | None
    message: str | None
    created_at: datetime


class ModeratePostResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    post_uuid: uuid.UUID
    status: str
    log_entry: ModerationLogEntrySchema
