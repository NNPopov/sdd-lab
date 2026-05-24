# FEATURE: delete_user — domain command.
from pydantic import BaseModel


class DeleteUserCommand(BaseModel):
    target_user_id: int
    requester_user_id: int
