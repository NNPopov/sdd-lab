# FEATURE: update_post — HTTP router.
from typing import Annotated

from dependency_injector.wiring import Provide, inject
from fastapi import APIRouter, Depends, Request

from .....adapters.cache.redis_cache import cache
from .....bootstrap.container import Container
from .....shared_dependencies import get_current_user
from ..domain.commands import UpdatePostCommand
from ..domain.use_case import UpdatePostUseCase
from .schemas import UpdatePostRequest, UpdatePostResponse

router = APIRouter(tags=["posts"])


@router.patch("/{user_id}/post/{id}", response_model=UpdatePostResponse, status_code=200)
@cache("{user_id}_post_cache", resource_id_name="id", pattern_to_invalidate_extra=["{user_id}_posts:*"])
@inject
async def update_post_endpoint(
    request: Request,
    user_id: int,
    id: int,
    body: UpdatePostRequest,
    current_user: Annotated[dict, Depends(get_current_user)],
    use_case: Annotated[UpdatePostUseCase, Depends(Provide[Container.update_post_use_case])],
) -> UpdatePostResponse:
    command = UpdatePostCommand(
        target_user_id=user_id,
        requester_user_id=current_user["id"],
        post_id=id,
        **body.model_dump(),
    )
    await use_case(command)
    return UpdatePostResponse(message="Post updated")
