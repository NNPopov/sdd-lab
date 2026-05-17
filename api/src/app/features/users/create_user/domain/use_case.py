# FEATURE: create_user — use case.
from collections.abc import Callable

from .....domain.errors import DuplicateValueDomainError
from .commands import CreateUserCommand, CreateUserInternalCommand
from .entities import CreatedUser
from .ports.create_user_port import CreateUserPort


class CreateUserUseCase:
    def __init__(self, port: CreateUserPort, password_hasher: Callable[[str], str]) -> None:
        self._port = port
        self._password_hasher = password_hasher

    async def __call__(self, command: CreateUserCommand) -> CreatedUser:
        if await self._port.email_exists(command.email):
            raise DuplicateValueDomainError("Email is already registered")
        if await self._port.username_exists(command.username):
            raise DuplicateValueDomainError("Username not available")
        internal = CreateUserInternalCommand(
            name=command.name,
            username=command.username,
            email=command.email,
            hashed_password=self._password_hasher(command.password),
        )
        return await self._port.create(internal)
