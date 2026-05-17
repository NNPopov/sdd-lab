# FEATURE: create_post — domain commands.
from pydantic import BaseModel


class CreatePostCommand(BaseModel):
    target_username: str
    requester_username: str
    title: str
    text: str
    media_url: str | None


class CreatePostInternalCommand(BaseModel):
    created_by_user_id: int
    title: str
    text: str
    media_url: str | None
