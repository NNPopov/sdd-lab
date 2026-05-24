# FEATURE: get_user_by_id — port protocol.
from typing import Protocol, runtime_checkable

from ..commands import GetUserByIdQuery
from ..entities import FoundUser


@runtime_checkable
class GetUserByIdPort(Protocol):
    async def get(self, query: GetUserByIdQuery) -> FoundUser | None: ...
