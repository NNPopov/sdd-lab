# FEATURE: delete_db_user — use case.
from .....domain.errors import NotFoundDomainError
from .commands import DeleteDbUserCommand
from .entities import DeleteDbUserResult
from .ports.delete_db_user_port import DeleteDbUserPort


class DeleteDbUserUseCase:
    def __init__(self, port: DeleteDbUserPort) -> None:
        self._port = port

    async def __call__(self, command: DeleteDbUserCommand) -> DeleteDbUserResult:
        target = await self._port.get_by_id(command.target_user_id)
        if target is None:
            raise NotFoundDomainError("User not found")
        await self._port.db_delete(command.target_user_id)
        return DeleteDbUserResult()
