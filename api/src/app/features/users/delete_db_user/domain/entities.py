# FEATURE: delete_db_user — domain entities.
from pydantic import BaseModel


class DbDeleteUserTarget(BaseModel):
    username: str


class DeleteDbUserResult(BaseModel):
    message: str = "User deleted from the database"
