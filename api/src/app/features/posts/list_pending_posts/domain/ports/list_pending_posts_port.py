# FEATURE: list_pending_posts — port protocol.
from typing import Protocol, runtime_checkable

from ..commands import ListPendingPostsQuery
from ..entities import PendingPostPage


@runtime_checkable
class ListPendingPostsPort(Protocol):
    async def list(self, query: ListPendingPostsQuery) -> PendingPostPage: ...
