# FEATURE: create_user — port protocol.
from typing import Protocol, runtime_checkable

from ..commands import CreateUserInternalCommand
from ..entities import CreatedUser


@runtime_checkable
class CreateUserPort(Protocol):
    async def email_exists(self, email: str) -> bool: ...
    async def username_exists(self, username: str) -> bool: ...
    async def create(self, command: CreateUserInternalCommand) -> CreatedUser: ...
