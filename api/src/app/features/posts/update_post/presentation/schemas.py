# FEATURE: update_post — request/response schemas.
from pydantic import BaseModel, ConfigDict, Field


class UpdatePostRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    title: str | None = Field(default=None, min_length=2, max_length=30)
    text: str | None = Field(default=None, min_length=1, max_length=63206)
    media_url: str | None = Field(default=None, pattern=r"^(https?|ftp)://[^\s/$.?#].[^\s]*$")


class UpdatePostResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    message: str
