# STABLE: Concrete token-blacklist service.
from datetime import datetime

from jose import jwt
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from ..adapters.db.token_blacklist.repository import crud_token_blacklist
from ..ports.token_blacklist import TokenBlacklistPort
from .schemas import TokenBlacklistCreate
from .security import ALGORITHM, SECRET_KEY


class TokenBlacklistService(TokenBlacklistPort):
    def __init__(self, session_factory: async_sessionmaker[AsyncSession]) -> None:
        self._session_factory = session_factory

    async def blacklist(self, token: str) -> None:
        payload = jwt.decode(token, SECRET_KEY.get_secret_value(), algorithms=[ALGORITHM])
        exp_timestamp = payload.get("exp")
        if exp_timestamp is not None:
            expires_at = datetime.fromtimestamp(exp_timestamp)
            async with self._session_factory() as session:
                await crud_token_blacklist.create(
                    session, object=TokenBlacklistCreate(token=token, expires_at=expires_at)
                )
