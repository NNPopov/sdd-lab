# FEATURE: erase_post — domain entities.
from pydantic import BaseModel


class ErasePostRecord(BaseModel):
    id: int
