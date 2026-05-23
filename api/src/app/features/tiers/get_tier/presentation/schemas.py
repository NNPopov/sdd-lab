# FEATURE: get_tier — request/response schemas.
from datetime import datetime

from pydantic import BaseModel, ConfigDict


class GetTierResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    name: str
    created_at: datetime
