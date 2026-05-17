# FEATURE: list_all_posts — port protocol.
from typing import Protocol, runtime_checkable

from ...._shared.entities import PostPage
from ..commands import ListAllPostsQuery


@runtime_checkable
class ListAllPostsPort(Protocol):
    async def list(self, query: ListAllPostsQuery) -> PostPage: ...
