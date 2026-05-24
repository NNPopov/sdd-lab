# FEATURE: delete_user — endpoint integration tests.
#
# Covers: F1, F2, F3, F13, F14.
import pytest
from httpx import AsyncClient

pytestmark = pytest.mark.asyncio

_ENDPOINT = "/api/v1/user/{user_id}"


# ── F1: happy path → 200 ──────────────────────────────────────────────────────


async def test_delete_user_returns_200_on_success(
    async_client: AsyncClient,
    seeded_alice: dict,
    alice_token: str,
) -> None:
    """F1 — owner deletes own account by integer ID; 200 and confirmation message."""
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    _fastapi_app.dependency_overrides[get_current_user] = lambda: seeded_alice
    try:
        response = await async_client.delete(
            _ENDPOINT.format(user_id=seeded_alice["id"]),
            headers={"Authorization": f"Bearer {alice_token}"},
        )
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 200
    assert response.json() == {"message": "User deleted"}


# ── F13: not found → 404 ─────────────────────────────────────────────────────


async def test_delete_user_returns_404_for_unknown_id(
    async_client: AsyncClient,
    seeded_alice: dict,
    alice_token: str,
) -> None:
    """F13 — target user_id does not exist; 404 returned."""
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    _fastapi_app.dependency_overrides[get_current_user] = lambda: seeded_alice
    try:
        response = await async_client.delete(
            _ENDPOINT.format(user_id=999999),
            headers={"Authorization": f"Bearer {alice_token}"},
        )
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 404
    body = response.json()
    assert body["error"]["code"] == "notfound"
    assert body["error"]["message"] == "User not found"


# ── F14: forbidden — wrong owner → 403 ───────────────────────────────────────


async def test_delete_user_returns_403_when_not_owner(
    async_client: AsyncClient,
    seeded_alice: dict,
    seeded_bob: dict,
    alice_token: str,
) -> None:
    """F14 — alice attempts to delete bob's account; 403 returned."""
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    _fastapi_app.dependency_overrides[get_current_user] = lambda: seeded_alice
    try:
        response = await async_client.delete(
            _ENDPOINT.format(user_id=seeded_bob["id"]),
            headers={"Authorization": f"Bearer {alice_token}"},
        )
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 403
    assert response.json() == {"error": {"code": "forbidden", "message": ""}}


# ── F3: missing token → 401 ───────────────────────────────────────────────────


async def test_delete_user_returns_401_without_token(
    async_client: AsyncClient,
    seeded_alice: dict,
) -> None:
    """F3 — no Authorization header; 401 returned."""
    response = await async_client.delete(_ENDPOINT.format(user_id=seeded_alice["id"]))
    assert response.status_code == 401


# ── F2: non-integer path param → 422 ─────────────────────────────────────────


async def test_delete_user_returns_422_for_non_integer_user_id(
    async_client: AsyncClient,
    seeded_alice: dict,
    alice_token: str,
) -> None:
    """F2 — non-integer user_id path param rejected by FastAPI with 422."""
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    _fastapi_app.dependency_overrides[get_current_user] = lambda: seeded_alice
    try:
        response = await async_client.delete(
            "/api/v1/user/abc",
            headers={"Authorization": f"Bearer {alice_token}"},
        )
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 422
