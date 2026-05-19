# FEATURE: create_post — HTTP router.
from typing import Annotated, Any

from dependency_injector.wiring import Provide, inject
from fastapi import APIRouter, Depends, status

from .....bootstrap.container import Container
from .....shared_dependencies import get_current_user
from ..domain.commands import CreatePostCommand
from ..domain.use_case import CreatePostUseCase
from .schemas import CreatePostRequest, CreatePostResponse

router = APIRouter(tags=["posts"])


@router.post(
    "/{username}/post",
    response_model=CreatePostResponse,
    status_code=status.HTTP_201_CREATED,
)
@inject
async def create_post_endpoint(
    username: str,
    request: CreatePostRequest,
    current_user: Annotated[dict[str, Any], Depends(get_current_user)],
    use_case: Annotated[CreatePostUseCase, Depends(Provide[Container.create_post_use_case])],
) -> CreatePostResponse:
    command = CreatePostCommand(
        target_username=username,
        requester_username=current_user["username"],
        title=request.title,
        text=request.text,
        media_url=request.media_url,
    )
    result = await use_case(command)
    return CreatePostResponse.model_validate(result)
