# FEATURE: erase_post — domain command.
from pydantic import BaseModel


class ErasePostCommand(BaseModel):
    user_id: int
    post_id: int
    requester_user_id: int
