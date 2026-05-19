# FEATURE: erase_db_post — use case.
from .....domain.errors import NotFoundDomainError
from .commands import EraseDbPostCommand
from .ports.erase_db_post_port import EraseDbPostPort


class EraseDbPostUseCase:
    def __init__(self, port: EraseDbPostPort) -> None:
        self._port = port

    async def __call__(self, command: EraseDbPostCommand) -> None:
        user = await self._port.get_user_by_username(command.username)
        if user is None:
            raise NotFoundDomainError("User not found")
        post = await self._port.find_post(command.post_id, owner_id=user.id)
        if post is None:
            raise NotFoundDomainError("Post not found")
        await self._port.hard_delete(command.post_id)
