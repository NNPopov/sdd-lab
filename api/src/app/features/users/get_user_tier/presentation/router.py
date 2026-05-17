# FEATURE: get_user_tier — HTTP router.
from typing import Annotated

from fastapi import APIRouter, Depends

from ..domain.commands import GetUserTierQuery
from ..domain.use_case import GetUserTierUseCase
from .schemas import GetUserTierResponse

router = APIRouter()


def _get_get_user_tier_use_case() -> GetUserTierUseCase:
    from .....bootstrap.container import container  # noqa: PLC0415

    return container.get_user_tier_use_case()


@router.get(
    "/user/{username}/tier",
    response_model=GetUserTierResponse | None,
    status_code=200,
)
async def get_user_tier(
    username: str,
    use_case: Annotated[GetUserTierUseCase, Depends(_get_get_user_tier_use_case)],
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
