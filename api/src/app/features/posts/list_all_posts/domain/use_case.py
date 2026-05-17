# FEATURE: list_all_posts — use case.
from ..._shared.entities import PostPage
from .commands import ListAllPostsQuery
from .ports.list_all_posts_port import ListAllPostsPort


class ListAllPostsUseCase:
    def __init__(self, port: ListAllPostsPort) -> None:
        self._port = port

    async def __call__(self, query: ListAllPostsQuery) -> PostPage:
        return await self._port.list(query)
