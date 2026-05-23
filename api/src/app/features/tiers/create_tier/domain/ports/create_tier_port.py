# FEATURE: create_tier — port protocol.
from typing import Protocol, runtime_checkable

from ...._shared.entities import TierItem
from ..commands import CreateTierCommand


@runtime_checkable
class CreateTierPort(Protocol):
    async def create(self, command: CreateTierCommand) -> TierItem: ...
