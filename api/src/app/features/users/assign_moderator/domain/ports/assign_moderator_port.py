# FEATURE: assign_moderator — port protocol.
from typing import Protocol, runtime_checkable

from ..entities import AssignedUser


@runtime_checkable
class AssignModeratorPort(Protocol):
    async def get_by_id(self, user_id: int) -> AssignedUser | None: ...

    async def assign(self, target_user_id: int, granted_by_user_id: int) -> AssignedUser: ...
