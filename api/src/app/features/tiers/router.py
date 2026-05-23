# FEATURE: tiers — router.
from fastapi import APIRouter

from .create_tier.presentation.router import router as create_tier_router
from .delete_tier.presentation.router import router as delete_tier_router
from .get_tier.presentation.router import router as get_tier_router
from .list_tiers.presentation.router import router as list_tiers_router
from .update_tier.presentation.router import router as update_tier_router

router = APIRouter(tags=["tiers"])
router.include_router(create_tier_router)
router.include_router(list_tiers_router)
router.include_router(get_tier_router)
router.include_router(update_tier_router)
router.include_router(delete_tier_router)
