# FEATURE: create_user — data adapter.
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from .....adapters.db.models.user import User
from .....domain.errors import DuplicateValueDomainError
from ..domain.commands import CreateUserInternalCommand
from ..domain.entities import CreatedUser
from ..domain.ports.create_user_port import CreateUserPort


class CreateUserAdapter(CreateUserPort):
    def __init__(self, session_factory: async_sessionmaker[AsyncSession]) -> None:
        self._session_factory = session_factory

    async def email_exists(self, email: str) -> bool:
        async with self._session_factory() as session:
            result = await session.execute(select(User).where(User.email == email))
            return result.scalar_one_or_none() is not None

    async def username_exists(self, username: str) -> bool:
        async with self._session_factory() as session:
            result = await session.execute(select(User).where(User.username == username))
            return result.scalar_one_or_none() is not None

    async def create(self, command: CreateUserInternalCommand) -> CreatedUser:
        async with self._session_factory() as session:
            user = User(
                name=command.name,
                username=command.username,
                email=command.email,
                hashed_password=command.hashed_password,
            )
            session.add(user)
            try:
                await session.commit()
            except IntegrityError as exc:
                raise DuplicateValueDomainError("Email is already registered") from exc
            await session.refresh(user)
            return CreatedUser(
                id=user.id,
                name=user.name,
                username=user.username,
                email=user.email,
                profile_image_url=user.profile_image_url,
                tier_id=user.tier_id,
            )
