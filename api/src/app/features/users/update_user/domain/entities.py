# FEATURE: update_user — domain entities.
from pydantic import BaseModel


class ExistingUser(BaseModel):
    username: str
    email: str


class UpdatedUserResult(BaseModel):
    message: str = "User updated"
