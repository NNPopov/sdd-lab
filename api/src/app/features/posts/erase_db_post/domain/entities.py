# FEATURE: erase_db_post — domain entities.
from pydantic import BaseModel


class EraseDbPostRecord(BaseModel):
    id: int
