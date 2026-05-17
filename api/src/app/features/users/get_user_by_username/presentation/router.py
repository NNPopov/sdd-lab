# FEATURE: get_user_by_username — HTTP router.
from typing import Annotated

from fastapi import APIRouter, Depends

from ..domain.commands import GetUserByUsernameQuery
from ..domain.use_case import GetUserByUsernameUseCase
from .schemas import GetUserByUsernameResponse

router = APIRouter()


def _get_get_user_by_username_use_case() -> GetUserByUsernameUseCase:
    from .....bootstrap.container import container  # noqa: PLC0415

    return container.get_user_by_username_use_case()


@router.get("/user/{username}", response_model=GetUserByUsernameResponse, status_code=200)
async def get_user_by_username(
    username: str,
    use_case: Annotated[GetUserByUsernameUseCase, Depends(_get_get_user_by_username_use_case)],
) -> GetUserByUsernameResponse:
    query = GetUserByUsernameQuery(username=username)
    entity = await use_case(query)
    return GetUserByUsernameResponse(
        id=entity.id,
        name=entity.name,
        username=entity.username,
        email=entity.email,
        profile_image_url=entity.profile_image_url,
        tier_id=entity.tier_id,
        is_moderator=entity.is_moderator,
    )
