# FEATURE: update_user — domain command.
from pydantic import BaseModel


class UpdateUserCommand(BaseModel):
    target_username: str
    requester_username: str
    name: str | None = None
    username: str | None = None
    email: str | None = None
    profile_image_url: str | None = None
