# FEATURE: posts — router.
from typing import Annotated, Any

from fastapi import APIRouter, Depends, Request
from sqlalchemy.ext.asyncio import AsyncSession

from ...adapters.cache.redis_cache import cache
from ...adapters.db.session import async_get_db
from ...domain.errors import ForbiddenDomainError, NotFoundDomainError
from ..users.dependencies import get_current_superuser, get_current_user
from ..users.repository import crud_users
from ..users.schemas import UserRead
from .create_post.presentation.router import router as create_post_router
from .get_moderation_log.presentation.router import router as get_moderation_log_router
from .list_all_posts.presentation.router import router as list_all_posts_router
from .list_pending_posts.presentation.router import router as list_pending_posts_router
from .list_posts.presentation.router import router as list_posts_router
from .moderate_post.presentation.router import router as moderate_post_router
from .repository import crud_posts
from .revise_post.presentation.router import router as revise_post_router
from .schemas import PostRead, PostUpdate

router = APIRouter(tags=["posts"])
router.include_router(list_posts_router)
router.include_router(list_all_posts_router)
router.include_router(create_post_router)
router.include_router(moderate_post_router)
router.include_router(revise_post_router)
router.include_router(list_pending_posts_router)
router.include_router(get_moderation_log_router)


@router.get("/{username}/post/{id}", response_model=PostRead)
@cache(key_prefix="{username}_post_cache", resource_id_name="id")
async def read_post(
    request: Request, username: str, id: int, db: Annotated[AsyncSession, Depends(async_get_db)]
) -> dict[str, Any]:
    db_user = await crud_users.get(db=db, username=username, is_deleted=False, schema_to_select=UserRead)
    if db_user is None:
        raise NotFoundDomainError("User not found")

    db_post = await crud_posts.get(
        db=db, id=id, created_by_user_id=db_user["id"], is_deleted=False, schema_to_select=PostRead
    )
    if db_post is None:
        raise NotFoundDomainError("Post not found")

    return db_post


@router.patch("/{username}/post/{id}")
@cache("{username}_post_cache", resource_id_name="id", pattern_to_invalidate_extra=["{username}_posts:*"])
async def patch_post(
    request: Request,
    username: str,
    id: int,
    values: PostUpdate,
    current_user: Annotated[dict, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(async_get_db)],
) -> dict[str, str]:
    db_user = await crud_users.get(db=db, username=username, is_deleted=False, schema_to_select=UserRead)
    if db_user is None:
        raise NotFoundDomainError("User not found")

    if current_user["id"] != db_user["id"]:
        raise ForbiddenDomainError()

    db_post = await crud_posts.get(db=db, id=id, is_deleted=False, schema_to_select=PostRead)
    if db_post is None:
        raise NotFoundDomainError("Post not found")

    await crud_posts.update(db=db, object=values, id=id)
    return {"message": "Post updated"}


@router.delete("/{username}/post/{id}")
@cache("{username}_post_cache", resource_id_name="id", to_invalidate_extra={"{username}_posts": "{username}"})
async def erase_post(
    request: Request,
    username: str,
    id: int,
    current_user: Annotated[dict, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(async_get_db)],
) -> dict[str, str]:
    db_user = await crud_users.get(db=db, username=username, is_deleted=False, schema_to_select=UserRead)
    if db_user is None:
        raise NotFoundDomainError("User not found")

    if current_user["id"] != db_user["id"]:
        raise ForbiddenDomainError()

    db_post = await crud_posts.get(db=db, id=id, is_deleted=False, schema_to_select=PostRead)
    if db_post is None:
        raise NotFoundDomainError("Post not found")

    await crud_posts.delete(db=db, id=id)
    return {"message": "Post deleted"}


@router.delete("/{username}/db_post/{id}", dependencies=[Depends(get_current_superuser)])
@cache("{username}_post_cache", resource_id_name="id", to_invalidate_extra={"{username}_posts": "{username}"})
async def erase_db_post(
    request: Request, username: str, id: int, db: Annotated[AsyncSession, Depends(async_get_db)]
) -> dict[str, str]:
    db_user = await crud_users.get(db=db, username=username, is_deleted=False, schema_to_select=UserRead)
    if db_user is None:
        raise NotFoundDomainError("User not found")

    db_post = await crud_posts.get(db=db, id=id, is_deleted=False, schema_to_select=PostRead)
    if db_post is None:
        raise NotFoundDomainError("Post not found")

    await crud_posts.db_delete(db=db, id=id)
    return {"message": "Post deleted from the database"}
