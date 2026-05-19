# FEATURE: get_post — HTTP router.
from typing import Annotated

from fastapi import APIRouter, Depends, Request

from .....adapters.cache.redis_cache import cache
from .....shared_dependencies import get_optional_user
from ..domain.commands import GetPostQuery
from ..domain.use_case import GetPostUseCase
from .schemas import GetPostResponse

router = APIRouter(tags=["posts"])


def _get_get_post_use_case() -> GetPostUseCase:
    from .....bootstrap.container import container  # noqa: PLC0415

    return container.get_post_use_case()


@router.get("/{username}/post/{id}", response_model=GetPostResponse, status_code=200)
@cache(key_prefix="{username}_post_cache", resource_id_name="id")
async def get_post_endpoint(
    request: Request,
    username: str,
    id: int,
    optional_user: Annotated[dict | None, Depends(get_optional_user)],
    use_case: Annotated[GetPostUseCase, Depends(_get_get_post_use_case)],
) -> GetPostResponse:
    requester_is_privileged = bool(optional_user and (optional_user["is_superuser"] or optional_user["is_moderator"]))
    requester_username = optional_user["username"] if optional_user else None
    query = GetPostQuery(
        username=username,
        post_id=id,
        requester_username=requester_username,
        requester_is_privileged=requester_is_privileged,
    )
    post = await use_case(query)
    return GetPostResponse.model_validate(post)
