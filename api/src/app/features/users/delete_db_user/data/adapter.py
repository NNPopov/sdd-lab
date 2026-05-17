# FEATURE: delete_db_user — data adapter.
from sqlalchemy import delete, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from .....adapters.db.models.user import User
from .....domain.errors import DuplicateValueDomainError
from ..domain.entities import DbDeleteUserTarget
from ..domain.ports.delete_db_user_port import DeleteDbUserPort


class DeleteDbUserAdapter(DeleteDbUserPort):
    def __init__(self, session_factory: async_sessionmaker[AsyncSession]) -> None:
        self._session_factory = session_factory

    async def get_by_username(self, username: str) -> DbDeleteUserTarget | None:
        async with self._session_factory() as session:
            result = await session.execute(select(User).where(User.username == username))
            row = result.scalar_one_or_none()
            if row is None:
                return None
            return DbDeleteUserTarget(username=row.username)

    async def db_delete(self, username: str) -> None:
        async with self._session_factory() as session:
            try:
                await session.execute(delete(User).where(User.username == username))
                await session.commit()
            except IntegrityError as exc:
                raise DuplicateValueDomainError("User has dependent records") from exc
