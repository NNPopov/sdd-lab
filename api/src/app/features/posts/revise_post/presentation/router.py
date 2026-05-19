# FEATURE: revise_post — HTTP router.
import uuid
from typing import Annotated

from dependency_injector.wiring import Provide, inject
from fastapi import APIRouter, Depends, status

from .....bootstrap.container import Container
from .....shared_dependencies import get_current_user
from ..domain.commands import RevisePostCommand
from ..domain.use_case import RevisePostUseCase
from .schemas import RevisePostRequest, RevisePostResponse, RevisionLogEntrySchema

router = APIRouter()


@router.patch(
    "/posts/{post_uuid}/revise",
    response_model=RevisePostResponse,
    status_code=status.HTTP_200_OK,
)
@inject
async def revise_post_endpoint(
    post_uuid: uuid.UUID,
    request: RevisePostRequest,
    use_case: Annotated[RevisePostUseCase, Depends(Provide[Container.revise_post_use_case])],
    current_user: Annotated[dict, Depends(get_current_user)],
) -> RevisePostResponse:
    command = RevisePostCommand(
        post_uuid=post_uuid,
        requester_user_id=current_user["id"],
        title=request.title,
        text=request.text,
        message=request.message,
    )
    result = await use_case(command)
    return RevisePostResponse(
        post_uuid=result.post_uuid,
        title=result.title,
        text=result.text,
        status=result.status,
        updated_at=result.updated_at,
        log_entry=RevisionLogEntrySchema(
            id=result.log_entry.id,
            event_type=result.log_entry.event_type,
            action=result.log_entry.action,
            message=result.log_entry.message,
            created_at=result.log_entry.created_at,
        ),
    )
