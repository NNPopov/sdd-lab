# FEATURE: get_tier — data adapter.
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from .....adapters.db.models.tier import Tier
from ..._shared.entities import TierItem
from ..domain.commands import GetTierQuery
from ..domain.ports.get_tier_port import GetTierPort


class GetTierAdapter(GetTierPort):
    def __init__(self, session_factory: async_sessionmaker[AsyncSession]) -> None:
        self._session_factory = session_factory

    async def get(self, query: GetTierQuery) -> TierItem | None:
        async with self._session_factory() as session:
            result = await session.execute(select(Tier).where(Tier.name == query.name))
            row = result.scalar_one_or_none()
            if row is None:
                return None
            return TierItem.model_validate(row)
