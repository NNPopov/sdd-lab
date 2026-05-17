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
        target = await self._port.get_by_username(command.target_username)
        if target is None:
            raise NotFoundDomainError("User not found")

        check_owner(command.requester_username, target.username)

        await self._port.soft_delete(command.target_username)
        return DeleteUserResult()
