# FEATURE: list_tiers — domain query.
from pydantic import BaseModel


class ListTiersQuery(BaseModel):
    page: int = 1
    items_per_page: int = 10
