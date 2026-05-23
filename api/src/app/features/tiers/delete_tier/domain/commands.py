# FEATURE: delete_tier — domain command.
from pydantic import BaseModel


class DeleteTierCommand(BaseModel):
    name: str
