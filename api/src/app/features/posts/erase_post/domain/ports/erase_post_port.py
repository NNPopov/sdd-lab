# FEATURE: erase_post — port protocol.
from typing import Protocol, runtime_checkable

from ..entities import ErasePostRecord


@runtime_checkable
class ErasePostPort(Protocol):
    async def find_post(self, post_id: int, owner_id: int) -> ErasePostRecord | None: ...
    async def soft_delete(self, post_id: int) -> None: ...
