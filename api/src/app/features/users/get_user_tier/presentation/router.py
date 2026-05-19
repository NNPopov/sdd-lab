# FEATURE: get_user_tier — HTTP router.
from typing import Annotated

from dependency_injector.wiring import Provide, inject
from fastapi import APIRouter, Depends

from .....bootstrap.container import Container
from ..domain.commands import GetUserTierQuery
from ..domain.use_case import GetUserTierUseCase
from .schemas import GetUserTierResponse

router = APIRouter()


@router.get(
    "/user/{username}/tier",
    response_model=GetUserTierResponse | None,
    status_code=200,
)
@inject
async def get_user_tier(
    username: str,
    use_case: Annotated[GetUserTierUseCase, Depends(Provide[Container.get_user_tier_use_case])],
) -> GetUserTierResponse | None:
    query = GetUserTierQuery(username=username)
    entity = await use_case(query)
    if entity is None:
        return None
    return GetUserTierResponse(
        tier_id=entity.tier_id,
        tier_name=entity.tier_name,
        tier_created_at=entity.tier_created_at,
    )
