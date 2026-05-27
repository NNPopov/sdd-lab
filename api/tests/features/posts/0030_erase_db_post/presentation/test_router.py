# FEATURE: erase_db_post — endpoint integration tests.
#
# Covers: F1, F8, F9, F11. (updated for the {user_id} migration — slice 0058)
import pytest
from httpx import AsyncClient

pytestmark = pytest.mark.asyncio

_ENDPOINT = "/api/v1/{user_id}/db_post/{id}"

_SUPERUSER = {
    "id": 9998,
    "username": "ep30routeradmin",
    "email": "ep30routeradmin@example.com",
    "name": "EP30 Router Admin",
    "is_superuser": True,
}


# ── F1: happy path → 200 ─────────────────────────────────────────────────────


async def test_erase_db_post_returns_200_with_correct_body(
    async_client: AsyncClient,
    ep30_alice: dict,
    ep30_alice_post: dict,
) -> None:
    """F1 — superuser, valid user_id and post → 200 {'message': 'Post deleted from the database'}."""
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    url = _ENDPOINT.format(user_id=ep30_alice["id"], id=ep30_alice_post["id"])
    _fastapi_app.dependency_overrides[get_current_user] = lambda: _SUPERUSER
    try:
        response = await async_client.delete(url)
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 200
    assert response.json() == {"message": "Post deleted from the database"}


# ── F11: unknown user_id → 404 ───────────────────────────────────────────────


async def test_erase_db_post_returns_404_for_unknown_user_id(
    async_client: AsyncClient,
    ep30_alice: dict,
    ep30_alice_post: dict,
) -> None:
    """F11 — superuser supplies user_id not in DB → 404 'User not found'."""
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    url = _ENDPOINT.format(user_id=999999999, id=ep30_alice_post["id"])
    _fastapi_app.dependency_overrides[get_current_user] = lambda: _SUPERUSER
    try:
        response = await async_client.delete(url)
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 404
    assert response.json()["error"]["message"] == "User not found"


# ── F11: post not found ───────────────────────────────────────────────────────


async def test_erase_db_post_returns_404_for_unknown_post(
    async_client: AsyncClient,
    ep30_alice: dict,
) -> None:
    """F11 — superuser, valid user_id, post id not in DB → 404 'Post not found'."""
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    url = _ENDPOINT.format(user_id=ep30_alice["id"], id=999999999)
    _fastapi_app.dependency_overrides[get_current_user] = lambda: _SUPERUSER
    try:
        response = await async_client.delete(url)
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 404
    assert response.json()["error"]["message"] == "Post not found"


# ── F11: post belongs to different user (wrong owner id) → 404 ───────────────


async def test_erase_db_post_returns_404_when_post_belongs_to_other_user(
    async_client: AsyncClient,
    ep30_alice: dict,
    ep30_bob: dict,
    ep30_alice_post: dict,
) -> None:
    """F11 — superuser uses bob's user_id for alice's post_id → 404 (ownership filter)."""
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    url = _ENDPOINT.format(user_id=ep30_bob["id"], id=ep30_alice_post["id"])
    _fastapi_app.dependency_overrides[get_current_user] = lambda: _SUPERUSER
    try:
        response = await async_client.delete(url)
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 404
    assert response.json()["error"]["message"] == "Post not found"


# ── F11: soft-deleted post → 404 ─────────────────────────────────────────────


async def test_erase_db_post_returns_404_for_soft_deleted_post(
    async_client: AsyncClient,
    ep30_alice: dict,
) -> None:
    """F11 — superuser, post exists but is_deleted=True → 404 'Post not found'."""
    from app.adapters.db.models.post import Post
    from app.bootstrap.container import container as _di_container
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    async with _di_container.session_factory()() as session:
        post = Post(
            created_by_user_id=ep30_alice["id"],
            title="Soft deleted",
            text="text",
            is_deleted=True,
        )
        session.add(post)
        await session.commit()
        await session.refresh(post)
        post_id = post.id

    url = _ENDPOINT.format(user_id=ep30_alice["id"], id=post_id)
    _fastapi_app.dependency_overrides[get_current_user] = lambda: _SUPERUSER
    try:
        response = await async_client.delete(url)
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 404
    assert response.json()["error"]["message"] == "Post not found"


# ── F8: non-superuser → 403 ──────────────────────────────────────────────────


async def test_erase_db_post_returns_403_for_non_superuser(
    async_client: AsyncClient,
    ep30_alice: dict,
    ep30_alice_post: dict,
) -> None:
    """F8 — authenticated but not a superuser → 403."""
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    url = _ENDPOINT.format(user_id=ep30_alice["id"], id=ep30_alice_post["id"])
    _fastapi_app.dependency_overrides[get_current_user] = lambda: ep30_alice
    try:
        response = await async_client.delete(url)
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 403


# ── F9: unauthenticated → 401 ────────────────────────────────────────────────


async def test_erase_db_post_returns_401_without_token(
    async_client: AsyncClient,
    ep30_alice: dict,
    ep30_alice_post: dict,
) -> None:
    """F9 — no Authorization header → 401."""
    url = _ENDPOINT.format(user_id=ep30_alice["id"], id=ep30_alice_post["id"])
    response = await async_client.delete(url)
    assert response.status_code == 401
