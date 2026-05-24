# FEATURE: get_user_by_id — domain query.
from pydantic import BaseModel


class GetUserByIdQuery(BaseModel):
    user_id: int
