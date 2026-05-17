# FEATURE: revoke_moderator — domain entity.
from pydantic import BaseModel


class RevokedUser(BaseModel):
    id: int
    name: str
    username: str
    email: str
    profile_image_url: str
    tier_id: int | None
    is_moderator: bool
