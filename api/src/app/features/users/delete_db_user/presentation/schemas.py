# FEATURE: delete_db_user — request/response schemas.
from pydantic import BaseModel


class DeleteDbUserResponse(BaseModel):
    message: str
