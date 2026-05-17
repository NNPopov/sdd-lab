# FEATURE: assign_moderator — endpoint integration tests.
#
# Covers: F1, F13, F14, F15, F16, F18, F19.
import pytest
from httpx import AsyncClient

pytestmark = pytest.mark.asyncio

_ENDPOINT = "/api/v1/user/{username}/assign-moderator"


# ── F15: no token → 401 ───────────────────────────────────────────────────────


async def test_assign_moderator_returns_401_without_token(
    async_client: AsyncClient,
) -> None:
    """F15 — missing Authorization header; 401 returned."""
    response = await async_client.patch(_ENDPOINT.format(username="anyone"))
    assert response.status_code == 401


# ── F16: non-superuser → 403 ──────────────────────────────────────────────────


async def test_assign_moderator_returns_403_for_non_superuser(
    async_client: AsyncClient,
    seeded_target_user: dict,
) -> None:
    """F16 — authenticated user is not a superuser; 403 returned."""
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    regular_user = {**seeded_target_user, "is_superuser": False}
    _fastapi_app.dependency_overrides[get_current_user] = lambda: regular_user
    try:
        response = await async_client.patch(_ENDPOINT.format(username=seeded_target_user["username"]))
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 403


# ── F18: user not found → 404 ─────────────────────────────────────────────────


async def test_assign_moderator_returns_404_for_unknown_username(
    async_client: AsyncClient,
    seeded_superuser: dict,
) -> None:
    """F18 — target username does not exist; 404 returned."""
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    _fastapi_app.dependency_overrides[get_current_user] = lambda: seeded_superuser
    try:
        response = await async_client.patch(_ENDPOINT.format(username="ghost_xyz_99"))
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 404
    body = response.json()
    assert body["error"]["code"] == "notfound"
    assert body["error"]["message"] == "User not found"


# ── F19: already moderator → 409 ──────────────────────────────────────────────


async def test_assign_moderator_returns_409_when_already_moderator(
    async_client: AsyncClient,
    seeded_target_user: dict,
    seeded_superuser: dict,
) -> None:
    """F19 — target is already a moderator; 409 returned."""
    from sqlalchemy import update as sa_update

    from app.adapters.db.models.user import User
    from app.bootstrap.container import container as _di_container
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    async with _di_container.session_factory()() as session:
        await session.execute(
            sa_update(User)
            .where(User.username == seeded_target_user["username"])
            .values(is_moderator=True, moderator_granted_by_user_id=seeded_superuser["id"])
        )
        await session.commit()

    _fastapi_app.dependency_overrides[get_current_user] = lambda: seeded_superuser
    try:
        response = await async_client.patch(_ENDPOINT.format(username=seeded_target_user["username"]))
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 409
    assert response.json()["error"]["message"] == "User is already a moderator"


# ── F1, F13, F14: happy path → 200 ───────────────────────────────────────────


async def test_assign_moderator_returns_200_on_success(
    async_client: AsyncClient,
    seeded_target_user: dict,
    seeded_superuser: dict,
) -> None:
    """F1, F13, F14 — superuser promotes target; 200 with is_moderator=true."""
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    _fastapi_app.dependency_overrides[get_current_user] = lambda: seeded_superuser
    try:
        response = await async_client.patch(_ENDPOINT.format(username=seeded_target_user["username"]))
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 200
    body = response.json()
    assert body["is_moderator"] is True
    assert body["username"] == seeded_target_user["username"]
    assert "id" in body
    assert "name" in body
    assert "email" in body
    assert "profile_image_url" in body
    assert "tier_id" in body
    assert "moderator_granted_by_user_id" not in body
