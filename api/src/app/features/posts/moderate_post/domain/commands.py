# FEATURE: moderate_post — domain command.
import uuid

from pydantic import BaseModel


class ModeratePostCommand(BaseModel):
    post_uuid: uuid.UUID
    requester_user_id: int
    requester_is_privileged: bool
    action: str
    message: str | None
