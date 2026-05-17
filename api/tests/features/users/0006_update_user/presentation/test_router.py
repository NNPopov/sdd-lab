# FEATURE: update_user — endpoint integration tests.
#
# Covers: F1–F6.
import pytest
from httpx import AsyncClient

pytestmark = pytest.mark.asyncio

_ENDPOINT = "/api/v1/user/{username}"


# ── F1, F13: happy path → 200 ─────────────────────────────────────────────────


async def test_update_user_returns_200_on_success(
    async_client: AsyncClient,
    seeded_alice: dict,
) -> None:
    """F1, F13 — owner sends valid patch; receives 200 and confirmation message."""
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    _fastapi_app.dependency_overrides[get_current_user] = lambda: seeded_alice
    try:
        response = await async_client.patch(
            _ENDPOINT.format(username="alice"),
            json={"name": "Alice New Name"},
        )
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 200
    assert response.json() == {"message": "User updated"}


# ── F3: forbidden — wrong owner → 403 ────────────────────────────────────────


async def test_update_user_returns_403_when_not_owner(
    async_client: AsyncClient,
    seeded_alice: dict,
    seeded_bob: dict,
) -> None:
    """F3 — requester does not own the target profile; 403 returned."""
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    _fastapi_app.dependency_overrides[get_current_user] = lambda: seeded_bob
    try:
        response = await async_client.patch(
            _ENDPOINT.format(username="alice"),
            json={"name": "Hacked"},
        )
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 403


# ── F4: not found → 404 ───────────────────────────────────────────────────────


async def test_update_user_returns_404_for_unknown_username(
    async_client: AsyncClient,
    seeded_alice: dict,
) -> None:
    """F4 — target username does not exist; 404 returned."""
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    _fastapi_app.dependency_overrides[get_current_user] = lambda: seeded_alice
    try:
        response = await async_client.patch(
            _ENDPOINT.format(username="ghost_xyz_99"),
            json={"name": "No One"},
        )
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 404
    body = response.json()
    assert body["error"]["code"] == "notfound"
    assert body["error"]["message"] == "User not found"


# ── F5: duplicate email → 409 ─────────────────────────────────────────────────


async def test_update_user_returns_409_when_email_taken(
    async_client: AsyncClient,
    seeded_alice: dict,
    seeded_bob: dict,
) -> None:
    """F5 — new email already belongs to another user; 409 returned."""
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    _fastapi_app.dependency_overrides[get_current_user] = lambda: seeded_alice
    try:
        response = await async_client.patch(
            _ENDPOINT.format(username="alice"),
            json={"email": "bob@example.com"},  # bob's email
        )
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 409


# ── F5: duplicate username → 409 ─────────────────────────────────────────────


async def test_update_user_returns_409_when_username_taken(
    async_client: AsyncClient,
    seeded_alice: dict,
    seeded_bob: dict,
) -> None:
    """F5 — new username already belongs to another user; 409 returned."""
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    _fastapi_app.dependency_overrides[get_current_user] = lambda: seeded_alice
    try:
        response = await async_client.patch(
            _ENDPOINT.format(username="alice"),
            json={"username": "bob"},  # bob's username
        )
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 409


# ── F2: missing/invalid token → 401 ──────────────────────────────────────────


async def test_update_user_returns_401_without_token(
    async_client: AsyncClient,
    seeded_alice: dict,
) -> None:
    """F2 — no Authorization header; 401 returned."""
    response = await async_client.patch(
        _ENDPOINT.format(username="alice"),
        json={"name": "Unauthorized"},
    )
    assert response.status_code == 401


# ── F6: invalid field → 422 ──────────────────────────────────────────────────


async def test_update_user_returns_422_for_invalid_username_pattern(
    async_client: AsyncClient,
    seeded_alice: dict,
) -> None:
    """F6 — username with uppercase violates pattern; 422 returned."""
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    _fastapi_app.dependency_overrides[get_current_user] = lambda: seeded_alice
    try:
        response = await async_client.patch(
            _ENDPOINT.format(username="alice"),
            json={"username": "ALICE_CAPS"},
        )
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 422
