# FEATURE: update_user — HTTP router.
from typing import Annotated

from dependency_injector.wiring import Provide, inject
from fastapi import APIRouter, Depends

from .....bootstrap.container import Container
from .....shared_dependencies import get_current_user
from ..domain.commands import UpdateUserCommand
from ..domain.use_case import UpdateUserUseCase
from .schemas import UpdateUserRequest, UpdateUserResponse

router = APIRouter()


@router.patch("/user/{username}", response_model=UpdateUserResponse, status_code=200)
@inject
async def update_user(
    username: str,
    request: UpdateUserRequest,
    current_user: Annotated[dict, Depends(get_current_user)],
    use_case: Annotated[UpdateUserUseCase, Depends(Provide[Container.update_user_use_case])],
) -> UpdateUserResponse:
    command = UpdateUserCommand(
        target_username=username,
        requester_user_id=current_user["id"],
        **request.model_dump(),
    )
    result = await use_case(command)
    return UpdateUserResponse(message=result.message)
