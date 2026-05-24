# FEATURE: delete_user — domain entities.
from pydantic import BaseModel


class DeleteUserTarget(BaseModel):
    id: int
    username: str


class DeleteUserResult(BaseModel):
    message: str = "User deleted"
