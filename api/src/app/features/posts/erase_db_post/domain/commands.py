# FEATURE: erase_db_post — domain command.
from pydantic import BaseModel


class EraseDbPostCommand(BaseModel):
    username: str
    post_id: int
