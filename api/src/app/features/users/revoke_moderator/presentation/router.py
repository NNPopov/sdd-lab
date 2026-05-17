# FEATURE: revoke_moderator — HTTP router.
from typing import Annotated

from fastapi import APIRouter, Depends

from ...dependencies import get_current_superuser
from ..domain.commands import RevokeModeratorCommand
from ..domain.use_case import RevokeModeratorUseCase
from .schemas import RevokeModeratorResponse

router = APIRouter()


def _get_revoke_moderator_use_case() -> RevokeModeratorUseCase:
    from .....bootstrap.container import container  # noqa: PLC0415

    return container.revoke_moderator_use_case()


@router.patch(
    "/users/{username}/revoke-moderator",
    response_model=RevokeModeratorResponse,
    status_code=200,
)
async def revoke_moderator_endpoint(
    username: str,
    use_case: Annotated[RevokeModeratorUseCase, Depends(_get_revoke_moderator_use_case)],
    current_superuser: Annotated[dict, Depends(get_current_superuser)],
) -> RevokeModeratorResponse:
    command = RevokeModeratorCommand(
        target_username=username,
        requester_is_superuser=current_superuser["is_superuser"],
    )
    entity = await use_case(command)
    return RevokeModeratorResponse(
        id=entity.id,
        name=entity.name,
        username=entity.username,
        email=entity.email,
        profile_image_url=entity.profile_image_url,
        tier_id=entity.tier_id,
        is_moderator=entity.is_moderator,
    )
