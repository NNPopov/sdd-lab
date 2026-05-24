# FEATURE: delete_tier — port protocol.
from typing import Protocol, runtime_checkable

from ...._shared.entities import TierItem


@runtime_checkable
class DeleteTierPort(Protocol):
    async def get(self, tier_id: int) -> TierItem | None: ...
    async def delete(self, tier_id: int) -> None: ...
