# FEATURE: rate_limits — use case: list rate limits for a tier.
from typing import Annotated, Any

from fastapi import Depends, Request
from fastcrud import compute_offset, paginated_response
from sqlalchemy.ext.asyncio import AsyncSession

from ....adapters.db.session import async_get_db
from ....domain.errors import NotFoundDomainError
from ....features.tiers.repository import crud_tiers
from ....features.tiers.schemas import TierRead
from ..repository import crud_rate_limits


async def read_rate_limits(
    request: Request,
    tier_name: str,
    db: Annotated[AsyncSession, Depends(async_get_db)],
    page: int = 1,
    items_per_page: int = 10,
) -> dict:
    db_tier = await crud_tiers.get(db=db, name=tier_name, schema_to_select=TierRead)
    if not db_tier:
        raise NotFoundDomainError("Tier not found")

    rate_limits_data = await crud_rate_limits.get_multi(
        db=db,
        offset=compute_offset(page, items_per_page),
        limit=items_per_page,
        tier_id=db_tier["id"],
    )

    response: dict[str, Any] = paginated_response(crud_data=rate_limits_data, page=page, items_per_page=items_per_page)
    return response
