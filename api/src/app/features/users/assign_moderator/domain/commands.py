# FEATURE: assign_moderator — domain command.
from pydantic import BaseModel


class AssignModeratorCommand(BaseModel):
    target_username: str
    requester_id: int
    requester_is_superuser: bool
