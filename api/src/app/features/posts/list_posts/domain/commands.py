# FEATURE: list_posts — domain query.
from pydantic import BaseModel


class ListPostsQuery(BaseModel):
    user_id: int
    page: int = 1
    items_per_page: int = 10
    requester_user_id: int | None = None
