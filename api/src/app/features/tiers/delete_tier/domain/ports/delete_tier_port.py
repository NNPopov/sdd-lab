# FEATURE: delete_tier — port protocol.
from typing import Protocol, runtime_checkable

from ...._shared.entities import TierItem


@runtime_checkable
class DeleteTierPort(Protocol):
    async def get(self, name: str) -> TierItem | None: ...
    async def delete(self, name: str) -> None: ...
