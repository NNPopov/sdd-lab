# FEATURE: list_posts — domain query.
from pydantic import BaseModel


class ListPostsQuery(BaseModel):
    username: str
    page: int = 1
    items_per_page: int = 10
    requester_username: str | None = None
