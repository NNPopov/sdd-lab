# FEATURE: posts._shared — PostItem and PostPage domain entities.
import uuid
from datetime import datetime

from pydantic import BaseModel


class PostItem(BaseModel):
    id: int
    title: str
    text: str
    media_url: str | None
    created_at: datetime
    created_by_user_id: int
    username: str
    status: str
    post_uuid: uuid.UUID


class PostPage(BaseModel):
    items: list[PostItem]
    total_count: int
    page: int
    items_per_page: int
