# FEATURE: create_user — domain entity returned by the use case.
from pydantic import BaseModel


class CreatedUser(BaseModel):
    id: int
    name: str
    username: str
    email: str
    profile_image_url: str
    tier_id: int | None
