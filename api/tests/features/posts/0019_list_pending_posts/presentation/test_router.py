# FEATURE: list_pending_posts — endpoint integration tests.
#
# Covers: F1, F2, F3, F4, F10, F11, F15, F16, F17, F18, F19, F20.
import pytest
from httpx import AsyncClient

pytestmark = pytest.mark.asyncio

_ENDPOINT = "/api/v1/posts/pending"


# ── F15: no auth → 401 ───────────────────────────────────────────────────────


async def test_no_auth_returns_401(async_client: AsyncClient) -> None:
    """F15 — missing Authorization header → 401."""
    response = await async_client.get(_ENDPOINT)
    assert response.status_code == 401


# ── F16: regular user → 403 ──────────────────────────────────────────────────


async def test_regular_user_returns_403(
    async_client: AsyncClient,
    seeded_lpp_plain_user: dict,
) -> None:
    """F16 — authenticated non-moderator, non-superuser → 403."""
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    _fastapi_app.dependency_overrides[get_current_user] = lambda: seeded_lpp_plain_user
    try:
        response = await async_client.get(_ENDPOINT)
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 403


# ── F11: no pending posts → 200 empty ────────────────────────────────────────


async def test_no_pending_posts_returns_empty_200(
    async_client: AsyncClient,
    seeded_lpp_moderator: dict,
) -> None:
    """F11 — no pending posts in DB → 200 with items=[] and total_count=0."""
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    _fastapi_app.dependency_overrides[get_current_user] = lambda: seeded_lpp_moderator
    try:
        response = await async_client.get(_ENDPOINT)
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 200
    body = response.json()
    assert body["items"] == []
    assert body["total_count"] == 0


# ── F1, F2, F3, F4, F10, F17: moderator sees pending post ────────────────────


async def test_moderator_sees_pending_post_with_correct_shape(
    async_client: AsyncClient,
    seeded_lpp_moderator: dict,
    seeded_lpp_author: dict,
    seeded_lpp_post_with_log_entries: dict,
) -> None:
    """F1, F2, F3, F4, F10, F17 — moderator → 200; response shape + author_username + log."""
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    _fastapi_app.dependency_overrides[get_current_user] = lambda: seeded_lpp_moderator
    try:
        response = await async_client.get(_ENDPOINT)
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 200
    body = response.json()

    assert "items" in body
    assert "total_count" in body
    assert "page" in body
    assert "items_per_page" in body
    assert body["total_count"] == 1

    item = body["items"][0]
    assert "post_uuid" in item
    assert "title" in item
    assert "text" in item
    assert "media_url" in item
    assert "status" in item
    assert "created_at" in item
    assert "updated_at" in item
    assert item["author_username"] == seeded_lpp_author["username"]
    assert "moderation_log" in item

    log = item["moderation_log"]
    assert len(log) == 2
    for entry in log:
        assert "id" in entry
        assert "event_type" in entry
        assert "action" in entry
        assert "message" in entry
        assert "created_at" in entry


# ── F5: approved posts not in response ────────────────────────────────────────


async def test_approved_posts_not_in_response(
    async_client: AsyncClient,
    seeded_lpp_moderator: dict,
    seeded_lpp_author: dict,
) -> None:
    """F5 — approved post excluded from response."""
    from sqlalchemy import update as sa_update

    from app.adapters.db.models.post import Post
    from app.bootstrap.container import container as _di_container
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    async with _di_container.session_factory()() as session:
        post = Post(
            created_by_user_id=seeded_lpp_author["id"],
            title="Approved Post",
            text="Already approved.",
        )
        session.add(post)
        await session.commit()
        await session.refresh(post)
        await session.execute(sa_update(Post).where(Post.id == post.id).values(status="approved"))
        await session.commit()

    _fastapi_app.dependency_overrides[get_current_user] = lambda: seeded_lpp_moderator
    try:
        response = await async_client.get(_ENDPOINT)
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 200
    titles = [item["title"] for item in response.json()["items"]]
    assert "Approved Post" not in titles


# ── F18: superuser → 200 ──────────────────────────────────────────────────────


async def test_superuser_returns_200(async_client: AsyncClient) -> None:
    """F18 — superuser with is_moderator=False → 200."""
    from app.adapters.db.models.user import User
    from app.bootstrap.container import container as _di_container
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    async with _di_container.session_factory()() as session:
        superuser = User(
            name="LPP Superuser",
            username="lpp_superuser_test",
            email="lpp_superuser_test@example.com",
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
        response = await async_client.get(_ENDPOINT)
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 200


# ── F19: page=0 → 422 ────────────────────────────────────────────────────────


async def test_page_zero_returns_422(
    async_client: AsyncClient,
    seeded_lpp_moderator: dict,
) -> None:
    """F19 — page=0 violates ge=1 constraint → 422."""
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    _fastapi_app.dependency_overrides[get_current_user] = lambda: seeded_lpp_moderator
    try:
        response = await async_client.get(f"{_ENDPOINT}?page=0")
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 422


# ── F20: items_per_page=101 → 422 ────────────────────────────────────────────


async def test_items_per_page_over_max_returns_422(
    async_client: AsyncClient,
    seeded_lpp_moderator: dict,
) -> None:
    """F20 — items_per_page=101 violates le=100 constraint → 422."""
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    _fastapi_app.dependency_overrides[get_current_user] = lambda: seeded_lpp_moderator
    try:
        response = await async_client.get(f"{_ENDPOINT}?items_per_page=101")
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 422
