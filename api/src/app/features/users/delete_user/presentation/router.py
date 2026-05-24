# FEATURE: delete_user — HTTP router.
from typing import Annotated

from dependency_injector.wiring import Provide, inject
from fastapi import APIRouter, Depends

from .....bootstrap.container import Container
from .....core.security import blacklist_token, oauth2_scheme
from .....ports.token_blacklist import TokenBlacklistPort
from .....shared_dependencies import get_current_user
from ..domain.commands import DeleteUserCommand
from ..domain.use_case import DeleteUserUseCase
from .schemas import DeleteUserResponse

router = APIRouter()


@router.delete("/user/{username}", response_model=DeleteUserResponse, status_code=200)
@inject
async def delete_user_endpoint(
    username: str,
    current_user: Annotated[dict, Depends(get_current_user)],
    token: Annotated[str, Depends(oauth2_scheme)],
    use_case: Annotated[DeleteUserUseCase, Depends(Provide[Container.delete_user_use_case])],
    blacklist: Annotated[TokenBlacklistPort, Depends(Provide[Container.token_blacklist_adapter])],
) -> DeleteUserResponse:
    command = DeleteUserCommand(
        target_username=username,
        requester_user_id=current_user["id"],
    )
    await use_case(command)
    await blacklist_token(token, blacklist)
    return DeleteUserResponse(message="User deleted")
