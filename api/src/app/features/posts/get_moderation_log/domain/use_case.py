# FEATURE: get_moderation_log — use case.
from .....domain.errors import ForbiddenDomainError, NotFoundDomainError
from .commands import GetModerationLogQuery
from .entities import ModerationLog
from .ports.get_moderation_log_port import GetModerationLogPort


class GetModerationLogUseCase:
    def __init__(self, port: GetModerationLogPort) -> None:
        self._port = port

    async def __call__(self, query: GetModerationLogQuery) -> ModerationLog:
        post = await self._port.get_post_by_uuid(query.post_uuid)
        if post is None:
            raise NotFoundDomainError("Post not found")

        if not (
            query.requester_user_id == post.created_by_user_id
            or query.requester_is_moderator
            or query.requester_is_superuser
        ):
            raise ForbiddenDomainError(
                "Access to moderation log requires being the author, a moderator, or a superuser"
            )

        entries = await self._port.get_log(post.id)
        return ModerationLog(items=entries)
