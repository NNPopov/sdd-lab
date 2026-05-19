# FEATURE: list_pending_posts — HTTP router.
from typing import Annotated

from dependency_injector.wiring import Provide, inject
from fastapi import APIRouter, Depends, Query, status

from .....bootstrap.container import Container
from .....shared_dependencies import get_current_moderator_or_superuser
from ..domain.commands import ListPendingPostsQuery
from ..domain.use_case import ListPendingPostsUseCase
from .schemas import ListPendingPostsResponse, PendingModerationLogEntrySchema, PendingPostItemSchema

router = APIRouter()


@router.get(
    "/posts/pending",
    response_model=ListPendingPostsResponse,
    status_code=status.HTTP_200_OK,
)
@inject
async def list_pending_posts_endpoint(
    use_case: Annotated[ListPendingPostsUseCase, Depends(Provide[Container.list_pending_posts_use_case])],
    current_user: Annotated[dict, Depends(get_current_moderator_or_superuser)],
    page: int = Query(default=1, ge=1),
    items_per_page: int = Query(default=10, ge=1, le=100),
) -> ListPendingPostsResponse:
    query = ListPendingPostsQuery(
        page=page,
        items_per_page=items_per_page,
        requester_is_privileged=bool(current_user.get("is_moderator") or current_user.get("is_superuser")),
    )
    result = await use_case(query)
    return ListPendingPostsResponse(
        items=[
            PendingPostItemSchema(
                post_uuid=item.post_uuid,
                title=item.title,
                text=item.text,
                media_url=item.media_url,
                status=item.status,
                created_at=item.created_at,
                updated_at=item.updated_at,
                author_username=item.author_username,
                moderation_log=[
                    PendingModerationLogEntrySchema(
                        id=e.id,
                        event_type=e.event_type,
                        action=e.action,
                        message=e.message,
                        created_at=e.created_at,
                    )
                    for e in item.moderation_log
                ],
            )
            for item in result.items
        ],
        total_count=result.total_count,
        page=result.page,
        items_per_page=result.items_per_page,
    )
