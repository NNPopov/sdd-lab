# FEATURE: list_posts — use case.
from ..._shared.entities import PostPage
from .commands import ListPostsQuery
from .ports.list_posts_port import ListPostsPort


class ListPostsUseCase:
    def __init__(self, port: ListPostsPort) -> None:
        self._port = port

    async def __call__(self, query: ListPostsQuery) -> PostPage:
        return await self._port.list(query)
