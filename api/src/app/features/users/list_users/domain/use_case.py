# FEATURE: list_users — use case.
from .commands import ListUsersQuery
from .entities import UserPage
from .ports.list_users_port import ListUsersPort


class ListUsersUseCase:
    def __init__(self, port: ListUsersPort) -> None:
        self._port = port

    async def __call__(self, query: ListUsersQuery) -> UserPage:
        return await self._port.list(query)
