# FEATURE: create_user — request/response schemas.
from typing import Annotated

from pydantic import BaseModel, ConfigDict, EmailStr, Field


class CreateUserRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    name: Annotated[str, Field(min_length=2, max_length=30)]
    username: Annotated[str, Field(min_length=2, max_length=20, pattern=r"^[a-z0-9_]+$")]
    email: EmailStr
    password: Annotated[str, Field(min_length=8, examples=["Str1ngst!"])]


class CreateUserResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    name: str
    username: str
    email: str
    profile_image_url: str
    tier_id: int | None
