# FEATURE: list_posts — port protocol.
from typing import Protocol, runtime_checkable

from ...._shared.entities import PostPage
from ..commands import ListPostsQuery


@runtime_checkable
class ListPostsPort(Protocol):
    async def list(self, query: ListPostsQuery) -> PostPage: ...
