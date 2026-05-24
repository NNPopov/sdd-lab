# FEATURE: update_tier — port protocol.
from typing import Protocol, runtime_checkable

from ...._shared.entities import TierItem


@runtime_checkable
class UpdateTierPort(Protocol):
    async def get(self, tier_id: int) -> TierItem | None: ...
    async def update(self, tier_id: int, name: str) -> None: ...
