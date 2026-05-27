# FEATURE: update_post — domain command.
from pydantic import BaseModel


class UpdatePostCommand(BaseModel):
    target_user_id: int
    requester_user_id: int
    post_id: int
    title: str | None = None
    text: str | None = None
    media_url: str | None = None
