# FEATURE: revoke_moderator — domain command.
from pydantic import BaseModel


class RevokeModeratorCommand(BaseModel):
    target_username: str
    requester_is_superuser: bool
