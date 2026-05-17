# FEATURE: get_user_by_username — port protocol.
from typing import Protocol, runtime_checkable

from ..commands import GetUserByUsernameQuery
from ..entities import FoundUser


@runtime_checkable
class GetUserByUsernamePort(Protocol):
    async def get(self, query: GetUserByUsernameQuery) -> FoundUser | None: ...
