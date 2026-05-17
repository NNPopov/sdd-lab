# FEATURE: delete_db_user — HTTP router.
from typing import Annotated

from fastapi import APIRouter, Depends

from ...dependencies import get_current_superuser
from ..domain.commands import DeleteDbUserCommand
from ..domain.use_case import DeleteDbUserUseCase
from .schemas import DeleteDbUserResponse

router = APIRouter()


def _get_delete_db_user_use_case() -> DeleteDbUserUseCase:
    from .....bootstrap.container import container  # noqa: PLC0415

    return container.delete_db_user_use_case()


@router.delete("/db_user/{username}", response_model=DeleteDbUserResponse, status_code=200)
async def delete_db_user_endpoint(
    username: str,
    use_case: Annotated[DeleteDbUserUseCase, Depends(_get_delete_db_user_use_case)],
    _: Annotated[dict, Depends(get_current_superuser)],
) -> DeleteDbUserResponse:
    command = DeleteDbUserCommand(target_username=username)
    result = await use_case(command)
    return DeleteDbUserResponse(message=result.message)
