# FEATURE: erase_db_post — request/response schemas.
from pydantic import BaseModel


class EraseDbPostResponse(BaseModel):
    message: str
