# STABLE: Cross-slice dependencies. Rate limiting and auth helpers cross all feature slices.
from typing import Annotated, Any

from dependency_injector.wiring import Provide, inject
from fastapi import Depends, HTTPException, Request
from fastcrud.exceptions.http_exceptions import ForbiddenException, RateLimitException, UnauthorizedException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from .adapters.db.models.user import User as UserModel
from .adapters.db.session import async_get_db
from .adapters.rate_limit.redis_rate_limiter import rate_limiter
from .bootstrap.container import Container
from .core.config import settings
from .core.logger import logging
from .core.security import TokenType, oauth2_scheme, verify_token
from .features.rate_limits.repository import crud_rate_limits
from .features.rate_limits.schemas import RateLimitRead, sanitize_path
from .features.tiers.repository import crud_tiers
from .features.tiers.schemas import TierRead
from .ports.token_blacklist import TokenBlacklistPort

logger = logging.getLogger(__name__)

DEFAULT_LIMIT = settings.DEFAULT_RATE_LIMIT_LIMIT
DEFAULT_PERIOD = settings.DEFAULT_RATE_LIMIT_PERIOD


async def _get_user_by_credential(db: AsyncSession, credential: str) -> dict[str, Any] | None:
    stmt = select(UserModel)
    if "@" in credential:
        stmt = stmt.where(UserModel.email == credential, UserModel.is_deleted.is_(False))
    else:
        stmt = stmt.where(UserModel.username == credential, UserModel.is_deleted.is_(False))
    result = await db.execute(stmt)
    row = result.scalar_one_or_none()
    if row is None:
        return None
    return {
        "id": row.id,
        "name": row.name,
        "username": row.username,
        "email": row.email,
        "profile_image_url": row.profile_image_url,
        "is_superuser": row.is_superuser,
        "is_moderator": row.is_moderator,
        "tier_id": row.tier_id,
    }


@inject
async def get_current_user(
    token: Annotated[str, Depends(oauth2_scheme)],
    db: Annotated[AsyncSession, Depends(async_get_db)],
    blacklist: Annotated[TokenBlacklistPort, Depends(Provide[Container.token_blacklist_adapter])],
) -> dict[str, Any]:
    token_data = await verify_token(token, TokenType.ACCESS, blacklist)
    if token_data is None:
        raise UnauthorizedException("User not authenticated.")
    user = await _get_user_by_credential(db, token_data.username_or_email)
    if user is None:
        raise UnauthorizedException("User not authenticated.")
    return user


@inject
async def get_optional_user(
    request: Request,
    db: AsyncSession = Depends(async_get_db),
    blacklist: TokenBlacklistPort = Depends(Provide[Container.token_blacklist_adapter]),
) -> dict | None:
    token = request.headers.get("Authorization")
    if not token:
        return None

    try:
        token_type, _, token_value = token.partition(" ")
        if token_type.lower() != "bearer" or not token_value:
            return None

        token_data = await verify_token(token_value, TokenType.ACCESS, blacklist)
        if token_data is None:
            return None

        return await _get_user_by_credential(db, token_data.username_or_email)

    except HTTPException as http_exc:
        if http_exc.status_code != 401:
            logger.error(f"Unexpected HTTPException in get_optional_user: {http_exc.detail}")
        return None

    except Exception as exc:
        logger.error(f"Unexpected error in get_optional_user: {exc}")
        return None


async def get_current_superuser(current_user: Annotated[dict, Depends(get_current_user)]) -> dict:
    if not current_user["is_superuser"]:
        raise ForbiddenException("You do not have enough privileges.")
    return current_user


async def get_current_moderator_or_superuser(
    current_user: Annotated[dict, Depends(get_current_user)],
) -> dict:
    if not (current_user.get("is_moderator") or current_user.get("is_superuser")):
        raise ForbiddenException("You do not have enough privileges.")
    return current_user


async def rate_limiter_dependency(
    request: Request,
    db: Annotated[AsyncSession, Depends(async_get_db)],
    user: dict | None = Depends(get_optional_user),
) -> None:
    if hasattr(request.app.state, "initialization_complete"):
        await request.app.state.initialization_complete.wait()

    path = sanitize_path(request.url.path)
    if user:
        user_id = user["id"]
        tier = await crud_tiers.get(db, id=user["tier_id"], schema_to_select=TierRead)
        if tier:
            rate_limit = await crud_rate_limits.get(
                db=db, tier_id=tier["id"], path=path, schema_to_select=RateLimitRead
            )
            if rate_limit:
                limit, period = rate_limit["limit"], rate_limit["period"]
            else:
                logger.warning(
                    f"User {user_id} with tier '{tier['name']}' has no specific rate limit for path '{path}'. "
                    "Applying default rate limit."
                )
                limit, period = DEFAULT_LIMIT, DEFAULT_PERIOD
        else:
            logger.warning(f"User {user_id} has no assigned tier. Applying default rate limit.")
            limit, period = DEFAULT_LIMIT, DEFAULT_PERIOD
    else:
        user_id = request.client.host if request.client else "unknown"
        limit, period = DEFAULT_LIMIT, DEFAULT_PERIOD

    is_limited = await rate_limiter.is_rate_limited(db=db, user_id=user_id, path=path, limit=limit, period=period)
    if is_limited:
        raise RateLimitException("Rate limit exceeded.")
