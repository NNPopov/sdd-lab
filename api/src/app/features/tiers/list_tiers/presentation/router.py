# FEATURE: list_tiers — HTTP router.
from typing import Annotated

from dependency_injector.wiring import Provide, inject
from fastapi import APIRouter, Depends, Query
from starlette import status

from .....bootstrap.container import Container
from ..domain.commands import ListTiersQuery
from ..domain.use_case import ListTiersUseCase
from .schemas import ListTiersResponse, TierItemSchema

router = APIRouter(tags=["tiers"])


@router.get("/tiers", response_model=ListTiersResponse, status_code=status.HTTP_200_OK)
@inject
async def list_tiers_endpoint(
    use_case: Annotated[ListTiersUseCase, Depends(Provide[Container.list_tiers_use_case])],
    page: int = Query(default=1, ge=1),
    items_per_page: int = Query(default=10, ge=1, le=100),
) -> ListTiersResponse:
    query = ListTiersQuery(page=page, items_per_page=items_per_page)
    result = await use_case(query)
    return ListTiersResponse(
        items=[TierItemSchema.model_validate(item) for item in result.items],
        total_count=result.total_count,
        page=result.page,
        items_per_page=result.items_per_page,
    )
