# FEATURE: delete_db_user — port protocol.
from typing import Protocol, runtime_checkable

from ..entities import DbDeleteUserTarget


@runtime_checkable
class DeleteDbUserPort(Protocol):
    async def get_by_id(self, user_id: int) -> DbDeleteUserTarget | None: ...
    async def db_delete(self, target_user_id: int) -> None: ...
