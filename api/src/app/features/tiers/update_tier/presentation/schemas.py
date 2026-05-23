# FEATURE: update_tier — request/response schemas.
from pydantic import BaseModel, ConfigDict, Field


class UpdateTierRequest(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    new_name: str = Field(min_length=1)


class UpdateTierResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    message: str = "Tier updated"
