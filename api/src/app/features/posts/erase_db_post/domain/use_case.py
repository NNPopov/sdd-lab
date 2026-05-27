# FEATURE: erase_db_post — use case.
from .....domain.errors import NotFoundDomainError
from ..._shared.user_lookup_port import UserLookupPort
from .commands import EraseDbPostCommand
from .ports.erase_db_post_port import EraseDbPostPort


class EraseDbPostUseCase:
    def __init__(self, port: EraseDbPostPort, user_lookup: UserLookupPort) -> None:
        self._port = port
        self._user_lookup = user_lookup

    async def __call__(self, command: EraseDbPostCommand) -> None:
        user = await self._user_lookup.get_active_user_by_id(command.user_id)
        if user is None:
            raise NotFoundDomainError("User not found")
        post = await self._port.find_post(command.post_id, owner_id=user.id)
        if post is None:
            raise NotFoundDomainError("Post not found")
        await self._port.hard_delete(command.post_id)
