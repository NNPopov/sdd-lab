# FEATURE: delete_user — port protocol.
from typing import Protocol, runtime_checkable

from ..entities import DeleteUserTarget


@runtime_checkable
class DeleteUserPort(Protocol):
    async def get_by_id(self, user_id: int) -> DeleteUserTarget | None: ...
    async def soft_delete(self, target_user_id: int) -> None: ...
