# FEATURE: assign_moderator — endpoint integration tests.
#
# Covers: F1, F2, F3, F4, F7, F8, F12, F13, F14.
import pytest
from httpx import AsyncClient

pytestmark = pytest.mark.asyncio

_ENDPOINT = "/api/v1/user/{user_id}/assign-moderator"


# ── F3: no token → 401 ────────────────────────────────────────────────────────


async def test_assign_moderator_returns_401_without_token(
    async_client: AsyncClient,
    seeded_target_user: dict,
) -> None:
    """F3 — missing Authorization header; 401 returned."""
    response = await async_client.patch(_ENDPOINT.format(user_id=seeded_target_user["id"]))
    assert response.status_code == 401


# ── F2: non-integer path param → 422 ──────────────────────────────────────────


async def test_assign_moderator_returns_422_for_non_integer_user_id(
    async_client: AsyncClient,
    seeded_superuser: dict,
) -> None:
    """F2 — non-integer path param; FastAPI rejects with 422."""
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    _fastapi_app.dependency_overrides[get_current_user] = lambda: seeded_superuser
    try:
        response = await async_client.patch("/api/v1/user/not-an-int/assign-moderator")
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 422


# ── F4, F14: non-superuser → 403 ──────────────────────────────────────────────


async def test_assign_moderator_returns_403_for_non_superuser(
    async_client: AsyncClient,
    seeded_target_user: dict,
) -> None:
    """F4, F14 — authenticated user is not a superuser; 403 returned."""
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    regular_user = {**seeded_target_user, "is_superuser": False}
    _fastapi_app.dependency_overrides[get_current_user] = lambda: regular_user
    try:
        response = await async_client.patch(_ENDPOINT.format(user_id=seeded_target_user["id"]))
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 403


# ── F7, F12: user not found → 404 ─────────────────────────────────────────────


async def test_assign_moderator_returns_404_for_unknown_user_id(
    async_client: AsyncClient,
    seeded_superuser: dict,
) -> None:
    """F7, F12 — target user_id does not exist; 404 returned."""
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


# ── F8, F13: already moderator → 409 ──────────────────────────────────────────


async def test_assign_moderator_returns_409_when_already_moderator(
    async_client: AsyncClient,
    seeded_target_user: dict,
    seeded_superuser: dict,
) -> None:
    """F8, F13 — target is already a moderator; 409 returned."""
    from sqlalchemy import update as sa_update

    from app.adapters.db.models.user import User
    from app.bootstrap.container import container as _di_container
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    async with _di_container.session_factory()() as session:
        await session.execute(
            sa_update(User)
            .where(User.id == seeded_target_user["id"])
            .values(is_moderator=True, moderator_granted_by_user_id=seeded_superuser["id"])
        )
        await session.commit()

    _fastapi_app.dependency_overrides[get_current_user] = lambda: seeded_superuser
    try:
        response = await async_client.patch(_ENDPOINT.format(user_id=seeded_target_user["id"]))
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 409
    assert response.json()["error"]["message"] == "User is already a moderator"


# ── F1: happy path → 200 ──────────────────────────────────────────────────────


async def test_assign_moderator_returns_200_on_success(
    async_client: AsyncClient,
    seeded_target_user: dict,
    seeded_superuser: dict,
) -> None:
    """F1 — superuser promotes target by integer id; 200 with is_moderator=true."""
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    _fastapi_app.dependency_overrides[get_current_user] = lambda: seeded_superuser
    try:
        response = await async_client.patch(_ENDPOINT.format(user_id=seeded_target_user["id"]))
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 200
    body = response.json()
    assert body["id"] == seeded_target_user["id"]
    assert body["is_moderator"] is True
    assert body["username"] == seeded_target_user["username"]
    assert "name" in body
    assert "email" in body
    assert "profile_image_url" in body
    assert "tier_id" in body
    assert "moderator_granted_by_user_id" not in body
