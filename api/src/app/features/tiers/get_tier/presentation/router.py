# FEATURE: get_tier — HTTP router.
from typing import Annotated

from dependency_injector.wiring import Provide, inject
from fastapi import APIRouter, Depends, status

from .....bootstrap.container import Container
from ..domain.commands import GetTierQuery
from ..domain.use_case import GetTierUseCase
from .schemas import GetTierResponse

router = APIRouter(tags=["tiers"])


@router.get(
    "/tier/{tier_id}",
    response_model=GetTierResponse,
    status_code=status.HTTP_200_OK,
)
@inject
async def get_tier_endpoint(
    tier_id: int,
    use_case: Annotated[
        GetTierUseCase,
        Depends(Provide[Container.get_tier_use_case]),
    ],
) -> GetTierResponse:
    query = GetTierQuery(id=tier_id)
    tier_item = await use_case(query)
    return GetTierResponse.model_validate(tier_item)
