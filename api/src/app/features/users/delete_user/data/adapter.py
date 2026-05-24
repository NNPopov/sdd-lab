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

    async def get_by_username(self, username: str) -> DeleteUserTarget | None:
        async with self._session_factory() as session:
            result = await session.execute(
                select(User).where(User.username == username, User.is_deleted == False)  # noqa: E712
            )
            row = result.scalar_one_or_none()
            if row is None:
                return None
            return DeleteUserTarget(id=row.id, username=row.username)

    async def soft_delete(self, username: str) -> None:
        async with self._session_factory() as session:
            await session.execute(
                update(User).where(User.username == username).values(is_deleted=True, deleted_at=datetime.now(UTC))
            )
            await session.commit()
