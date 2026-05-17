# FEATURE: revise_post — domain command.
import uuid

from pydantic import BaseModel


class RevisePostCommand(BaseModel):
    post_uuid: uuid.UUID
    requester_user_id: int
    title: str | None
    text: str | None
    message: str | None
