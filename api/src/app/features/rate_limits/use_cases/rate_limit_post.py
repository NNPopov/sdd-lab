# FEATURE: rate_limits — use case: create rate limit.
from typing import Annotated, Any

from fastapi import Depends, Request
from sqlalchemy.ext.asyncio import AsyncSession

from ....adapters.db.session import async_get_db
from ....domain.errors import DuplicateValueDomainError, NotFoundDomainError
from ....features.tiers.repository import crud_tiers
from ....features.tiers.schemas import TierRead
from ..repository import crud_rate_limits
from ..schemas import RateLimitCreate, RateLimitCreateInternal, RateLimitRead


async def write_rate_limit(
    request: Request, tier_name: str, rate_limit: RateLimitCreate, db: Annotated[AsyncSession, Depends(async_get_db)]
) -> dict[str, Any]:
    db_tier = await crud_tiers.get(db=db, name=tier_name, schema_to_select=TierRead)
    if not db_tier:
        raise NotFoundDomainError("Tier not found")

    rate_limit_internal_dict = rate_limit.model_dump()
    rate_limit_internal_dict["tier_id"] = db_tier["id"]

    db_rate_limit = await crud_rate_limits.exists(db=db, name=rate_limit_internal_dict["name"])
    if db_rate_limit:
        raise DuplicateValueDomainError("Rate Limit Name not available")

    rate_limit_internal = RateLimitCreateInternal(**rate_limit_internal_dict)
    created_rate_limit = await crud_rate_limits.create(
        db=db, object=rate_limit_internal, schema_to_select=RateLimitRead
    )

    if created_rate_limit is None:
        raise NotFoundDomainError("Failed to create rate limit")

    return created_rate_limit
