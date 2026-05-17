# FEATURE: assign_moderator — data adapter.
from sqlalchemy import select
from sqlalchemy import update as sa_update
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from .....adapters.db.models.user import User
from ..domain.entities import AssignedUser
from ..domain.ports.assign_moderator_port import AssignModeratorPort


class AssignModeratorAdapter(AssignModeratorPort):
    def __init__(self, session_factory: async_sessionmaker[AsyncSession]) -> None:
        self._session_factory = session_factory

    async def get_by_username(self, username: str) -> AssignedUser | None:
        async with self._session_factory() as session:
            result = await session.execute(
                select(User).where(
                    User.username == username,
                    User.is_deleted == False,  # noqa: E712
                )
            )
            row = result.scalar_one_or_none()
        if row is None:
            return None
        return AssignedUser(
            id=row.id,
            name=row.name,
            username=row.username,
            email=row.email,
            profile_image_url=row.profile_image_url,
            tier_id=row.tier_id,
            is_moderator=row.is_moderator,
        )

    async def assign(self, target_username: str, granted_by_user_id: int) -> AssignedUser:
        async with self._session_factory() as session:
            await session.execute(
                sa_update(User)
                .where(User.username == target_username)
                .values(is_moderator=True, moderator_granted_by_user_id=granted_by_user_id)
            )
            await session.commit()
            result = await session.execute(select(User).where(User.username == target_username))
            row = result.scalar_one()
        return AssignedUser(
            id=row.id,
            name=row.name,
            username=row.username,
            email=row.email,
            profile_image_url=row.profile_image_url,
            tier_id=row.tier_id,
            is_moderator=row.is_moderator,
        )
