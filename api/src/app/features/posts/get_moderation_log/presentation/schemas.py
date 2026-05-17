# FEATURE: get_moderation_log — request/response schemas.
from datetime import datetime

from pydantic import BaseModel, ConfigDict


class ModerationLogEntrySchema(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    event_type: str
    action: str | None
    message: str | None
    created_at: datetime
    actor_user_id: int
    actor_username: str


class GetModerationLogResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    items: list[ModerationLogEntrySchema]
