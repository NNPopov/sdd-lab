# FEATURE: assign_moderator — HTTP router.
from typing import Annotated

from fastapi import APIRouter, Depends

from .....shared_dependencies import get_current_superuser
from ..domain.commands import AssignModeratorCommand
from ..domain.use_case import AssignModeratorUseCase
from .schemas import AssignModeratorResponse

router = APIRouter()


def _get_assign_moderator_use_case() -> AssignModeratorUseCase:
    from .....bootstrap.container import container  # noqa: PLC0415

    return container.assign_moderator_use_case()


@router.patch(
    "/user/{username}/assign-moderator",
    response_model=AssignModeratorResponse,
    status_code=200,
)
async def assign_moderator_endpoint(
    username: str,
    use_case: Annotated[AssignModeratorUseCase, Depends(_get_assign_moderator_use_case)],
    current_superuser: Annotated[dict, Depends(get_current_superuser)],
) -> AssignModeratorResponse:
    command = AssignModeratorCommand(
        target_username=username,
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
