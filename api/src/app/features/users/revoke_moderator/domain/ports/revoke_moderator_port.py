# FEATURE: revoke_moderator — port protocol.
from typing import Protocol, runtime_checkable

from ..entities import RevokedUser


@runtime_checkable
class RevokeModeratorPort(Protocol):
    async def get_by_id(self, user_id: int) -> RevokedUser | None: ...

    async def revoke(self, target_user_id: int) -> RevokedUser: ...
