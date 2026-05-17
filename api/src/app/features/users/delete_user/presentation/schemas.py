# FEATURE: delete_user — request/response schemas.
from pydantic import BaseModel


class DeleteUserResponse(BaseModel):
    message: str
