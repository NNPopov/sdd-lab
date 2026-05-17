# FEATURE: create_user — HTTP router.
from typing import Annotated

from fastapi import APIRouter, Depends

from ..domain.commands import CreateUserCommand
from ..domain.use_case import CreateUserUseCase
from .schemas import CreateUserRequest, CreateUserResponse

router = APIRouter()


def _get_create_user_use_case() -> CreateUserUseCase:
    # Relative import keeps us in the same module hierarchy regardless of entry point.
    from .....bootstrap.container import container  # noqa: PLC0415

    return container.create_user_use_case()


@router.post("/user", response_model=CreateUserResponse, status_code=201)
async def create_user(
    request: CreateUserRequest,
    use_case: Annotated[CreateUserUseCase, Depends(_get_create_user_use_case)],
) -> CreateUserResponse:
    command = CreateUserCommand(
        name=request.name,
        username=request.username,
        email=request.email,
        password=request.password,
    )
    entity = await use_case(command)
    return CreateUserResponse(
        id=entity.id,
        name=entity.name,
        username=entity.username,
        email=entity.email,
        profile_image_url=entity.profile_image_url,
        tier_id=entity.tier_id,
    )
