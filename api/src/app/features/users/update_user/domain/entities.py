# FEATURE: update_user — domain entities.
from pydantic import BaseModel


class ExistingUser(BaseModel):
    id: int
    username: str
    email: str


class UpdatedUserResult(BaseModel):
    message: str = "User updated"
