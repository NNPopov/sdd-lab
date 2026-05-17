# FEATURE: moderate_post — use case.
from .....domain.errors import DuplicateValueDomainError, ForbiddenDomainError, NotFoundDomainError
from .commands import ModeratePostCommand
from .entities import ModeratedPostResult
from .ports.moderate_post_port import ModeratePostPort


class ModeratePostUseCase:
    def __init__(self, port: ModeratePostPort) -> None:
        self._port = port

    async def __call__(self, command: ModeratePostCommand) -> ModeratedPostResult:
        if not command.requester_is_privileged:
            raise ForbiddenDomainError("Moderator or superuser privilege required")

        post = await self._port.get_post_by_uuid(command.post_uuid)
        if post is None:
            raise NotFoundDomainError("Post not found")

        if post.created_by_user_id == command.requester_user_id:
            raise ForbiddenDomainError("Moderators may not review their own posts")

        if post.status == "approved":
            raise DuplicateValueDomainError("Post is already approved")

        if command.action == "changes_requested" and command.message is None:
            raise ForbiddenDomainError("A message is required when requesting changes")

        return await self._port.apply_decision(
            post.id,
            post.uuid,
            command.action,
            command.requester_user_id,
            command.message,
        )
