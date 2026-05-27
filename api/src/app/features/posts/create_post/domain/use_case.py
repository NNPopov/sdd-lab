# FEATURE: create_post — use case.
from .....domain.errors import NotFoundDomainError
from ..._shared.policies import check_post_owner
from ..._shared.user_lookup_port import UserLookupPort
from .commands import CreatePostCommand, CreatePostInternalCommand
from .entities import CreatedPost
from .ports.create_post_port import CreatePostPort


class CreatePostUseCase:
    def __init__(self, port: CreatePostPort, user_lookup: UserLookupPort) -> None:
        self._port = port
        self._user_lookup = user_lookup

    async def __call__(self, command: CreatePostCommand) -> CreatedPost:
        author = await self._user_lookup.get_active_user_by_id(command.target_user_id)
        if author is None:
            raise NotFoundDomainError("User not found")
        check_post_owner(command.requester_user_id, author.id)
        internal = CreatePostInternalCommand(
            created_by_user_id=author.id,
            title=command.title,
            text=command.text,
            media_url=command.media_url,
        )
        return await self._port.create(internal)
