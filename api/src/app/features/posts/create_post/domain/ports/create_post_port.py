# FEATURE: create_post — port protocol.
from typing import Protocol, runtime_checkable

from ..commands import CreatePostInternalCommand
from ..entities import CreatedPost


@runtime_checkable
class CreatePostPort(Protocol):
    async def create(self, command: CreatePostInternalCommand) -> CreatedPost: ...
