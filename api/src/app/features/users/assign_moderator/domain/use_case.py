# FEATURE: assign_moderator — use case.
from .....domain.errors import DuplicateValueDomainError, ForbiddenDomainError, NotFoundDomainError
from .commands import AssignModeratorCommand
from .entities import AssignedUser
from .ports.assign_moderator_port import AssignModeratorPort


class AssignModeratorUseCase:
    def __init__(self, port: AssignModeratorPort) -> None:
        self._port = port

    async def __call__(self, command: AssignModeratorCommand) -> AssignedUser:
        if not command.requester_is_superuser:
            raise ForbiddenDomainError("Superuser privilege required")
        target = await self._port.get_by_username(command.target_username)
        if target is None:
            raise NotFoundDomainError("User not found")
        if target.is_moderator:
            raise DuplicateValueDomainError("User is already a moderator")
        return await self._port.assign(command.target_username, command.requester_id)
