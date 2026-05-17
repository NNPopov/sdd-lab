# FEATURE: revoke_moderator — use case.
from .....domain.errors import DuplicateValueDomainError, ForbiddenDomainError, NotFoundDomainError
from .commands import RevokeModeratorCommand
from .entities import RevokedUser
from .ports.revoke_moderator_port import RevokeModeratorPort


class RevokeModeratorUseCase:
    def __init__(self, port: RevokeModeratorPort) -> None:
        self._port = port

    async def __call__(self, command: RevokeModeratorCommand) -> RevokedUser:
        if not command.requester_is_superuser:
            raise ForbiddenDomainError("Superuser privilege required")
        target = await self._port.get_by_username(command.target_username)
        if target is None:
            raise NotFoundDomainError("User not found")
        if not target.is_moderator:
            raise DuplicateValueDomainError("User is not a moderator")
        return await self._port.revoke(command.target_username)
