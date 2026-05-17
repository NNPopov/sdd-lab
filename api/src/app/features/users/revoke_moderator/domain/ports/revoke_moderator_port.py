# FEATURE: revoke_moderator — port protocol.
from typing import Protocol, runtime_checkable

from ..entities import RevokedUser


@runtime_checkable
class RevokeModeratorPort(Protocol):
    async def get_by_username(self, username: str) -> RevokedUser | None: ...

    async def revoke(self, target_username: str) -> RevokedUser: ...
