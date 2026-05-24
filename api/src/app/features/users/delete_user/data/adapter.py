# FEATURE: delete_user — data adapter.
from datetime import UTC, datetime

from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from .....adapters.db.models.user import User
from ..domain.entities import DeleteUserTarget
from ..domain.ports.delete_user_port import DeleteUserPort


class DeleteUserAdapter(DeleteUserPort):
    def __init__(self, session_factory: async_sessionmaker[AsyncSession]) -> None:
        self._session_factory = session_factory

    async def get_by_id(self, user_id: int) -> DeleteUserTarget | None:
        async with self._session_factory() as session:
            result = await session.execute(
                select(User).where(User.id == user_id, User.is_deleted == False)  # noqa: E712
            )
            row = result.scalar_one_or_none()
            if row is None:
                return None
            return DeleteUserTarget(id=row.id)

    async def soft_delete(self, target_user_id: int) -> None:
        async with self._session_factory() as session:
            await session.execute(
                update(User).where(User.id == target_user_id).values(is_deleted=True, deleted_at=datetime.now(UTC))
            )
            await session.commit()
