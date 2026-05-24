# FEATURE: update_tier — domain command.
from pydantic import BaseModel


class UpdateTierCommand(BaseModel):
    id: int
    name: str
