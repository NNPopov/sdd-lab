# FEATURE: get_user_tier — domain query.
from pydantic import BaseModel


class GetUserTierQuery(BaseModel):
    username: str
