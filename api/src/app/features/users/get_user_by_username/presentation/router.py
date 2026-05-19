# FEATURE: get_user_by_username — HTTP router.
from typing import Annotated

from dependency_injector.wiring import Provide, inject
from fastapi import APIRouter, Depends

from .....bootstrap.container import Container
from ..domain.commands import GetUserByUsernameQuery
from ..domain.use_case import GetUserByUsernameUseCase
from .schemas import GetUserByUsernameResponse

router = APIRouter()


@router.get("/user/{username}", response_model=GetUserByUsernameResponse, status_code=200)
@inject
async def get_user_by_username(
    username: str,
    use_case: Annotated[GetUserByUsernameUseCase, Depends(Provide[Container.get_user_by_username_use_case])],
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
