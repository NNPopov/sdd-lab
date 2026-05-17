# FEATURE: list_users — data adapter.
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from .....adapters.db.models.user import User
from ..domain.commands import ListUsersQuery
from ..domain.entities import ListedUser, UserPage
from ..domain.ports.list_users_port import ListUsersPort


class ListUsersAdapter(ListUsersPort):
    def __init__(self, session_factory: async_sessionmaker[AsyncSession]) -> None:
        self._session_factory = session_factory

    async def list(self, query: ListUsersQuery) -> UserPage:
        async with self._session_factory() as session:
            count_result = await session.execute(
                select(func.count()).select_from(User).where(User.is_deleted == False)  # noqa: E712
            )
            total_count: int = count_result.scalar_one()

            offset = (query.page - 1) * query.items_per_page
            rows_result = await session.execute(
                select(User)
                .where(User.is_deleted == False)  # noqa: E712
                .offset(offset)
                .limit(query.items_per_page)
            )
            rows = rows_result.scalars().all()

        items = [
            ListedUser(
                id=row.id,
                name=row.name,
                username=row.username,
                email=row.email,
                profile_image_url=row.profile_image_url,
                tier_id=row.tier_id,
            )
            for row in rows
        ]
        return UserPage(
            items=items,
            total_count=total_count,
            page=query.page,
            items_per_page=query.items_per_page,
        )
