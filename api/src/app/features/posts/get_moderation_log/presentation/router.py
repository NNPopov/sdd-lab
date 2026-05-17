# FEATURE: get_moderation_log — HTTP router.
from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, status

from ....users.dependencies import get_current_user
from ..domain.commands import GetModerationLogQuery
from ..domain.use_case import GetModerationLogUseCase
from .schemas import GetModerationLogResponse, ModerationLogEntrySchema

router = APIRouter()


def _get_get_moderation_log_use_case() -> GetModerationLogUseCase:
    from .....bootstrap.container import container  # noqa: PLC0415

    return container.get_moderation_log_use_case()


@router.get(
    "/posts/{post_uuid}/moderation-log",
    response_model=GetModerationLogResponse,
    status_code=status.HTTP_200_OK,
)
async def get_moderation_log_endpoint(
    post_uuid: UUID,
    use_case: Annotated[GetModerationLogUseCase, Depends(_get_get_moderation_log_use_case)],
    current_user: Annotated[dict, Depends(get_current_user)],
) -> GetModerationLogResponse:
    query = GetModerationLogQuery(
        post_uuid=post_uuid,
        requester_user_id=current_user["id"],
        requester_is_moderator=bool(current_user.get("is_moderator")),
        requester_is_superuser=bool(current_user.get("is_superuser")),
    )
    result = await use_case(query)
    return GetModerationLogResponse(
        items=[
            ModerationLogEntrySchema(
                id=e.id,
                event_type=e.event_type,
                action=e.action,
                message=e.message,
                created_at=e.created_at,
                actor_user_id=e.actor_user_id,
                actor_username=e.actor_username,
            )
            for e in result.items
        ]
    )
