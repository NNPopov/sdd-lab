# FEATURE: delete_tier — use case.
from .....domain.errors import NotFoundDomainError
from .commands import DeleteTierCommand
from .ports.delete_tier_port import DeleteTierPort


class DeleteTierUseCase:
    def __init__(self, port: DeleteTierPort) -> None:
        self._port = port

    async def __call__(self, command: DeleteTierCommand) -> None:
        result = await self._port.get(command.name)
        if result is None:
            raise NotFoundDomainError("Tier not found")
        await self._port.delete(command.name)
