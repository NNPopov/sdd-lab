# FEATURE: tasks — schemas.
from pydantic import BaseModel


class Job(BaseModel):
    id: str
