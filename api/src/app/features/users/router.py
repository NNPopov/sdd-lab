# FEATURE: users — router.
from fastapi import APIRouter, Depends

from ...shared_dependencies import get_current_superuser
from ..users.schemas import UserMeRead
from .assign_moderator.presentation.router import router as assign_moderator_router
from .create_user.presentation.router import router as create_user_router
from .delete_db_user.presentation.router import router as delete_db_user_router
from .delete_user.presentation.router import router as delete_user_router
from .get_user_by_id.presentation.router import router as get_user_by_id_router
from .get_user_tier.presentation.router import router as get_user_tier_router
from .list_users.presentation.router import router as list_users_router
from .revoke_moderator.presentation.router import router as revoke_moderator_router
from .update_user.presentation.router import router as update_user_router
from .use_cases.user_get_me import read_users_me
from .use_cases.user_rate_limits_get import read_user_rate_limits
from .use_cases.user_tier_patch import patch_user_tier

router = APIRouter(tags=["users"])

router.include_router(create_user_router)
router.include_router(list_users_router)
router.include_router(get_user_by_id_router)
router.include_router(get_user_tier_router)
router.include_router(update_user_router)
router.include_router(delete_user_router)
router.include_router(delete_db_user_router)
router.include_router(assign_moderator_router)
router.include_router(revoke_moderator_router)
router.get("/user/me/", response_model=UserMeRead)(read_users_me)
router.get("/user/{username}/rate_limits", dependencies=[Depends(get_current_superuser)])(read_user_rate_limits)
router.patch("/user/{username}/tier", dependencies=[Depends(get_current_superuser)])(patch_user_tier)
