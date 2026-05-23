# FEATURE: create_tier — use case.
from ..._shared.entities import TierItem
from .commands import CreateTierCommand
from .ports.create_tier_port import CreateTierPort


class CreateTierUseCase:
    def __init__(self, port: CreateTierPort) -> None:
        self._port = port

    async def __call__(self, command: CreateTierCommand) -> TierItem:
        return await self._port.create(command)
