# FEATURE: erase_db_post — HTTP router.
from typing import Annotated

from dependency_injector.wiring import Provide, inject
from fastapi import APIRouter, Depends, Request

from .....adapters.cache.redis_cache import cache
from .....bootstrap.container import Container
from .....shared_dependencies import get_current_superuser
from ..domain.commands import EraseDbPostCommand
from ..domain.use_case import EraseDbPostUseCase
from .schemas import EraseDbPostResponse

router = APIRouter(tags=["posts"])


@router.delete("/{user_id}/db_post/{id}", response_model=EraseDbPostResponse, status_code=200)
@cache(
    "{user_id}_post_cache",
    resource_id_name="id",
    to_invalidate_extra={"{user_id}_posts": "{user_id}"},
)
@inject
async def erase_db_post_endpoint(
    request: Request,
    user_id: int,
    id: int,
    _: Annotated[dict, Depends(get_current_superuser)],
    use_case: Annotated[EraseDbPostUseCase, Depends(Provide[Container.erase_db_post_use_case])],
) -> EraseDbPostResponse:
    command = EraseDbPostCommand(user_id=user_id, post_id=id)
    await use_case(command)
    return EraseDbPostResponse(message="Post deleted from the database")
