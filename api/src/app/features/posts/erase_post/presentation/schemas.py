# FEATURE: erase_post — request/response schemas.
from pydantic import BaseModel


class ErasePostResponse(BaseModel):
    message: str
