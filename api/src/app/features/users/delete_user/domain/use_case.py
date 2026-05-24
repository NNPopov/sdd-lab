# FEATURE: delete_user — use case.
from .....domain.errors import NotFoundDomainError
from ..._shared.policies import check_owner
from .commands import DeleteUserCommand
from .entities import DeleteUserResult
from .ports.delete_user_port import DeleteUserPort


class DeleteUserUseCase:
    def __init__(self, port: DeleteUserPort) -> None:
        self._port = port

    async def __call__(self, command: DeleteUserCommand) -> DeleteUserResult:
        target = await self._port.get_by_id(command.target_user_id)
        if target is None:
            raise NotFoundDomainError("User not found")

        check_owner(command.requester_user_id, target.id)

        await self._port.soft_delete(command.target_user_id)
        return DeleteUserResult()
