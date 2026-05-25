# FEATURE: rate_limits_route_to_user_id — endpoint integration tests.
#
# httpx.AsyncClient against the test Postgres (savepoint rollback per test).
# Auth identity is supplied by overriding get_current_user; the route's
# Depends(get_current_superuser) then passes for a superuser dict and 403s for
# a non-superuser dict. Fixtures (async_client, seeded_superuser,
# seeded_user_with_tier) come from the slice conftest.py.
#
# Covers: F1, F2 (empty), F7, F8, F9, F10.
import pytest
from httpx import AsyncClient

pytestmark = pytest.mark.asyncio

_ENDPOINT = "/api/v1/user/{user_id}/rate_limits"


# ── F7: no token → 401 ────────────────────────────────────────────────────────


async def test_returns_401_without_token(async_client: AsyncClient) -> None:
    """F7 — missing Authorization header; 401 returned by get_current_superuser."""
    response = await async_client.get(_ENDPOINT.format(user_id=1))
    assert response.status_code == 401


# ── F8: authenticated non-superuser → 403 ─────────────────────────────────────


async def test_returns_403_for_non_superuser(
    async_client: AsyncClient,
    seeded_user_with_tier: dict,
    seeded_superuser: dict,
) -> None:
    """F8 — authenticated user is not a superuser; 403 returned."""
    from app.main import app as _fastapi_app
    from app.shared_dependencies import get_current_user

    regular_user = {**seeded_superuser, "is_superuser": False}
    _fastapi_app.dependency_overrides[get_current_user] = lambda: regular_user
    try:
        response = await async_client.get(_ENDPOINT.format(user_id=seeded_user_with_tier["id"]))
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
        response = await async_client.get("/api/v1/user/abc/rate_limits")
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 422


# ── F9: unknown user_id → 404 ─────────────────────────────────────────────────


async def test_returns_404_for_unknown_user_id(
    async_client: AsyncClient,
    seeded_superuser: dict,
) -> None:
    """F9 — user_id matches no user; 404 with the domain error body."""
    from app.main import app as _fastapi_app
    from app.shared_dependencies import get_current_user

    _fastapi_app.dependency_overrides[get_current_user] = lambda: seeded_superuser
    try:
        response = await async_client.get(_ENDPOINT.format(user_id=999999))
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 404
    assert response.json() == {"error": {"code": "notfound", "message": "User not found"}}


# ── F2: user with no tier → 200 with empty rate limits ────────────────────────


async def test_returns_200_with_empty_rate_limits_when_no_tier(
    async_client: AsyncClient,
    seeded_superuser: dict,
) -> None:
    """F2 — user exists but tier_id is None; 200 with tier_rate_limits == []."""
    from app.adapters.db.models.user import User
    from app.bootstrap.container import container as _di_container
    from app.main import app as _fastapi_app
    from app.shared_dependencies import get_current_user

    async with _di_container.session_factory()() as session:
        user = User(
            name="RL No Tier",
            username="rl049notier",
            email="rl049notier@example.com",
            hashed_password="fake_hashed_password",
            profile_image_url="https://www.profileimageurl.com",
        )
        session.add(user)
        await session.commit()
        await session.refresh(user)
        no_tier_id = user.id

    _fastapi_app.dependency_overrides[get_current_user] = lambda: seeded_superuser
    try:
        response = await async_client.get(_ENDPOINT.format(user_id=no_tier_id))
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 200, response.text
    body = response.json()
    assert body["id"] == no_tier_id
    assert body["tier_id"] is None
    assert body["tier_rate_limits"] == []


# ── F1: user with a tier → 200 with populated rate limits ─────────────────────


async def test_returns_200_with_rate_limits_for_user_with_tier(
    async_client: AsyncClient,
    seeded_user_with_tier: dict,
    seeded_superuser: dict,
) -> None:
    """F1 — superuser reads a user's rate limits by id; 200 with populated list."""
    from app.main import app as _fastapi_app
    from app.shared_dependencies import get_current_user

    target_id = seeded_user_with_tier["id"]
    _fastapi_app.dependency_overrides[get_current_user] = lambda: seeded_superuser
    try:
        response = await async_client.get(_ENDPOINT.format(user_id=target_id))
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 200, response.text
    body = response.json()
    assert body["id"] == target_id
    assert body["tier_id"] == seeded_user_with_tier["tier_id"]
    assert body["username"] == seeded_user_with_tier["username"]
    assert isinstance(body["tier_rate_limits"], list)
    names = {entry["name"] for entry in body["tier_rate_limits"]}
    assert seeded_user_with_tier["rate_limit_name"] in names
