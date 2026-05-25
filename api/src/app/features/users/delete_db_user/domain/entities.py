# FEATURE: delete_db_user — domain entities.
from pydantic import BaseModel


class DbDeleteUserTarget(BaseModel):
    id: int


class DeleteDbUserResult(BaseModel):
    message: str = "User deleted from the database"
