# FEATURE: update_tier — port protocol.
from typing import Protocol, runtime_checkable

from ...._shared.entities import TierItem


@runtime_checkable
class UpdateTierPort(Protocol):
    async def get(self, name: str) -> TierItem | None: ...
    async def update(self, name: str, new_name: str) -> None: ...
