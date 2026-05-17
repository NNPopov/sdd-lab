# FEATURE: list_pending_posts — request/response schemas.
import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict


class PendingModerationLogEntrySchema(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    event_type: str
    action: str | None
    message: str | None
    created_at: datetime


class PendingPostItemSchema(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    post_uuid: uuid.UUID
    title: str
    text: str
    media_url: str | None
    status: str
    created_at: datetime
    updated_at: datetime | None
    author_username: str
    moderation_log: list[PendingModerationLogEntrySchema]


class ListPendingPostsResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    items: list[PendingPostItemSchema]
    total_count: int
    page: int
    items_per_page: int
