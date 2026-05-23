# FEATURE: list_tiers — request/response schemas.
from datetime import datetime

from pydantic import BaseModel, ConfigDict


class TierItemSchema(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    name: str
    created_at: datetime


class ListTiersResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    items: list[TierItemSchema]
    total_count: int
    page: int
    items_per_page: int
