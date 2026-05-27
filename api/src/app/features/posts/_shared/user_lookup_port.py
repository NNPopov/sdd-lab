# FEATURE: posts._shared — UserLookupPort protocol.
from typing import Protocol, runtime_checkable

from .entities import UserIdentity


@runtime_checkable
class UserLookupPort(Protocol):
    async def get_active_user_by_id(self, user_id: int) -> UserIdentity | None: ...
