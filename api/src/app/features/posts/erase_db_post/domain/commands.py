# FEATURE: erase_db_post — domain command.
from pydantic import BaseModel


class EraseDbPostCommand(BaseModel):
    user_id: int
    post_id: int
