# STABLE: Port protocol for token blacklisting.
from typing import Protocol, runtime_checkable


@runtime_checkable
class TokenBlacklistPort(Protocol):
    async def blacklist(self, token: str) -> None: ...
