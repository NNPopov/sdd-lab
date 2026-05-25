# FEATURE: revoke_moderator — data adapter.
from sqlalchemy import select
from sqlalchemy import update as sa_update
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from .....adapters.db.models.user import User
from ..domain.entities import RevokedUser
from ..domain.ports.revoke_moderator_port import RevokeModeratorPort


class RevokeModeratorAdapter(RevokeModeratorPort):
    def __init__(self, session_factory: async_sessionmaker[AsyncSession]) -> None:
        self._session_factory = session_factory

    async def get_by_id(self, user_id: int) -> RevokedUser | None:
        async with self._session_factory() as session:
            result = await session.execute(
                select(User).where(
                    User.id == user_id,
                    User.is_deleted == False,  # noqa: E712
                )
            )
            row = result.scalar_one_or_none()
        if row is None:
            return None
        return RevokedUser(
            id=row.id,
            name=row.name,
            username=row.username,
            email=row.email,
            profile_image_url=row.profile_image_url,
            tier_id=row.tier_id,
            is_moderator=row.is_moderator,
        )

    async def revoke(self, target_user_id: int) -> RevokedUser:
        async with self._session_factory() as session:
            await session.execute(
                sa_update(User)
                .where(User.id == target_user_id)
                .values(is_moderator=False, moderator_granted_by_user_id=None)
            )
            await session.commit()
            result = await session.execute(select(User).where(User.id == target_user_id))
            row = result.scalar_one()
        return RevokedUser(
            id=row.id,
            name=row.name,
            username=row.username,
            email=row.email,
            profile_image_url=row.profile_image_url,
            tier_id=row.tier_id,
            is_moderator=row.is_moderator,
        )
