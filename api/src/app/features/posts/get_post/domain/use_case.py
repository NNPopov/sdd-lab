# FEATURE: get_post — use case.
from .....domain.errors import NotFoundDomainError
from ..._shared.entities import PostItem
from .commands import GetPostQuery
from .ports.get_post_port import GetPostPort


class GetPostUseCase:
    def __init__(self, port: GetPostPort) -> None:
        self._port = port

    async def __call__(self, query: GetPostQuery) -> PostItem:
        post = await self._port.get(query)
        if post is None:
            raise NotFoundDomainError("Post not found")
        if post.status != "approved":
            if query.requester_username == query.username:
                return post
            if query.requester_is_privileged:
                return post
            raise NotFoundDomainError("Post not found")
        return post
