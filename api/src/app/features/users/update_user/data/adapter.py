# FEATURE: update_user — data adapter.
from datetime import UTC, datetime

from sqlalchemy import select, update
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from .....adapters.db.models.user import User
from .....domain.errors import DuplicateValueDomainError
from ..domain.commands import UpdateUserCommand
from ..domain.entities import ExistingUser
from ..domain.ports.update_user_port import UpdateUserPort


class UpdateUserAdapter(UpdateUserPort):
    def __init__(self, session_factory: async_sessionmaker[AsyncSession]) -> None:
        self._session_factory = session_factory

    async def get_by_username(self, username: str) -> ExistingUser | None:
        async with self._session_factory() as session:
            result = await session.execute(
                select(User).where(User.username == username, User.is_deleted == False)  # noqa: E712
            )
            row = result.scalar_one_or_none()
            if row is None:
                return None
            return ExistingUser(id=row.id, username=row.username, email=row.email)

    async def email_exists(self, email: str) -> bool:
        async with self._session_factory() as session:
            result = await session.execute(select(User).where(User.email == email))
            return result.scalar_one_or_none() is not None

    async def username_exists(self, username: str) -> bool:
        async with self._session_factory() as session:
            result = await session.execute(select(User).where(User.username == username))
            return result.scalar_one_or_none() is not None

    async def update(self, command: UpdateUserCommand) -> None:
        update_values: dict[str, object] = {
            k: v
            for k, v in command.model_dump().items()
            if k not in ("target_username", "requester_user_id") and v is not None
        }
        update_values["updated_at"] = datetime.now(UTC)

        async with self._session_factory() as session:
            await session.execute(update(User).where(User.username == command.target_username).values(**update_values))
            try:
                await session.commit()
            except IntegrityError as exc:
                raise DuplicateValueDomainError("Email or username already taken") from exc
