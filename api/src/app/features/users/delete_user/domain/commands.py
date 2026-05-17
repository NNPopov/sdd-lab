# FEATURE: delete_user — domain command.
from pydantic import BaseModel


class DeleteUserCommand(BaseModel):
    target_username: str
    requester_username: str
