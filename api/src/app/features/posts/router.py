# FEATURE: posts — router.
from fastapi import APIRouter

from .create_post.presentation.router import router as create_post_router
from .erase_db_post.presentation.router import router as erase_db_post_router
from .erase_post.presentation.router import router as erase_post_router
from .get_moderation_log.presentation.router import router as get_moderation_log_router
from .get_post.presentation.router import router as get_post_router
from .list_all_posts.presentation.router import router as list_all_posts_router
from .list_pending_posts.presentation.router import router as list_pending_posts_router
from .list_posts.presentation.router import router as list_posts_router
from .moderate_post.presentation.router import router as moderate_post_router
from .revise_post.presentation.router import router as revise_post_router
from .update_post.presentation.router import router as update_post_router

router = APIRouter(tags=["posts"])
router.include_router(list_posts_router)
router.include_router(list_all_posts_router)
router.include_router(create_post_router)
router.include_router(moderate_post_router)
router.include_router(revise_post_router)
router.include_router(list_pending_posts_router)
router.include_router(get_moderation_log_router)
router.include_router(get_post_router)
router.include_router(update_post_router)
router.include_router(erase_post_router)
router.include_router(erase_db_post_router)
