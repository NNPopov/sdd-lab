# STABLE: Root API router. Register new feature routers here.
# Rule: only main.py and bootstrap/factory.py import from this module.
from fastapi import APIRouter

from ..features.auth.router import router as auth_router
from ..features.health.router import router as health_router
from ..features.posts.router import router as posts_router
from ..features.rate_limits.router import router as rate_limits_router
from ..features.tasks.router import router as tasks_router
from ..features.tiers.router import router as tiers_router
from ..features.users.router import router as users_router

router = APIRouter(prefix="/api/v1")
router.include_router(health_router)
router.include_router(auth_router)
router.include_router(users_router)
router.include_router(posts_router)
router.include_router(tasks_router)
router.include_router(tiers_router)
router.include_router(rate_limits_router)
