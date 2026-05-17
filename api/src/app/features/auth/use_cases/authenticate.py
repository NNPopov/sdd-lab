# FEATURE: auth — use case: authenticate user credentials.
# Extracted from core/security.py to fix core→features import violation.
from typing import Any, Literal

from sqlalchemy.ext.asyncio import AsyncSession

from ....core.security import verify_password
from ...users.repository import crud_users


async def authenticate_user(username_or_email: str, password: str, db: AsyncSession) -> dict[str, Any] | Literal[False]:
    if "@" in username_or_email:
        db_user = await crud_users.get(db=db, email=username_or_email, is_deleted=False)
    else:
        db_user = await crud_users.get(db=db, username=username_or_email, is_deleted=False)

    if not db_user:
        return False

    if not await verify_password(password, db_user["hashed_password"]):
        return False

    return db_user
