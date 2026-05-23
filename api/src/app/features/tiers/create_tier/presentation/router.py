# FEATURE: create_tier — HTTP router.
from typing import Annotated

from dependency_injector.wiring import Provide, inject
from fastapi import APIRouter, Depends, status

from .....bootstrap.container import Container
from .....shared_dependencies import get_current_superuser
from ..domain.commands import CreateTierCommand
from ..domain.use_case import CreateTierUseCase
from .schemas import CreateTierRequest, CreateTierResponse

router = APIRouter(tags=["tiers"])


@router.post(
    "/tier",
    response_model=CreateTierResponse,
    status_code=status.HTTP_201_CREATED,
    dependencies=[Depends(get_current_superuser)],
)
@inject
async def create_tier_endpoint(
    request: CreateTierRequest,
    use_case: Annotated[
        CreateTierUseCase,
        Depends(Provide[Container.create_tier_use_case]),
    ],
) -> CreateTierResponse:
    command = CreateTierCommand(name=request.name)
    tier_item = await use_case(command)
    return CreateTierResponse.model_validate(tier_item)
