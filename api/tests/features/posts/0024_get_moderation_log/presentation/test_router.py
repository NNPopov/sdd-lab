# FEATURE: get_moderation_log — endpoint integration tests.
#
# Covers: F1, F2, F3, F4, F5, F6, F7, F8, F10, F12, F13.
import uuid

import pytest
from httpx import AsyncClient

pytestmark = pytest.mark.asyncio

_ENDPOINT = "/api/v1/posts/{post_uuid}/moderation-log"


def _url(post_uuid) -> str:
    return _ENDPOINT.format(post_uuid=str(post_uuid))


# ── F2: no auth → 401 ────────────────────────────────────────────────────────


async def test_no_auth_returns_401(async_client: AsyncClient) -> None:
    """F2 — missing Authorization header → 401."""
    response = await async_client.get(_url(uuid.uuid4()))
    assert response.status_code == 401


# ── F5: plain user → 403 ──────────────────────────────────────────────────────


async def test_plain_user_returns_403(
    async_client: AsyncClient,
    seeded_gml_plain_user: dict,
    seeded_gml_post_with_log: dict,
) -> None:
    """F5 — authenticated non-author, non-moderator, non-superuser → 403."""
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    _fastapi_app.dependency_overrides[get_current_user] = lambda: seeded_gml_plain_user
    try:
        response = await async_client.get(_url(seeded_gml_post_with_log["uuid"]))
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 403


# ── F3: non-existent post UUID → 404 ─────────────────────────────────────────


async def test_nonexistent_post_returns_404(
    async_client: AsyncClient,
    seeded_gml_author: dict,
) -> None:
    """F3 — post UUID not in DB → 404."""
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    _fastapi_app.dependency_overrides[get_current_user] = lambda: seeded_gml_author
    try:
        response = await async_client.get(_url(uuid.uuid4()))
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 404


# ── F4: soft-deleted post → 404 ───────────────────────────────────────────────


async def test_soft_deleted_post_returns_404(
    async_client: AsyncClient,
    seeded_gml_author: dict,
) -> None:
    """F4 — post with is_deleted=True → 404."""
    from sqlalchemy import update as sa_update

    from app.adapters.db.models.post import Post
    from app.bootstrap.container import container as _di_container
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    async with _di_container.session_factory()() as session:
        post = Post(
            created_by_user_id=seeded_gml_author["id"],
            title="Deleted",
            text="body",
        )
        session.add(post)
        await session.commit()
        await session.refresh(post)
        post_uuid = post.uuid
        await session.execute(sa_update(Post).where(Post.id == post.id).values(is_deleted=True))
        await session.commit()

    _fastapi_app.dependency_overrides[get_current_user] = lambda: seeded_gml_author
    try:
        response = await async_client.get(_url(post_uuid))
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 404


# ── F1, F10: author, no log entries → 200 with empty items ────────────────────


async def test_author_with_no_log_entries_returns_200_empty(
    async_client: AsyncClient,
    seeded_gml_author: dict,
) -> None:
    """F1, F10 — author calls log on newly created post → 200 with items=[]."""
    from app.adapters.db.models.post import Post
    from app.bootstrap.container import container as _di_container
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    async with _di_container.session_factory()() as session:
        post = Post(
            created_by_user_id=seeded_gml_author["id"],
            title="Empty Log Post",
            text="body",
        )
        session.add(post)
        await session.commit()
        await session.refresh(post)
        post_uuid = post.uuid

    _fastapi_app.dependency_overrides[get_current_user] = lambda: seeded_gml_author
    try:
        response = await async_client.get(_url(post_uuid))
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 200
    assert response.json() == {"items": []}


# ── F1, F6, F12, F13: author reads log with entries ──────────────────────────


async def test_author_reads_log_with_entries(
    async_client: AsyncClient,
    seeded_gml_author: dict,
    seeded_gml_moderator: dict,
    seeded_gml_post_with_log: dict,
) -> None:
    """F1, F6, F12, F13 — author → 200 with entries and actor_username resolved."""
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    _fastapi_app.dependency_overrides[get_current_user] = lambda: seeded_gml_author
    try:
        response = await async_client.get(_url(seeded_gml_post_with_log["uuid"]))
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 200
    body = response.json()
    assert "items" in body
    assert len(body["items"]) == 2
    entry = body["items"][0]
    assert "id" in entry
    assert "event_type" in entry
    assert "action" in entry
    assert "message" in entry
    assert "created_at" in entry
    assert "actor_user_id" in entry
    assert "actor_username" in entry
    assert entry["actor_username"] == seeded_gml_moderator["username"]


# ── F7: moderator (not author) → 200 ─────────────────────────────────────────


async def test_moderator_reads_log(
    async_client: AsyncClient,
    seeded_gml_moderator: dict,
    seeded_gml_post_with_log: dict,
) -> None:
    """F7 — moderator (not author) → 200."""
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    _fastapi_app.dependency_overrides[get_current_user] = lambda: seeded_gml_moderator
    try:
        response = await async_client.get(_url(seeded_gml_post_with_log["uuid"]))
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 200


# ── F8: superuser (not author) → 200 ─────────────────────────────────────────


async def test_superuser_reads_log(
    async_client: AsyncClient,
    seeded_gml_post_with_log: dict,
) -> None:
    """F8 — superuser (not author) → 200."""
    from app.adapters.db.models.user import User
    from app.bootstrap.container import container as _di_container
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    async with _di_container.session_factory()() as session:
        superuser = User(
            name="GML Superuser",
            username="gmlsuper",
            email="gmlsuper@example.com",
            hashed_password="x",
            is_superuser=True,
        )
        session.add(superuser)
        await session.commit()
        await session.refresh(superuser)
        superuser_dict = {
            "id": superuser.id,
            "username": superuser.username,
            "email": superuser.email,
            "name": superuser.name,
            "is_superuser": superuser.is_superuser,
            "is_moderator": superuser.is_moderator,
        }

    _fastapi_app.dependency_overrides[get_current_user] = lambda: superuser_dict
    try:
        response = await async_client.get(_url(seeded_gml_post_with_log["uuid"]))
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 200
