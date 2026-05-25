# FEATURE: revoke_moderator — domain command.
from pydantic import BaseModel


class RevokeModeratorCommand(BaseModel):
    target_user_id: int
    requester_is_superuser: bool
