# FEATURE: create_tier — request/response schemas.
from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field


class CreateTierRequest(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    name: str = Field(min_length=1)


class CreateTierResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    name: str
    created_at: datetime
