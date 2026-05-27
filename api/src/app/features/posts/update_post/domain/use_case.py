# FEATURE: update_post — use case.
from .....domain.errors import NotFoundDomainError
from ..._shared.policies import check_post_owner
from ..._shared.user_lookup_port import UserLookupPort
from .commands import UpdatePostCommand
from .ports.update_post_port import UpdatePostPort


class UpdatePostUseCase:
    def __init__(self, port: UpdatePostPort, user_lookup: UserLookupPort) -> None:
        self._port = port
        self._user_lookup = user_lookup

    async def __call__(self, command: UpdatePostCommand) -> None:
        author = await self._user_lookup.get_active_user_by_id(command.target_user_id)
        if author is None:
            raise NotFoundDomainError("User not found")
        check_post_owner(command.requester_user_id, author.id)
        post = await self._port.get_post_by_id(command.post_id)
        if post is None:
            raise NotFoundDomainError("Post not found")
        await self._port.update(command)
