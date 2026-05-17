# FEATURE: get_user_tier — request/response schemas.
from datetime import datetime

from pydantic import BaseModel, ConfigDict


class GetUserTierResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    tier_id: int
    tier_name: str
    tier_created_at: datetime
