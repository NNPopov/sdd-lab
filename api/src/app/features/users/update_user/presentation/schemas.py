# FEATURE: update_user — request/response schemas.
from pydantic import BaseModel, ConfigDict, EmailStr, Field


class UpdateUserRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    name: str | None = Field(default=None, min_length=2, max_length=30)
    username: str | None = Field(default=None, min_length=2, max_length=20, pattern=r"^[a-z0-9_]+$")
    email: EmailStr | None = None
    profile_image_url: str | None = None


class UpdateUserResponse(BaseModel):
    message: str
