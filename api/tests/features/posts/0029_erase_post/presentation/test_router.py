# FEATURE: erase_post — endpoint integration tests.
#
# Covers: F1, F2, F3, F4, F5.
import pytest
from httpx import AsyncClient

pytestmark = pytest.mark.asyncio

_ENDPOINT = "/api/v1/{username}/post/{id}"


# ── F1: happy path → 200 ─────────────────────────────────────────────────────


async def test_erase_post_returns_200_with_correct_body(
    async_client: AsyncClient,
    ep29_alice: dict,
    ep29_alice_post: dict,
) -> None:
    """F1 — valid token, owner, post exists → 200 {'message': 'Post deleted'}."""
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    url = _ENDPOINT.format(username="ep29alice", id=ep29_alice_post["id"])
    _fastapi_app.dependency_overrides[get_current_user] = lambda: ep29_alice
    try:
        response = await async_client.delete(url)
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 200
    assert response.json() == {"message": "Post deleted"}


# ── F4: ownership mismatch → 403 ─────────────────────────────────────────────


async def test_erase_post_returns_403_when_not_owner(
    async_client: AsyncClient,
    ep29_alice: dict,
    ep29_bob: dict,
    ep29_alice_post: dict,
) -> None:
    """F4 — requester is bob, path username is alice → 403."""
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    url = _ENDPOINT.format(username="ep29alice", id=ep29_alice_post["id"])
    _fastapi_app.dependency_overrides[get_current_user] = lambda: ep29_bob
    try:
        response = await async_client.delete(url)
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 403
    assert response.json()["error"]["code"] == "forbidden"


# ── F3: unknown username → 404 ────────────────────────────────────────────────


async def test_erase_post_returns_404_for_unknown_username(
    async_client: AsyncClient,
    ep29_alice: dict,
    ep29_alice_post: dict,
) -> None:
    """F3 — username not in DB → 404 'User not found'."""
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    url = _ENDPOINT.format(username="ghost_xyz_ep29", id=ep29_alice_post["id"])
    _fastapi_app.dependency_overrides[get_current_user] = lambda: ep29_alice
    try:
        response = await async_client.delete(url)
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 404
    assert response.json()["error"]["message"] == "User not found"


# ── F5: unknown post → 404 ────────────────────────────────────────────────────


async def test_erase_post_returns_404_for_unknown_post(
    async_client: AsyncClient,
    ep29_alice: dict,
) -> None:
    """F5 — post id not in DB → 404 'Post not found'."""
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    url = _ENDPOINT.format(username="ep29alice", id=999999999)
    _fastapi_app.dependency_overrides[get_current_user] = lambda: ep29_alice
    try:
        response = await async_client.delete(url)
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 404
    assert response.json()["error"]["message"] == "Post not found"


# ── F5: post belongs to different user (via own path) → 404 ──────────────────


async def test_erase_post_returns_404_when_post_belongs_to_other_user(
    async_client: AsyncClient,
    ep29_alice: dict,
    ep29_bob: dict,
    ep29_alice_post: dict,
) -> None:
    """F5 — bob uses his own path but alice's post_id → 404 (ownership gap fix)."""
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    url = _ENDPOINT.format(username="ep29bob", id=ep29_alice_post["id"])
    _fastapi_app.dependency_overrides[get_current_user] = lambda: ep29_bob
    try:
        response = await async_client.delete(url)
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 404
    assert response.json()["error"]["message"] == "Post not found"


# ── F2: missing token → 401 ──────────────────────────────────────────────────


async def test_erase_post_returns_401_without_token(
    async_client: AsyncClient,
    ep29_alice_post: dict,
) -> None:
    """F2 — no Authorization header → 401."""
    url = _ENDPOINT.format(username="ep29alice", id=ep29_alice_post["id"])
    response = await async_client.delete(url)
    assert response.status_code == 401
