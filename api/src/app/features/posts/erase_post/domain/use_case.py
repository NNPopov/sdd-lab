# FEATURE: erase_post — use case.
from .....domain.errors import NotFoundDomainError
from ..._shared.policies import check_post_owner
from ..._shared.user_lookup_port import UserLookupPort
from .commands import ErasePostCommand
from .ports.erase_post_port import ErasePostPort


class ErasePostUseCase:
    def __init__(self, port: ErasePostPort, user_lookup: UserLookupPort) -> None:
        self._port = port
        self._user_lookup = user_lookup

    async def __call__(self, command: ErasePostCommand) -> None:
        user = await self._user_lookup.get_active_user_by_id(command.user_id)
        if user is None:
            raise NotFoundDomainError("User not found")
        check_post_owner(command.requester_user_id, user.id)
        post = await self._port.find_post(command.post_id, owner_id=user.id)
        if post is None:
            raise NotFoundDomainError("Post not found")
        await self._port.soft_delete(command.post_id)
