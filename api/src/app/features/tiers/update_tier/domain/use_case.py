# FEATURE: update_tier — use case.
from .....domain.errors import NotFoundDomainError
from .commands import UpdateTierCommand
from .ports.update_tier_port import UpdateTierPort


class UpdateTierUseCase:
    def __init__(self, port: UpdateTierPort) -> None:
        self._port = port

    async def __call__(self, command: UpdateTierCommand) -> None:
        result = await self._port.get(command.id)
        if result is None:
            raise NotFoundDomainError("Tier not found")
        await self._port.update(command.id, command.name)
