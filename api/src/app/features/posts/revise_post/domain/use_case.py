# FEATURE: revise_post — use case.
from .....domain.errors import ForbiddenDomainError, NotFoundDomainError
from .commands import RevisePostCommand
from .entities import RevisedPostResult
from .ports.revise_post_port import RevisePostPort


class RevisePostUseCase:
    def __init__(self, port: RevisePostPort) -> None:
        self._port = port

    async def __call__(self, command: RevisePostCommand) -> RevisedPostResult:
        post = await self._port.get_post_by_uuid(command.post_uuid)
        if post is None:
            raise NotFoundDomainError("Post not found")

        if post.created_by_user_id != command.requester_user_id:
            raise ForbiddenDomainError("You may only revise your own posts")

        if post.status != "changes_requested":
            raise ForbiddenDomainError("Post is not in changes_requested status")

        return await self._port.apply_revision(
            post.id,
            post.uuid,
            command.title,
            command.text,
            command.requester_user_id,
            command.message,
        )
