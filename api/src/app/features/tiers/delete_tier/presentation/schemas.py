# FEATURE: delete_tier — request/response schemas.
from pydantic import BaseModel, ConfigDict


class DeleteTierResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    message: str = "Tier deleted"
