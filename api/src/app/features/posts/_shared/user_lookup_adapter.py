# FEATURE: posts._shared — UserLookupAdapter.
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from ....adapters.db.models.user import User
from .entities import UserIdentity
from .user_lookup_port import UserLookupPort


class UserLookupAdapter(UserLookupPort):
    def __init__(self, session_factory: async_sessionmaker[AsyncSession]) -> None:
        self._session_factory = session_factory

    async def get_active_user_by_username(self, username: str) -> UserIdentity | None:
        async with self._session_factory() as session:
            result = await session.execute(select(User).where(User.username == username, User.is_deleted.is_(False)))
            user = result.scalar_one_or_none()
            if user is None:
                return None
            return UserIdentity.model_validate(user)
