# FEATURE: update_user — HTTP router.
from typing import Annotated

from fastapi import APIRouter, Depends

from ...dependencies import get_current_user
from ..domain.commands import UpdateUserCommand
from ..domain.use_case import UpdateUserUseCase
from .schemas import UpdateUserRequest, UpdateUserResponse

router = APIRouter()


def _get_update_user_use_case() -> UpdateUserUseCase:
    from .....bootstrap.container import container  # noqa: PLC0415

    return container.update_user_use_case()


@router.patch("/user/{username}", response_model=UpdateUserResponse, status_code=200)
async def update_user(
    username: str,
    request: UpdateUserRequest,
    current_user: Annotated[dict, Depends(get_current_user)],
    use_case: Annotated[UpdateUserUseCase, Depends(_get_update_user_use_case)],
) -> UpdateUserResponse:
    command = UpdateUserCommand(
        target_username=username,
        requester_username=current_user["username"],
        **request.model_dump(),
    )
    result = await use_case(command)
    return UpdateUserResponse(message=result.message)
