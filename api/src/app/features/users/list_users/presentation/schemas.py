# FEATURE: list_users — request/response schemas.
from pydantic import BaseModel, ConfigDict


class ListedUserSchema(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    name: str
    username: str
    email: str
    profile_image_url: str
    tier_id: int | None


class ListUsersResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    items: list[ListedUserSchema]
    total_count: int
    page: int
    items_per_page: int
