# STABLE: Hand-written adapter for token blacklisting.
from datetime import datetime

from sqlalchemy import exists, select
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from ....ports.token_blacklist import TokenBlacklistPort
from .model import TokenBlacklist


class TokenBlacklistAdapter(TokenBlacklistPort):
    def __init__(self, session_factory: async_sessionmaker[AsyncSession]) -> None:
        self._session_factory = session_factory

    async def is_blacklisted(self, token: str) -> bool:
        async with self._session_factory() as session:
            result = await session.execute(select(exists().where(TokenBlacklist.token == token)))
            return bool(result.scalar())

    async def blacklist(self, token: str, expires_at: datetime) -> None:
        async with self._session_factory() as session:
            session.add(TokenBlacklist(token=token, expires_at=expires_at))
            await session.commit()
