# FEATURE: health — router.
import logging
from datetime import UTC, datetime
from typing import Annotated

from fastapi import APIRouter, Depends, status
from fastapi.responses import JSONResponse
from redis.asyncio import Redis
from sqlalchemy.ext.asyncio import AsyncSession

from ...adapters.cache.redis_cache import async_get_redis
from ...adapters.db.session import async_get_db
from ...core.config import settings
from ...core.health import check_database_health, check_redis_health
from ...core.schemas import HealthCheck, ReadyCheck

router = APIRouter(tags=["health"])

STATUS_HEALTHY = "healthy"
STATUS_UNHEALTHY = "unhealthy"

LOGGER = logging.getLogger(__name__)


@router.get("/health", response_model=HealthCheck)
async def health():
    return JSONResponse(
        status_code=status.HTTP_200_OK,
        content={
            "status": STATUS_HEALTHY,
            "environment": settings.ENVIRONMENT.value,
            "version": settings.APP_VERSION,
            "timestamp": datetime.now(UTC).isoformat(timespec="seconds"),
        },
    )


@router.get("/ready", response_model=ReadyCheck)
async def ready(
    redis: Annotated[Redis, Depends(async_get_redis)],
    db: Annotated[AsyncSession, Depends(async_get_db)],
):
    database_status = await check_database_health(db=db)
    LOGGER.debug(f"Database health check status: {database_status}")
    redis_status = await check_redis_health(redis=redis)
    LOGGER.debug(f"Redis health check status: {redis_status}")

    overall_status = STATUS_HEALTHY if database_status and redis_status else STATUS_UNHEALTHY
    http_status = status.HTTP_200_OK if overall_status == STATUS_HEALTHY else status.HTTP_503_SERVICE_UNAVAILABLE

    return JSONResponse(
        status_code=http_status,
        content={
            "status": overall_status,
            "environment": settings.ENVIRONMENT.value,
            "version": settings.APP_VERSION,
            "app": STATUS_HEALTHY,
            "database": STATUS_HEALTHY if database_status else STATUS_UNHEALTHY,
            "redis": STATUS_HEALTHY if redis_status else STATUS_UNHEALTHY,
            "timestamp": datetime.now(UTC).isoformat(timespec="seconds"),
        },
    )
