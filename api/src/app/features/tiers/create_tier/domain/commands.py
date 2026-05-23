# FEATURE: create_tier — domain command.
from pydantic import BaseModel


class CreateTierCommand(BaseModel):
    name: str
