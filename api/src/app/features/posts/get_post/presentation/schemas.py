# FEATURE: get_post — request/response schemas.
import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict


class GetPostResponse(BaseModel):
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
