# FEATURE: create_user — domain commands.
from pydantic import BaseModel


class CreateUserCommand(BaseModel):
    name: str
    username: str
    email: str
    password: str


class CreateUserInternalCommand(BaseModel):
    name: str
    username: str
    email: str
    hashed_password: str
