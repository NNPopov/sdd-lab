# FEATURE: delete_db_user — endpoint integration tests.
#
# Covers: F1, F7, F8, F9, F10.
import pytest
from httpx import AsyncClient

pytestmark = pytest.mark.asyncio

_ENDPOINT = "/api/v1/db_user/{username}"

_SUPERUSER = {
    "id": 9999,
    "username": "admin",
    "email": "admin@example.com",
    "name": "Admin",
    "is_superuser": True,
}

_REGULAR_USER = {
    "id": 8888,
    "username": "regularuser",
    "email": "regular@example.com",
    "name": "Regular",
    "is_superuser": False,
}


# ── F1: happy path — active user deleted → 200 ───────────────────────────────


async def test_delete_db_user_returns_200_on_success(
    async_client: AsyncClient,
    seeded_alice: dict,
) -> None:
    """F1 — superuser hard-deletes alice; 200 and confirmation message."""
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    _fastapi_app.dependency_overrides[get_current_user] = lambda: _SUPERUSER
    try:
        response = await async_client.delete(
            _ENDPOINT.format(username="alice"),
            headers={"Authorization": "Bearer fake-token"},
        )
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 200
    assert response.json() == {"message": "User deleted from the database"}


# ── F1: soft-deleted user also deleted → 200 ─────────────────────────────────


async def test_delete_db_user_returns_200_for_soft_deleted_user(
    async_client: AsyncClient,
) -> None:
    """F1, F4 — superuser hard-deletes a soft-deleted alice; 200 returned."""
    from app.adapters.db.models.user import User
    from app.bootstrap.container import container as _di_container
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    async with _di_container.session_factory()() as session:
        user = User(
            name="Alice Tester",
            username="alice",
            email="alice@example.com",
            hashed_password="fake_hashed_password",
            profile_image_url="https://www.profileimageurl.com",
            is_deleted=True,
        )
        session.add(user)
        await session.commit()

    _fastapi_app.dependency_overrides[get_current_user] = lambda: _SUPERUSER
    try:
        response = await async_client.delete(
            _ENDPOINT.format(username="alice"),
            headers={"Authorization": "Bearer fake-token"},
        )
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 200
    assert response.json() == {"message": "User deleted from the database"}


# ── F9: not found → 404 ───────────────────────────────────────────────────────


async def test_delete_db_user_returns_404_for_unknown_username(
    async_client: AsyncClient,
) -> None:
    """F9 — target username does not exist; 404 returned."""
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    _fastapi_app.dependency_overrides[get_current_user] = lambda: _SUPERUSER
    try:
        response = await async_client.delete(
            _ENDPOINT.format(username="ghost_xyz_99"),
            headers={"Authorization": "Bearer fake-token"},
        )
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 404
    body = response.json()
    assert body["error"]["code"] == "notfound"
    assert body["error"]["message"] == "User not found"


# ── F10: FK violation → 409 ───────────────────────────────────────────────────


async def test_delete_db_user_returns_409_when_user_has_dependent_records(
    async_client: AsyncClient,
    seeded_alice_with_post: dict,
) -> None:
    """F10 — alice has a dependent post; 409 returned."""
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    _fastapi_app.dependency_overrides[get_current_user] = lambda: _SUPERUSER
    try:
        response = await async_client.delete(
            _ENDPOINT.format(username="alice"),
            headers={"Authorization": "Bearer fake-token"},
        )
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 409
    body = response.json()
    assert body["error"]["code"] == "duplicatevalue"
    assert "dependent" in body["error"]["message"].lower()


# ── F8: non-superuser → 403 ───────────────────────────────────────────────────


async def test_delete_db_user_returns_403_for_regular_user(
    async_client: AsyncClient,
    seeded_alice: dict,
) -> None:
    """F8 — regular (non-superuser) user; 403 returned."""
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    _fastapi_app.dependency_overrides[get_current_user] = lambda: _REGULAR_USER
    try:
        response = await async_client.delete(
            _ENDPOINT.format(username="alice"),
            headers={"Authorization": "Bearer fake-token"},
        )
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 403


# ── F7: missing token → 401 ───────────────────────────────────────────────────


async def test_delete_db_user_returns_401_without_token(
    async_client: AsyncClient,
) -> None:
    """F7 — no Authorization header; 401 returned."""
    response = await async_client.delete(_ENDPOINT.format(username="alice"))
    assert response.status_code == 401
