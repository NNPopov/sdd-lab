# FEATURE: users — use case: get user rate limits.
from typing import Annotated, Any

from fastapi import Depends, Request
from sqlalchemy.ext.asyncio import AsyncSession

from ....adapters.db.session import async_get_db
from ....domain.errors import NotFoundDomainError
from ....features.rate_limits.repository import crud_rate_limits
from ....features.tiers.repository import crud_tiers
from ....features.tiers.schemas import TierRead
from ..repository import crud_users
from ..schemas import UserRead


async def read_user_rate_limits(
    request: Request, user_id: int, db: Annotated[AsyncSession, Depends(async_get_db)]
) -> dict[str, Any]:
    db_user = await crud_users.get(db=db, id=user_id, schema_to_select=UserRead)
    if db_user is None:
        raise NotFoundDomainError("User not found")

    user_dict = dict(db_user)
    if db_user["tier_id"] is None:
        user_dict["tier_rate_limits"] = []
        return user_dict

    db_tier = await crud_tiers.get(db=db, id=db_user["tier_id"], schema_to_select=TierRead)
    if db_tier is None:
        raise NotFoundDomainError("Tier not found")

    db_rate_limits = await crud_rate_limits.get_multi(db=db, tier_id=db_tier["id"])
    user_dict["tier_rate_limits"] = db_rate_limits["data"]

    return user_dict
