# FEATURE: update_post — endpoint integration tests.
#
# Covers: F1, F2, F3, F4, F5, F11 (updated for the {user_id} migration — slice 0056).
import pytest
from httpx import AsyncClient

pytestmark = pytest.mark.asyncio

_ENDPOINT = "/api/v1/{user_id}/post/{id}"


# ── F1: happy path → 200 ─────────────────────────────────────────────────────


async def test_update_post_returns_200_with_correct_body(
    async_client: AsyncClient,
    up28_alice: dict,
    up28_alice_post: dict,
) -> None:
    """F1 — valid token, owner, valid partial body → 200 {'message': 'Post updated'}."""
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    url = _ENDPOINT.format(user_id=up28_alice["id"], id=up28_alice_post["id"])
    _fastapi_app.dependency_overrides[get_current_user] = lambda: up28_alice
    try:
        response = await async_client.patch(url, json={"title": "Changed title"})
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 200
    assert response.json() == {"message": "Post updated"}


# ── F4: ownership violation → 403 ────────────────────────────────────────────


async def test_update_post_returns_403_when_not_owner(
    async_client: AsyncClient,
    up28_alice: dict,
    up28_bob: dict,
    up28_alice_post: dict,
) -> None:
    """F4 — requester does not own the user_id → bare 403."""
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    url = _ENDPOINT.format(user_id=up28_alice["id"], id=up28_alice_post["id"])
    _fastapi_app.dependency_overrides[get_current_user] = lambda: up28_bob
    try:
        response = await async_client.patch(url, json={"title": "Stolen title"})
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 403
    assert response.json()["error"]["code"] == "forbidden"


# ── F3: unknown user_id → 404 ─────────────────────────────────────────────────


async def test_update_post_returns_404_for_unknown_user(
    async_client: AsyncClient,
    up28_alice: dict,
    up28_alice_post: dict,
) -> None:
    """F3 — user_id not in DB → 404."""
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    url = _ENDPOINT.format(user_id=999999999, id=up28_alice_post["id"])
    _fastapi_app.dependency_overrides[get_current_user] = lambda: up28_alice
    try:
        response = await async_client.patch(url, json={"title": "Any title"})
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 404
    assert response.json()["error"]["message"] == "User not found"


# ── F5: unknown post → 404 ────────────────────────────────────────────────────


async def test_update_post_returns_404_for_unknown_post(
    async_client: AsyncClient,
    up28_alice: dict,
) -> None:
    """F5 — post id not in DB → 404."""
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    url = _ENDPOINT.format(user_id=up28_alice["id"], id=999999999)
    _fastapi_app.dependency_overrides[get_current_user] = lambda: up28_alice
    try:
        response = await async_client.patch(url, json={"title": "Any title"})
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 404
    assert response.json()["error"]["message"] == "Post not found"


# ── F2: missing/invalid token → 401 ──────────────────────────────────────────


async def test_update_post_returns_401_without_token(
    async_client: AsyncClient,
    up28_alice: dict,
    up28_alice_post: dict,
) -> None:
    """F2 — no Authorization header → 401."""
    url = _ENDPOINT.format(user_id=up28_alice["id"], id=up28_alice_post["id"])
    response = await async_client.patch(url, json={"title": "Any title"})
    assert response.status_code == 401


# ── F11: field validation → 422 ──────────────────────────────────────────────


async def test_update_post_returns_422_when_title_too_short(
    async_client: AsyncClient,
    up28_alice: dict,
    up28_alice_post: dict,
) -> None:
    """F11 — title shorter than min_length=2 → 422."""
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    url = _ENDPOINT.format(user_id=up28_alice["id"], id=up28_alice_post["id"])
    _fastapi_app.dependency_overrides[get_current_user] = lambda: up28_alice
    try:
        response = await async_client.patch(url, json={"title": "x"})
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 422
