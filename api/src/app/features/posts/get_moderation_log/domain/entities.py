# FEATURE: get_moderation_log — domain entities.
from datetime import datetime

from pydantic import BaseModel


class PostForModerationLog(BaseModel):
    id: int
    created_by_user_id: int


class ModerationLogEntry(BaseModel):
    id: int
    event_type: str
    action: str | None
    message: str | None
    created_at: datetime
    actor_user_id: int
    actor_username: str


class ModerationLog(BaseModel):
    items: list[ModerationLogEntry]
