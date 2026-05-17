# FEATURE: get_user_tier — use case.
from .....domain.errors import NotFoundDomainError
from .commands import GetUserTierQuery
from .entities import FoundUserTier, TierNotFound, UserNotFound
from .ports.get_user_tier_port import GetUserTierPort


class GetUserTierUseCase:
    def __init__(self, port: GetUserTierPort) -> None:
        self._port = port

    async def __call__(self, query: GetUserTierQuery) -> FoundUserTier | None:
        result = await self._port.get(query)
        if isinstance(result, UserNotFound):
            raise NotFoundDomainError("User not found")
        if isinstance(result, TierNotFound):
            raise NotFoundDomainError("Tier not found")
        return result
