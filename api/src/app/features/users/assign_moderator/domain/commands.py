# FEATURE: assign_moderator — domain command.
from pydantic import BaseModel


class AssignModeratorCommand(BaseModel):
    target_user_id: int
    requester_id: int
    requester_is_superuser: bool
