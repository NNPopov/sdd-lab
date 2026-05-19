# FEATURE: get_post — port protocol.
from typing import Protocol, runtime_checkable

from ...._shared.entities import PostItem
from ..commands import GetPostQuery


@runtime_checkable
class GetPostPort(Protocol):
    async def get(self, query: GetPostQuery) -> PostItem | None: ...
