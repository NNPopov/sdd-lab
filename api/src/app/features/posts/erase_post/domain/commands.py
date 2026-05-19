# FEATURE: erase_post — domain command.
from pydantic import BaseModel


class ErasePostCommand(BaseModel):
    username: str
    post_id: int
    requester_username: str
