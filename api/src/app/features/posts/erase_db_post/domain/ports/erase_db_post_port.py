# FEATURE: erase_db_post — port protocol.
from typing import Protocol, runtime_checkable

from ...._shared.entities import PostAuthor
from ..entities import EraseDbPostRecord


@runtime_checkable
class EraseDbPostPort(Protocol):
    async def get_user_by_username(self, username: str) -> PostAuthor | None: ...
    async def find_post(self, post_id: int, owner_id: int) -> EraseDbPostRecord | None: ...
    async def hard_delete(self, post_id: int) -> None: ...
