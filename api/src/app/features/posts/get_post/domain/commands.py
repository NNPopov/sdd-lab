# FEATURE: get_post — domain query.
from pydantic import BaseModel


class GetPostQuery(BaseModel):
    user_id: int
    post_id: int
    requester_user_id: int | None = None
    requester_is_privileged: bool = False
