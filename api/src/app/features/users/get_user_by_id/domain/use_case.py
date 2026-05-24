# FEATURE: get_user_by_id — use case.
from .....domain.errors import NotFoundDomainError
from .commands import GetUserByIdQuery
from .entities import FoundUser
from .ports.get_user_by_id_port import GetUserByIdPort


class GetUserByIdUseCase:
    def __init__(self, port: GetUserByIdPort) -> None:
        self._port = port

    async def __call__(self, query: GetUserByIdQuery) -> FoundUser:
        result = await self._port.get(query)
        if result is None:
            raise NotFoundDomainError("User not found")
        return result
