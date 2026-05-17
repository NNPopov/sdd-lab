# FEATURE: list_users — HTTP router.
from typing import Annotated

from fastapi import APIRouter, Depends, Query

from ..domain.commands import ListUsersQuery
from ..domain.use_case import ListUsersUseCase
from .schemas import ListedUserSchema, ListUsersResponse

router = APIRouter()


def _get_list_users_use_case() -> ListUsersUseCase:
    from .....bootstrap.container import container  # noqa: PLC0415

    return container.list_users_use_case()


@router.get("/users", response_model=ListUsersResponse, status_code=200)
async def list_users(
    use_case: Annotated[ListUsersUseCase, Depends(_get_list_users_use_case)],
    page: int = Query(default=1, ge=1),
    items_per_page: int = Query(default=10, ge=1),
) -> ListUsersResponse:
    query = ListUsersQuery(page=page, items_per_page=items_per_page)
    result = await use_case(query)
    return ListUsersResponse(
        items=[ListedUserSchema.model_validate(u) for u in result.items],
        total_count=result.total_count,
        page=result.page,
        items_per_page=result.items_per_page,
    )
