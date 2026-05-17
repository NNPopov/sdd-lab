# FEATURE: list_users — domain entities.
from pydantic import BaseModel


class ListedUser(BaseModel):
    id: int
    name: str
    username: str
    email: str
    profile_image_url: str
    tier_id: int | None


class UserPage(BaseModel):
    items: list[ListedUser]
    total_count: int
    page: int
    items_per_page: int
