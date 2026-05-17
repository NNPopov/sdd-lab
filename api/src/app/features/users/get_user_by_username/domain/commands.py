# FEATURE: get_user_by_username — domain query.
from pydantic import BaseModel


class GetUserByUsernameQuery(BaseModel):
    username: str
