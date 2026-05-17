# FEATURE: delete_user — endpoint integration tests.
#
# Covers: F1, F7, F8, F9, F10.
import pytest
from httpx import AsyncClient

pytestmark = pytest.mark.asyncio

_ENDPOINT = "/api/v1/user/{username}"


# ── F1, F7: happy path → 200, row soft-deleted ───────────────────────────────


async def test_delete_user_returns_200_on_success(
    async_client: AsyncClient,
    seeded_alice: dict,
    alice_token: str,
) -> None:
    """F1, F7 — owner deletes own account; 200 and confirmation message."""
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    _fastapi_app.dependency_overrides[get_current_user] = lambda: seeded_alice
    try:
        response = await async_client.delete(
            _ENDPOINT.format(username="alice"),
            headers={"Authorization": f"Bearer {alice_token}"},
        )
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 200
    assert response.json() == {"message": "User deleted"}


# ── F10: not found → 404 ──────────────────────────────────────────────────────


async def test_delete_user_returns_404_for_unknown_username(
    async_client: AsyncClient,
    seeded_alice: dict,
    alice_token: str,
) -> None:
    """F10 — target username does not exist; 404 returned."""
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    _fastapi_app.dependency_overrides[get_current_user] = lambda: seeded_alice
    try:
        response = await async_client.delete(
            _ENDPOINT.format(username="ghost_xyz_99"),
            headers={"Authorization": f"Bearer {alice_token}"},
        )
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 404
    body = response.json()
    assert body["error"]["code"] == "notfound"
    assert body["error"]["message"] == "User not found"


# ── F9: forbidden — wrong owner → 403 ────────────────────────────────────────


async def test_delete_user_returns_403_when_not_owner(
    async_client: AsyncClient,
    seeded_alice: dict,
    seeded_bob: dict,
    alice_token: str,
) -> None:
    """F9 — alice attempts to delete bob's account; 403 returned."""
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    _fastapi_app.dependency_overrides[get_current_user] = lambda: seeded_alice
    try:
        response = await async_client.delete(
            _ENDPOINT.format(username="bob"),
            headers={"Authorization": f"Bearer {alice_token}"},
        )
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 403
    assert response.json() == {"error": {"code": "forbidden", "message": ""}}


# ── F8: missing token → 401 ───────────────────────────────────────────────────


async def test_delete_user_returns_401_without_token(
    async_client: AsyncClient,
) -> None:
    """F8 — no Authorization header; 401 returned."""
    response = await async_client.delete(_ENDPOINT.format(username="alice"))
    assert response.status_code == 401
