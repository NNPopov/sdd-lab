# FEATURE: delete_user — domain entities.
from pydantic import BaseModel


class DeleteUserTarget(BaseModel):
    id: int


class DeleteUserResult(BaseModel):
    message: str = "User deleted"
