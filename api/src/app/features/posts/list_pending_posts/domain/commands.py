# FEATURE: list_pending_posts — domain query.
from pydantic import BaseModel


class ListPendingPostsQuery(BaseModel):
    page: int = 1
    items_per_page: int = 10
    requester_is_privileged: bool
