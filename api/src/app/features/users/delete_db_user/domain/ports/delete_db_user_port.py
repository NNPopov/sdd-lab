# FEATURE: delete_db_user — port protocol.
from typing import Protocol, runtime_checkable

from ..entities import DbDeleteUserTarget


@runtime_checkable
class DeleteDbUserPort(Protocol):
    async def get_by_username(self, username: str) -> DbDeleteUserTarget | None: ...
    async def db_delete(self, username: str) -> None: ...
