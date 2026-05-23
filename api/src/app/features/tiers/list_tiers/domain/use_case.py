# FEATURE: list_tiers — use case.
from ..._shared.entities import TierPage
from .commands import ListTiersQuery
from .ports.list_tiers_port import ListTiersPort


class ListTiersUseCase:
    def __init__(self, port: ListTiersPort) -> None:
        self._port = port

    async def __call__(self, query: ListTiersQuery) -> TierPage:
        return await self._port.list(query)
