# FEATURE: create_post — domain entities.
import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict


class PostAuthor(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    username: str


class CreatedPost(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    title: str
    text: str
    media_url: str | None
    created_by_user_id: int
    created_at: datetime
    status: str
    post_uuid: uuid.UUID
