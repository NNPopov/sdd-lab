# FEATURE: update_tier — domain command.
from pydantic import BaseModel


class UpdateTierCommand(BaseModel):
    name: str
    new_name: str
