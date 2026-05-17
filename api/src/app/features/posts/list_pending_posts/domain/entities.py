# FEATURE: list_pending_posts — domain entities.
import uuid
from datetime import datetime

from pydantic import BaseModel


class PendingModerationLogEntry(BaseModel):
    id: int
    event_type: str
    action: str | None
    message: str | None
    created_at: datetime


class PendingPostItem(BaseModel):
    post_uuid: uuid.UUID
    title: str
    text: str
    media_url: str | None
    status: str
    created_at: datetime
    updated_at: datetime | None
    author_username: str
    moderation_log: list[PendingModerationLogEntry]


class PendingPostPage(BaseModel):
    items: list[PendingPostItem]
    total_count: int
    page: int
    items_per_page: int
