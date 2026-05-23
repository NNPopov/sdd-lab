# FEATURE: create_tier — data adapter.
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from .....adapters.db.models.tier import Tier
from .....domain.errors import DuplicateValueDomainError
from ..._shared.entities import TierItem
from ..domain.commands import CreateTierCommand
from ..domain.ports.create_tier_port import CreateTierPort


class CreateTierAdapter(CreateTierPort):
    def __init__(self, session_factory: async_sessionmaker[AsyncSession]) -> None:
        self._session_factory = session_factory

    async def create(self, command: CreateTierCommand) -> TierItem:
        async with self._session_factory() as session:
            tier = Tier(name=command.name)
            session.add(tier)
            try:
                await session.commit()
            except IntegrityError as exc:
                raise DuplicateValueDomainError("Tier name already exists") from exc
            await session.refresh(tier)
            return TierItem.model_validate(tier)
