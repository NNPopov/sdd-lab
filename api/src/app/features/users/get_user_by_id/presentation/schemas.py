# FEATURE: get_user_by_id — request/response schemas.
from pydantic import BaseModel, ConfigDict


class GetUserByIdResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    name: str
    username: str
    email: str
    profile_image_url: str
    tier_id: int | None
    is_moderator: bool
