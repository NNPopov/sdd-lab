# FEATURE: get_user_tier — data adapter.
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from .....adapters.db.models.tier import Tier
from .....adapters.db.models.user import User
from ..domain.commands import GetUserTierQuery
from ..domain.entities import FoundUserTier, TierNotFound, UserNotFound
from ..domain.ports.get_user_tier_port import GetUserTierPort


class GetUserTierAdapter(GetUserTierPort):
    def __init__(self, session_factory: async_sessionmaker[AsyncSession]) -> None:
        self._session_factory = session_factory

    async def get(self, query: GetUserTierQuery) -> FoundUserTier | None | UserNotFound | TierNotFound:
        async with self._session_factory() as session:
            result = await session.execute(
                select(User).where(
                    User.username == query.username,
                    User.is_deleted == False,  # noqa: E712
                )
            )
            user_row = result.scalar_one_or_none()

        if user_row is None:
            return UserNotFound()
        if user_row.tier_id is None:
            return None

        async with self._session_factory() as session:
            result = await session.execute(select(Tier).where(Tier.id == user_row.tier_id))
            tier_row = result.scalar_one_or_none()

        if tier_row is None:
            return TierNotFound()
        return FoundUserTier(
            tier_id=tier_row.id,
            tier_name=tier_row.name,
            tier_created_at=tier_row.created_at,
        )
