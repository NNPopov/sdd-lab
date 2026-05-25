# FEATURE: delete_db_user — domain command.
from pydantic import BaseModel


class DeleteDbUserCommand(BaseModel):
    target_user_id: int
