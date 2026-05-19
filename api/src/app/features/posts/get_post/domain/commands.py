# FEATURE: get_post — domain query.
from pydantic import BaseModel


class GetPostQuery(BaseModel):
    username: str
    post_id: int
    requester_username: str | None = None
    requester_is_privileged: bool = False
