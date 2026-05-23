# FEATURE: update_tier — data adapter.
from sqlalchemy import func, select, update
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from .....adapters.db.models.tier import Tier
from .....domain.errors import DuplicateValueDomainError
from ..._shared.entities import TierItem
from ..domain.ports.update_tier_port import UpdateTierPort


class UpdateTierAdapter(UpdateTierPort):
    def __init__(self, session_factory: async_sessionmaker[AsyncSession]) -> None:
        self._session_factory = session_factory

    async def get(self, name: str) -> TierItem | None:
        async with self._session_factory() as session:
            result = await session.execute(select(Tier).where(Tier.name == name))
            row = result.scalar_one_or_none()
            if row is None:
                return None
            return TierItem.model_validate(row)

    async def update(self, name: str, new_name: str) -> None:
        async with self._session_factory() as session:
            try:
                await session.execute(
                    update(Tier).where(Tier.name == name).values(name=new_name, updated_at=func.now())
                )
                await session.commit()
            except IntegrityError as exc:
                raise DuplicateValueDomainError("Tier name already exists") from exc
