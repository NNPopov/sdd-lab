# FEATURE: list_all_posts — request/response schemas.
import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict


class PostItemSchema(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    title: str
    text: str
    media_url: str | None
    created_at: datetime
    created_by_user_id: int
    username: str
    status: str
    post_uuid: uuid.UUID


class ListAllPostsResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    items: list[PostItemSchema]
    total_count: int
    page: int
    items_per_page: int
