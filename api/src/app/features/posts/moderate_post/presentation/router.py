# FEATURE: moderate_post — HTTP router.
import uuid
from typing import Annotated

from dependency_injector.wiring import Provide, inject
from fastapi import APIRouter, Depends, status

from .....bootstrap.container import Container
from .....shared_dependencies import get_current_moderator_or_superuser
from ..domain.commands import ModeratePostCommand
from ..domain.use_case import ModeratePostUseCase
from .schemas import ModeratePostRequest, ModeratePostResponse, ModerationLogEntrySchema

router = APIRouter()


@router.post(
    "/posts/{post_uuid}/moderate",
    response_model=ModeratePostResponse,
    status_code=status.HTTP_200_OK,
)
@inject
async def moderate_post_endpoint(
    post_uuid: uuid.UUID,
    request: ModeratePostRequest,
    use_case: Annotated[ModeratePostUseCase, Depends(Provide[Container.moderate_post_use_case])],
    current_user: Annotated[dict, Depends(get_current_moderator_or_superuser)],
) -> ModeratePostResponse:
    command = ModeratePostCommand(
        post_uuid=post_uuid,
        requester_user_id=current_user["id"],
        requester_is_privileged=bool(current_user.get("is_moderator") or current_user.get("is_superuser")),
        action=request.action,
        message=request.message,
    )
    result = await use_case(command)
    return ModeratePostResponse(
        post_uuid=result.post_uuid,
        status=result.status,
        log_entry=ModerationLogEntrySchema(
            id=result.log_entry.id,
            event_type=result.log_entry.event_type,
            action=result.log_entry.action,
            message=result.log_entry.message,
            created_at=result.log_entry.created_at,
        ),
    )
