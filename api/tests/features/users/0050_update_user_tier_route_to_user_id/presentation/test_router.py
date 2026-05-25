# FEATURE: update_user_tier_route_to_user_id — endpoint integration tests.
#
# httpx.AsyncClient against the test Postgres (savepoint rollback per test).
# Auth identity is supplied by overriding get_current_user; the route's
# Depends(get_current_superuser) then passes for a superuser dict and 403s for
# a non-superuser dict. Fixtures (async_client, seeded_superuser,
# seeded_user_and_tier) come from the slice conftest.py.
#
# Covers: F1, F4, F5, F7, F8, F9, F10.
import pytest
from httpx import AsyncClient

pytestmark = pytest.mark.asyncio

_ENDPOINT = "/api/v1/user/{user_id}/tier"


# ── F7: no token → 401 ────────────────────────────────────────────────────────


async def test_returns_401_without_token(async_client: AsyncClient) -> None:
    """F7 — missing Authorization header; 401 returned by get_current_superuser."""
    response = await async_client.patch(_ENDPOINT.format(user_id=1), json={"tier_id": 1})
    assert response.status_code == 401


# ── F8: authenticated non-superuser → 403 ─────────────────────────────────────


async def test_returns_403_for_non_superuser(
    async_client: AsyncClient,
    seeded_user_and_tier: dict,
    seeded_superuser: dict,
) -> None:
    """F8 — authenticated user is not a superuser; 403 returned."""
    from app.main import app as _fastapi_app
    from app.shared_dependencies import get_current_user

    regular_user = {**seeded_superuser, "is_superuser": False}
    _fastapi_app.dependency_overrides[get_current_user] = lambda: regular_user
    try:
        response = await async_client.patch(
            _ENDPOINT.format(user_id=seeded_user_and_tier["id"]),
            json={"tier_id": seeded_user_and_tier["tier_id"]},
        )
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 403


# ── F10: non-integer path param → 422 ─────────────────────────────────────────


async def test_returns_422_for_non_integer_user_id(
    async_client: AsyncClient,
    seeded_superuser: dict,
) -> None:
    """F10 — non-integer user_id path param; 422 from FastAPI path coercion."""
    from app.main import app as _fastapi_app
    from app.shared_dependencies import get_current_user

    _fastapi_app.dependency_overrides[get_current_user] = lambda: seeded_superuser
    try:
        response = await async_client.patch("/api/v1/user/abc/tier", json={"tier_id": 1})
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 422


# ── F4/F9: unknown user_id → 404 ──────────────────────────────────────────────


async def test_returns_404_for_unknown_user_id(
    async_client: AsyncClient,
    seeded_user_and_tier: dict,
    seeded_superuser: dict,
) -> None:
    """F4, F9 — user_id matches no user; 404 with the domain error body."""
    from app.main import app as _fastapi_app
    from app.shared_dependencies import get_current_user

    _fastapi_app.dependency_overrides[get_current_user] = lambda: seeded_superuser
    try:
        response = await async_client.patch(
            _ENDPOINT.format(user_id=999999),
            json={"tier_id": seeded_user_and_tier["tier_id"]},
        )
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 404
    assert response.json() == {"error": {"code": "notfound", "message": "User not found"}}


# ── F5/F9: existing user, unknown tier_id → 404 ───────────────────────────────


async def test_returns_404_for_unknown_tier_id(
    async_client: AsyncClient,
    seeded_user_and_tier: dict,
    seeded_superuser: dict,
) -> None:
    """F5, F9 — user exists but tier_id matches no tier; 404 with the domain error body."""
    from app.main import app as _fastapi_app
    from app.shared_dependencies import get_current_user

    _fastapi_app.dependency_overrides[get_current_user] = lambda: seeded_superuser
    try:
        response = await async_client.patch(
            _ENDPOINT.format(user_id=seeded_user_and_tier["id"]),
            json={"tier_id": 999999},
        )
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 404
    assert response.json() == {"error": {"code": "notfound", "message": "Tier not found"}}


# ── F1: superuser updates a user's tier by id → 200 ───────────────────────────


async def test_returns_200_and_updates_tier(
    async_client: AsyncClient,
    seeded_user_and_tier: dict,
    seeded_superuser: dict,
) -> None:
    """F1 — superuser updates a user's tier by id; 200 with the success message."""
    from app.main import app as _fastapi_app
    from app.shared_dependencies import get_current_user

    target_id = seeded_user_and_tier["id"]
    _fastapi_app.dependency_overrides[get_current_user] = lambda: seeded_superuser
    try:
        response = await async_client.patch(
            _ENDPOINT.format(user_id=target_id),
            json={"tier_id": seeded_user_and_tier["tier_id"]},
        )
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 200, response.text
    assert response.json() == {"message": f"User {seeded_user_and_tier['name']} Tier updated"}
