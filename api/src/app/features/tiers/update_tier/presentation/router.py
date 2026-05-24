# FEATURE: update_tier — HTTP router.
from typing import Annotated

from dependency_injector.wiring import Provide, inject
from fastapi import APIRouter, Depends, status

from .....bootstrap.container import Container
from .....shared_dependencies import get_current_superuser
from ..domain.commands import UpdateTierCommand
from ..domain.use_case import UpdateTierUseCase
from .schemas import UpdateTierRequest, UpdateTierResponse

router = APIRouter(tags=["tiers"])


@router.patch(
    "/tier/{id}",
    response_model=UpdateTierResponse,
    status_code=status.HTTP_200_OK,
    dependencies=[Depends(get_current_superuser)],
)
@inject
async def update_tier_endpoint(
    id: int,
    body: UpdateTierRequest,
    use_case: Annotated[
        UpdateTierUseCase,
        Depends(Provide[Container.update_tier_use_case]),
    ],
) -> UpdateTierResponse:
    command = UpdateTierCommand(id=id, name=body.name)
    await use_case(command)
    return UpdateTierResponse()
