# FEATURE: list_tiers — data adapter.
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from .....adapters.db.models.tier import Tier
from ..._shared.entities import TierItem, TierPage
from ..domain.commands import ListTiersQuery
from ..domain.ports.list_tiers_port import ListTiersPort


class ListTiersAdapter(ListTiersPort):
    def __init__(self, session_factory: async_sessionmaker[AsyncSession]) -> None:
        self._session_factory = session_factory

    async def list(self, query: ListTiersQuery) -> TierPage:
        async with self._session_factory() as session:
            total_count: int = (await session.execute(select(func.count()).select_from(Tier))).scalar_one()

            offset = (query.page - 1) * query.items_per_page
            rows = (
                (await session.execute(select(Tier).order_by(Tier.id).offset(offset).limit(query.items_per_page)))
                .scalars()
                .all()
            )

        items = [TierItem(id=row.id, name=row.name, created_at=row.created_at) for row in rows]
        return TierPage(
            items=items,
            total_count=total_count,
            page=query.page,
            items_per_page=query.items_per_page,
        )
