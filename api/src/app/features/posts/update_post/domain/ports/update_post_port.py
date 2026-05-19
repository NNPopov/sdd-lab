# FEATURE: update_post — port protocol.
from typing import Protocol, runtime_checkable

from ...._shared.entities import PostAuthor, PostItem
from ..commands import UpdatePostCommand


@runtime_checkable
class UpdatePostPort(Protocol):
    async def get_user_by_username(self, username: str) -> PostAuthor | None: ...
    async def get_post_by_id(self, post_id: int) -> PostItem | None: ...
    async def update(self, command: UpdatePostCommand) -> None: ...
