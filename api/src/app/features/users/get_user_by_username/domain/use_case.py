# FEATURE: get_user_by_username — use case.
from .....domain.errors import NotFoundDomainError
from .commands import GetUserByUsernameQuery
from .entities import FoundUser
from .ports.get_user_by_username_port import GetUserByUsernamePort


class GetUserByUsernameUseCase:
    def __init__(self, port: GetUserByUsernamePort) -> None:
        self._port = port

    async def __call__(self, query: GetUserByUsernameQuery) -> FoundUser:
        result = await self._port.get(query)
        if result is None:
            raise NotFoundDomainError("User not found")
        return result
