# FEATURE: update_user — use case.
from .....domain.errors import DuplicateValueDomainError, NotFoundDomainError
from ..._shared.policies import check_owner
from .commands import UpdateUserCommand
from .entities import UpdatedUserResult
from .ports.update_user_port import UpdateUserPort


class UpdateUserUseCase:
    def __init__(self, port: UpdateUserPort) -> None:
        self._port = port

    async def __call__(self, command: UpdateUserCommand) -> UpdatedUserResult:
        existing = await self._port.get_by_username(command.target_username)
        if existing is None:
            raise NotFoundDomainError("User not found")

        check_owner(command.requester_username, existing.username)

        if command.email is not None and command.email != existing.email:
            if await self._port.email_exists(command.email):
                raise DuplicateValueDomainError("Email is already registered")

        if command.username is not None and command.username != existing.username:
            if await self._port.username_exists(command.username):
                raise DuplicateValueDomainError("Username not available")

        await self._port.update(command)
        return UpdatedUserResult()
