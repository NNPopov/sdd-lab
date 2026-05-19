# FEATURE: list_all_posts — HTTP router.
from typing import Annotated

from dependency_injector.wiring import Provide, inject
from fastapi import APIRouter, Depends, Query, Request

from .....adapters.cache.redis_cache import cache
from .....bootstrap.container import Container
from .....shared_dependencies import get_optional_user
from ..domain.commands import ListAllPostsQuery
from ..domain.use_case import ListAllPostsUseCase
from .schemas import ListAllPostsResponse, PostItemSchema

router = APIRouter(tags=["posts"])


async def _get_view(
    optional_user: Annotated[dict | None, Depends(get_optional_user)],
) -> str:
    if optional_user and (optional_user.get("is_moderator") or optional_user.get("is_superuser")):
        return "privileged"
    return "public"


@router.get("/posts", response_model=ListAllPostsResponse, status_code=200)
@cache(
    key_prefix="all_posts:{view}:page_{page}:items_per_page:{items_per_page}",
    resource_id_name="page",
    expiration=60,
)
@inject
async def list_all_posts_endpoint(
    request: Request,
    use_case: Annotated[ListAllPostsUseCase, Depends(Provide[Container.list_all_posts_use_case])],
    view: Annotated[str, Depends(_get_view)],
    page: int = Query(default=1, ge=1),
    items_per_page: int = Query(default=10, ge=1, le=100),
) -> ListAllPostsResponse:
    query = ListAllPostsQuery(
        page=page,
        items_per_page=items_per_page,
        requester_is_privileged=(view == "privileged"),
    )
    result = await use_case(query)
    return ListAllPostsResponse(
        items=[PostItemSchema.model_validate(p) for p in result.items],
        total_count=result.total_count,
        page=result.page,
        items_per_page=result.items_per_page,
    )
