# FEATURE: get_user_by_id — data adapter.
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from .....adapters.db.models.user import User
from ..domain.commands import GetUserByIdQuery
from ..domain.entities import FoundUser
from ..domain.ports.get_user_by_id_port import GetUserByIdPort


class GetUserByIdAdapter(GetUserByIdPort):
    def __init__(self, session_factory: async_sessionmaker[AsyncSession]) -> None:
        self._session_factory = session_factory

    async def get(self, query: GetUserByIdQuery) -> FoundUser | None:
        async with self._session_factory() as session:
            result = await session.execute(
                select(User).where(
                    User.id == query.user_id,
                    User.is_deleted == False,  # noqa: E712
                )
            )
            row = result.scalar_one_or_none()

        if row is None:
            return None
        return FoundUser(
            id=row.id,
            name=row.name,
            username=row.username,
            email=row.email,
            profile_image_url=row.profile_image_url,
            tier_id=row.tier_id,
            is_moderator=row.is_moderator,
        )
