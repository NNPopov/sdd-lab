# FEATURE: get_tier — domain query.
from pydantic import BaseModel


class GetTierQuery(BaseModel):
    id: int
