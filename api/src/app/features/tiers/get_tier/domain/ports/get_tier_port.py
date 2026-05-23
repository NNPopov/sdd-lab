# FEATURE: get_tier — port protocol.
from typing import Protocol, runtime_checkable

from ...._shared.entities import TierItem
from ..commands import GetTierQuery


@runtime_checkable
class GetTierPort(Protocol):
    async def get(self, query: GetTierQuery) -> TierItem | None: ...
