# FEATURE: delete_user — HTTP router.
from typing import Annotated

from fastapi import APIRouter, Depends

from .....core.security import blacklist_token, oauth2_scheme
from .....ports.token_blacklist import TokenBlacklistPort
from .....shared_dependencies import get_current_user
from ..domain.commands import DeleteUserCommand
from ..domain.use_case import DeleteUserUseCase
from .schemas import DeleteUserResponse

router = APIRouter()


def _get_delete_user_use_case() -> DeleteUserUseCase:
    from .....bootstrap.container import container  # noqa: PLC0415

    return container.delete_user_use_case()


def _get_token_blacklist_adapter() -> TokenBlacklistPort:
    from .....bootstrap.container import container  # noqa: PLC0415

    return container.token_blacklist_adapter()


@router.delete("/user/{username}", response_model=DeleteUserResponse, status_code=200)
async def delete_user_endpoint(
    username: str,
    current_user: Annotated[dict, Depends(get_current_user)],
    token: Annotated[str, Depends(oauth2_scheme)],
    use_case: Annotated[DeleteUserUseCase, Depends(_get_delete_user_use_case)],
    blacklist: Annotated[TokenBlacklistPort, Depends(_get_token_blacklist_adapter)],
) -> DeleteUserResponse:
    command = DeleteUserCommand(
        target_username=username,
        requester_username=current_user["username"],
    )
    await use_case(command)
    await blacklist_token(token, blacklist)
    return DeleteUserResponse(message="User deleted")
