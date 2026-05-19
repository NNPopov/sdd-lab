# FEATURE: create_post — port protocol.
from typing import Protocol, runtime_checkable

from ...._shared.entities import PostAuthor
from ..commands import CreatePostInternalCommand
from ..entities import CreatedPost


@runtime_checkable
class CreatePostPort(Protocol):
    async def get_user_by_username(self, username: str) -> PostAuthor | None: ...
    async def create(self, command: CreatePostInternalCommand) -> CreatedPost: ...
