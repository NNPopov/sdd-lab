# FEATURE: list_pending_posts — use case.
from .....domain.errors import ForbiddenDomainError
from .commands import ListPendingPostsQuery
from .entities import PendingPostPage
from .ports.list_pending_posts_port import ListPendingPostsPort


class ListPendingPostsUseCase:
    def __init__(self, port: ListPendingPostsPort) -> None:
        self._port = port

    async def __call__(self, query: ListPendingPostsQuery) -> PendingPostPage:
        if not query.requester_is_privileged:
            raise ForbiddenDomainError("Moderator or superuser privilege required")
        return await self._port.list(query)
