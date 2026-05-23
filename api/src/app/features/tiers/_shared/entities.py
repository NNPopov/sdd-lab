# FEATURE: tiers._shared — domain entities.
from datetime import datetime

from pydantic import BaseModel, ConfigDict


class TierItem(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    name: str
    created_at: datetime


class TierPage(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    items: list[TierItem]
    total_count: int
    page: int
    items_per_page: int
