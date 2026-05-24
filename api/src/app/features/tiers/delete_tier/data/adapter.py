# FEATURE: delete_tier — data adapter.
from sqlalchemy import delete, select
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from .....adapters.db.models.tier import Tier
from ..._shared.entities import TierItem
from ..domain.ports.delete_tier_port import DeleteTierPort


class DeleteTierAdapter(DeleteTierPort):
    def __init__(self, session_factory: async_sessionmaker[AsyncSession]) -> None:
        self._session_factory = session_factory

    async def get(self, tier_id: int) -> TierItem | None:
        async with self._session_factory() as session:
            result = await session.execute(select(Tier).where(Tier.id == tier_id))
            row = result.scalar_one_or_none()
            if row is None:
                return None
            return TierItem.model_validate(row)

    async def delete(self, tier_id: int) -> None:
        async with self._session_factory() as session:
            await session.execute(delete(Tier).where(Tier.id == tier_id))
            await session.commit()
