# FEATURE: update_user_route_to_user_id — endpoint integration tests.
#
# Covers: F1, F2, F3, F4, F5, F6.
import pytest
from httpx import AsyncClient

pytestmark = pytest.mark.asyncio

_ENDPOINT = "/api/v1/user/{user_id}"


# ── F1: happy path → 200 ──────────────────────────────────────────────────────


async def test_update_user_returns_200_on_success(
    async_client: AsyncClient,
    seeded_alice: dict,
) -> None:
    """F1 — owner sends valid patch by integer ID; receives 200 and confirmation message."""
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    _fastapi_app.dependency_overrides[get_current_user] = lambda: seeded_alice
    try:
        response = await async_client.patch(
            _ENDPOINT.format(user_id=seeded_alice["id"]),
            json={"name": "Alice New Name"},
        )
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 200
    assert response.json() == {"message": "User updated"}


# ── F2: non-integer user_id → 422 ─────────────────────────────────────────────


async def test_update_user_returns_422_for_non_integer_user_id(
    async_client: AsyncClient,
    seeded_alice: dict,
) -> None:
    """F2 — non-integer path param; FastAPI rejects with 422."""
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    _fastapi_app.dependency_overrides[get_current_user] = lambda: seeded_alice
    try:
        response = await async_client.patch(
            "/api/v1/user/not-an-int",
            json={"name": "Whatever"},
        )
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 422


# ── F3: missing/invalid token → 401 ──────────────────────────────────────────


async def test_update_user_returns_401_without_token(
    async_client: AsyncClient,
    seeded_alice: dict,
) -> None:
    """F3 — no Authorization header; 401 returned."""
    response = await async_client.patch(
        _ENDPOINT.format(user_id=seeded_alice["id"]),
        json={"name": "Unauthorized"},
    )
    assert response.status_code == 401


# ── F5: forbidden — wrong owner → 403 ────────────────────────────────────────


async def test_update_user_returns_403_when_not_owner(
    async_client: AsyncClient,
    seeded_alice: dict,
    seeded_bob: dict,
) -> None:
    """F5 — bob attempts to update alice's profile; 403 returned."""
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    _fastapi_app.dependency_overrides[get_current_user] = lambda: seeded_bob
    try:
        response = await async_client.patch(
            _ENDPOINT.format(user_id=seeded_alice["id"]),
            json={"name": "Hacked"},
        )
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 403
    assert response.json() == {"error": {"code": "forbidden", "message": ""}}


# ── F4: not found → 404 ───────────────────────────────────────────────────────


async def test_update_user_returns_404_for_unknown_user_id(
    async_client: AsyncClient,
    seeded_alice: dict,
) -> None:
    """F4 — target user_id does not exist; 404 returned."""
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    _fastapi_app.dependency_overrides[get_current_user] = lambda: seeded_alice
    try:
        response = await async_client.patch(
            _ENDPOINT.format(user_id=999999),
            json={"name": "No One"},
        )
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 404
    body = response.json()
    assert body["error"]["code"] == "notfound"
    assert body["error"]["message"] == "User not found"


# ── F6: duplicate email → 409 ─────────────────────────────────────────────────


async def test_update_user_returns_409_when_email_taken(
    async_client: AsyncClient,
    seeded_alice: dict,
    seeded_bob: dict,
) -> None:
    """F6 — new email already belongs to another user; 409 returned."""
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    _fastapi_app.dependency_overrides[get_current_user] = lambda: seeded_alice
    try:
        response = await async_client.patch(
            _ENDPOINT.format(user_id=seeded_alice["id"]),
            json={"email": "bob@example.com"},
        )
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 409


# ── F6: duplicate username → 409 ─────────────────────────────────────────────


async def test_update_user_returns_409_when_username_taken(
    async_client: AsyncClient,
    seeded_alice: dict,
    seeded_bob: dict,
) -> None:
    """F6 — new username already belongs to another user; 409 returned."""
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    _fastapi_app.dependency_overrides[get_current_user] = lambda: seeded_alice
    try:
        response = await async_client.patch(
            _ENDPOINT.format(user_id=seeded_alice["id"]),
            json={"username": "bob"},
        )
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 409


# ── invalid field body → 422 ──────────────────────────────────────────────────


async def test_update_user_returns_422_for_invalid_username_pattern(
    async_client: AsyncClient,
    seeded_alice: dict,
) -> None:
    """F2 — username with uppercase violates pattern; 422 returned."""
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    _fastapi_app.dependency_overrides[get_current_user] = lambda: seeded_alice
    try:
        response = await async_client.patch(
            _ENDPOINT.format(user_id=seeded_alice["id"]),
            json={"username": "ALICE_CAPS"},
        )
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 422
