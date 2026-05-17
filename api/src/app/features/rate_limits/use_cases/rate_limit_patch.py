# FEATURE: rate_limits — use case: update rate limit.
from typing import Annotated

from fastapi import Depends, Request
from sqlalchemy.ext.asyncio import AsyncSession

from ....adapters.db.session import async_get_db
from ....domain.errors import NotFoundDomainError
from ....features.tiers.repository import crud_tiers
from ....features.tiers.schemas import TierRead
from ..repository import crud_rate_limits
from ..schemas import RateLimitRead, RateLimitUpdate


async def patch_rate_limit(
    request: Request,
    tier_name: str,
    id: int,
    values: RateLimitUpdate,
    db: Annotated[AsyncSession, Depends(async_get_db)],
) -> dict[str, str]:
    db_tier = await crud_tiers.get(db=db, name=tier_name, schema_to_select=TierRead)
    if not db_tier:
        raise NotFoundDomainError("Tier not found")

    db_rate_limit = await crud_rate_limits.get(db=db, tier_id=db_tier["id"], id=id, schema_to_select=RateLimitRead)
    if db_rate_limit is None:
        raise NotFoundDomainError("Rate Limit not found")

    await crud_rate_limits.update(db=db, object=values, id=id)
    return {"message": "Rate Limit updated"}
