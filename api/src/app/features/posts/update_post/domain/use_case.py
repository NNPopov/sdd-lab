# FEATURE: update_post — use case.
from .....domain.errors import ForbiddenDomainError, NotFoundDomainError
from .commands import UpdatePostCommand
from .ports.update_post_port import UpdatePostPort


class UpdatePostUseCase:
    def __init__(self, port: UpdatePostPort) -> None:
        self._port = port

    async def __call__(self, command: UpdatePostCommand) -> None:
        author = await self._port.get_user_by_username(command.target_username)
        if author is None:
            raise NotFoundDomainError("User not found")
        if command.requester_username != author.username:
            raise ForbiddenDomainError("You can only update your own posts")
        post = await self._port.get_post_by_id(command.post_id)
        if post is None:
            raise NotFoundDomainError("Post not found")
        await self._port.update(command)
