# FEATURE: revoke_moderator — endpoint integration tests.
#
# Covers: F1, F2, F3, F4, F12, F13, F14.
import pytest
from httpx import AsyncClient

pytestmark = pytest.mark.asyncio

_ENDPOINT = "/api/v1/users/{user_id}/revoke-moderator"


# ── F3: no token → 401 ────────────────────────────────────────────────────────


async def test_revoke_moderator_returns_401_without_token(
    async_client: AsyncClient,
) -> None:
    """F3 — missing Authorization header; 401 returned."""
    response = await async_client.patch(_ENDPOINT.format(user_id=1))
    assert response.status_code == 401


# ── F4: non-superuser → 403 ───────────────────────────────────────────────────


async def test_revoke_moderator_returns_403_for_non_superuser(
    async_client: AsyncClient,
    seeded_moderator_user: dict,
) -> None:
    """F4 — authenticated user is not a superuser; 403 returned."""
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    regular_user = {**seeded_moderator_user, "is_superuser": False}
    _fastapi_app.dependency_overrides[get_current_user] = lambda: regular_user
    try:
        response = await async_client.patch(_ENDPOINT.format(user_id=seeded_moderator_user["id"]))
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 403


# ── F2: non-integer path param → 422 ──────────────────────────────────────────


async def test_revoke_moderator_returns_422_for_non_integer_user_id(
    async_client: AsyncClient,
    seeded_superuser: dict,
) -> None:
    """F2 — non-integer user_id path param; 422 returned by FastAPI coercion."""
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    _fastapi_app.dependency_overrides[get_current_user] = lambda: seeded_superuser
    try:
        response = await async_client.patch("/api/v1/users/abc/revoke-moderator")
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 422


# ── F12: user not found → 404 ─────────────────────────────────────────────────


async def test_revoke_moderator_returns_404_for_unknown_user_id(
    async_client: AsyncClient,
    seeded_superuser: dict,
) -> None:
    """F12 — target user_id does not exist; 404 returned."""
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    _fastapi_app.dependency_overrides[get_current_user] = lambda: seeded_superuser
    try:
        response = await async_client.patch(_ENDPOINT.format(user_id=999999))
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 404
    body = response.json()
    assert body["error"]["code"] == "notfound"
    assert body["error"]["message"] == "User not found"


# ── F13: not a moderator → 409 ────────────────────────────────────────────────


async def test_revoke_moderator_returns_409_when_not_a_moderator(
    async_client: AsyncClient,
    seeded_regular_user: dict,
    seeded_superuser: dict,
) -> None:
    """F13 — target is not a moderator; 409 returned."""
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    _fastapi_app.dependency_overrides[get_current_user] = lambda: seeded_superuser
    try:
        response = await async_client.patch(_ENDPOINT.format(user_id=seeded_regular_user["id"]))
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 409
    assert response.json()["error"]["message"] == "User is not a moderator"


# ── F1: happy path → 200 ──────────────────────────────────────────────────────


async def test_revoke_moderator_returns_200_on_success(
    async_client: AsyncClient,
    seeded_moderator_user: dict,
    seeded_superuser: dict,
) -> None:
    """F1 — superuser revokes moderator; 200 with is_moderator=false."""
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    _fastapi_app.dependency_overrides[get_current_user] = lambda: seeded_superuser
    try:
        response = await async_client.patch(_ENDPOINT.format(user_id=seeded_moderator_user["id"]))
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 200
    body = response.json()
    assert body["id"] == seeded_moderator_user["id"]
    assert body["is_moderator"] is False
    assert body["username"] == seeded_moderator_user["username"]
    assert "name" in body
    assert "email" in body
    assert "profile_image_url" in body
    assert "tier_id" in body
    assert "moderator_granted_by_user_id" not in body
