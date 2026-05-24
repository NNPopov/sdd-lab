# FEATURE: get_user_by_id — HTTP router.
from typing import Annotated

from dependency_injector.wiring import Provide, inject
from fastapi import APIRouter, Depends

from .....bootstrap.container import Container
from ..domain.commands import GetUserByIdQuery
from ..domain.use_case import GetUserByIdUseCase
from .schemas import GetUserByIdResponse

router = APIRouter()


@router.get("/user/{user_id}", response_model=GetUserByIdResponse, status_code=200)
@inject
async def get_user_by_id(
    user_id: int,
    use_case: Annotated[GetUserByIdUseCase, Depends(Provide[Container.get_user_by_id_use_case])],
) -> GetUserByIdResponse:
    query = GetUserByIdQuery(user_id=user_id)
    entity = await use_case(query)
    return GetUserByIdResponse(
        id=entity.id,
        name=entity.name,
        username=entity.username,
        email=entity.email,
        profile_image_url=entity.profile_image_url,
        tier_id=entity.tier_id,
        is_moderator=entity.is_moderator,
    )
