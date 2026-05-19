# FEATURE: create_user — HTTP router.
from typing import Annotated

from dependency_injector.wiring import Provide, inject
from fastapi import APIRouter, Depends

from .....bootstrap.container import Container
from ..domain.commands import CreateUserCommand
from ..domain.use_case import CreateUserUseCase
from .schemas import CreateUserRequest, CreateUserResponse

router = APIRouter()


@router.post("/user", response_model=CreateUserResponse, status_code=201)
@inject
async def create_user(
    request: CreateUserRequest,
    use_case: Annotated[CreateUserUseCase, Depends(Provide[Container.create_user_use_case])],
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
