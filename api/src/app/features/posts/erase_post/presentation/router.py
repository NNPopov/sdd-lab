# FEATURE: erase_post — HTTP router.
from typing import Annotated

from dependency_injector.wiring import Provide, inject
from fastapi import APIRouter, Depends, Request

from .....adapters.cache.redis_cache import cache
from .....bootstrap.container import Container
from .....shared_dependencies import get_current_user
from ..domain.commands import ErasePostCommand
from ..domain.use_case import ErasePostUseCase
from .schemas import ErasePostResponse

router = APIRouter(tags=["posts"])


@router.delete("/{username}/post/{id}", response_model=ErasePostResponse, status_code=200)
@cache(
    "{username}_post_cache",
    resource_id_name="id",
    to_invalidate_extra={"{username}_posts": "{username}"},
)
@inject
async def erase_post_endpoint(
    request: Request,
    username: str,
    id: int,
    current_user: Annotated[dict, Depends(get_current_user)],
    use_case: Annotated[ErasePostUseCase, Depends(Provide[Container.erase_post_use_case])],
) -> ErasePostResponse:
    command = ErasePostCommand(
        username=username,
        post_id=id,
        requester_username=current_user["username"],
    )
    await use_case(command)
    return ErasePostResponse(message="Post deleted")
