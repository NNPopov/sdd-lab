# FEATURE: list_posts — HTTP router.
from typing import Annotated

from dependency_injector.wiring import Provide, inject
from fastapi import APIRouter, Depends, Query, Request

from .....adapters.cache.redis_cache import cache
from .....bootstrap.container import Container
from .....shared_dependencies import get_optional_user
from ..domain.commands import ListPostsQuery
from ..domain.use_case import ListPostsUseCase
from .schemas import ListPostsResponse, PostItemSchema

router = APIRouter(tags=["posts"])


async def _get_view(
    username: str,
    optional_user: Annotated[dict | None, Depends(get_optional_user)],
) -> str:
    if optional_user and optional_user.get("username") == username:
        return "author"
    return "public"


@router.get("/{username}/posts", response_model=ListPostsResponse, status_code=200)
@cache(
    key_prefix="{username}_posts:{view}:page_{page}:items_per_page:{items_per_page}",
    resource_id_name="username",
    expiration=60,
)
@inject
async def list_posts_endpoint(
    request: Request,
    username: str,
    use_case: Annotated[ListPostsUseCase, Depends(Provide[Container.list_posts_use_case])],
    view: Annotated[str, Depends(_get_view)],
    page: int = Query(default=1, ge=1),
    items_per_page: int = Query(default=10, ge=1, le=100),
) -> ListPostsResponse:
    requester_username = username if view == "author" else None
    query = ListPostsQuery(
        username=username,
        page=page,
        items_per_page=items_per_page,
        requester_username=requester_username,
    )
    result = await use_case(query)
    return ListPostsResponse(
        items=[PostItemSchema.model_validate(p) for p in result.items],
        total_count=result.total_count,
        page=result.page,
        items_per_page=result.items_per_page,
    )
