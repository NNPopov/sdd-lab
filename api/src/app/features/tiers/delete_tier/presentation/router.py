# FEATURE: delete_tier — HTTP router.
from typing import Annotated

from dependency_injector.wiring import Provide, inject
from fastapi import APIRouter, Depends, status

from .....bootstrap.container import Container
from .....shared_dependencies import get_current_superuser
from ..domain.commands import DeleteTierCommand
from ..domain.use_case import DeleteTierUseCase
from .schemas import DeleteTierResponse

router = APIRouter(tags=["tiers"])


@router.delete(
    "/tier/{id}",
    response_model=DeleteTierResponse,
    status_code=status.HTTP_200_OK,
    dependencies=[Depends(get_current_superuser)],
)
@inject
async def delete_tier_endpoint(
    id: int,
    use_case: Annotated[
        DeleteTierUseCase,
        Depends(Provide[Container.delete_tier_use_case]),
    ],
) -> DeleteTierResponse:
    command = DeleteTierCommand(id=id)
    await use_case(command)
    return DeleteTierResponse()
