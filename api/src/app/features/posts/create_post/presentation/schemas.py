# FEATURE: create_post — request/response schemas.
import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field


class CreatePostRequest(BaseModel):
    model_config = ConfigDict(extra="forbid", from_attributes=True)

    title: str = Field(min_length=1, max_length=30)
    text: str = Field(min_length=1, max_length=63206)
    media_url: str | None = None


class CreatePostResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    title: str
    text: str
    media_url: str | None
    created_by_user_id: int
    created_at: datetime
    status: str
    post_uuid: uuid.UUID
