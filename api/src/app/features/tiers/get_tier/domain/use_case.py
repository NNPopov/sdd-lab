# FEATURE: get_tier — use case.
from .....domain.errors import NotFoundDomainError
from ..._shared.entities import TierItem
from .commands import GetTierQuery
from .ports.get_tier_port import GetTierPort


class GetTierUseCase:
    def __init__(self, port: GetTierPort) -> None:
        self._port = port

    async def __call__(self, query: GetTierQuery) -> TierItem:
        result = await self._port.get(query)
        if result is None:
            raise NotFoundDomainError("Tier not found")
        return result
