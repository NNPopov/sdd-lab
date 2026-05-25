# FEATURE: assign_moderator — HTTP router.
from typing import Annotated

from dependency_injector.wiring import Provide, inject
from fastapi import APIRouter, Depends

from .....bootstrap.container import Container
from .....shared_dependencies import get_current_superuser
from ..domain.commands import AssignModeratorCommand
from ..domain.use_case import AssignModeratorUseCase
from .schemas import AssignModeratorResponse

router = APIRouter()


@router.patch(
    "/user/{user_id}/assign-moderator",
    response_model=AssignModeratorResponse,
    status_code=200,
)
@inject
async def assign_moderator_endpoint(
    user_id: int,
    use_case: Annotated[AssignModeratorUseCase, Depends(Provide[Container.assign_moderator_use_case])],
    current_superuser: Annotated[dict, Depends(get_current_superuser)],
) -> AssignModeratorResponse:
    command = AssignModeratorCommand(
        target_user_id=user_id,
        requester_id=current_superuser["id"],
        requester_is_superuser=current_superuser["is_superuser"],
    )
    entity = await use_case(command)
    return AssignModeratorResponse(
        id=entity.id,
        name=entity.name,
        username=entity.username,
        email=entity.email,
        profile_image_url=entity.profile_image_url,
        tier_id=entity.tier_id,
        is_moderator=entity.is_moderator,
    )
