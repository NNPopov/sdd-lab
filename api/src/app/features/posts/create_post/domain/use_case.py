# FEATURE: create_post — use case.
from .....domain.errors import ForbiddenDomainError, NotFoundDomainError
from ..._shared.user_lookup_port import UserLookupPort
from .commands import CreatePostCommand, CreatePostInternalCommand
from .entities import CreatedPost
from .ports.create_post_port import CreatePostPort


class CreatePostUseCase:
    def __init__(self, port: CreatePostPort, user_lookup: UserLookupPort) -> None:
        self._port = port
        self._user_lookup = user_lookup

    async def __call__(self, command: CreatePostCommand) -> CreatedPost:
        author = await self._user_lookup.get_active_user_by_username(command.target_username)
        if author is None:
            raise NotFoundDomainError("User not found")
        if command.requester_username != author.username:
            raise ForbiddenDomainError("You can only post under your own username")
        internal = CreatePostInternalCommand(
            created_by_user_id=author.id,
            title=command.title,
            text=command.text,
            media_url=command.media_url,
        )
        return await self._port.create(internal)
