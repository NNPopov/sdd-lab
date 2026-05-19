# STABLE: Port protocol for token blacklisting.
from datetime import datetime
from typing import Protocol, runtime_checkable


@runtime_checkable
class TokenBlacklistPort(Protocol):
    async def is_blacklisted(self, token: str) -> bool: ...
    async def blacklist(self, token: str, expires_at: datetime) -> None: ...
