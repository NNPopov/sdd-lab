# FEATURE: delete_db_user — HTTP router.
from typing import Annotated

from dependency_injector.wiring import Provide, inject
from fastapi import APIRouter, Depends

from .....bootstrap.container import Container
from .....shared_dependencies import get_current_superuser
from ..domain.commands import DeleteDbUserCommand
from ..domain.use_case import DeleteDbUserUseCase
from .schemas import DeleteDbUserResponse

router = APIRouter()


@router.delete("/db_user/{username}", response_model=DeleteDbUserResponse, status_code=200)
@inject
async def delete_db_user_endpoint(
    username: str,
    use_case: Annotated[DeleteDbUserUseCase, Depends(Provide[Container.delete_db_user_use_case])],
    _: Annotated[dict, Depends(get_current_superuser)],
) -> DeleteDbUserResponse:
    command = DeleteDbUserCommand(target_username=username)
    result = await use_case(command)
    return DeleteDbUserResponse(message=result.message)
