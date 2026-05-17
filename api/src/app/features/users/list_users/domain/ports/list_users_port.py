# FEATURE: list_users — port protocol.
from typing import Protocol, runtime_checkable

from ..commands import ListUsersQuery
from ..entities import UserPage


@runtime_checkable
class ListUsersPort(Protocol):
    async def list(self, query: ListUsersQuery) -> UserPage: ...
