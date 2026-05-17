# FEATURE: list_users — domain query.
from pydantic import BaseModel


class ListUsersQuery(BaseModel):
    page: int = 1
    items_per_page: int = 10
