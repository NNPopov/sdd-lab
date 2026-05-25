# FEATURE: delete_db_user — endpoint integration tests.
#
# Covers: F1 (200), F2 (422), F3 (401), F4 (403), F12 (404), F13 (409).
import pytest
from httpx import AsyncClient

pytestmark = pytest.mark.asyncio

_ENDPOINT = "/api/v1/db_user/{user_id}"

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
    """F1 — superuser hard-deletes alice by id; 200 and confirmation message."""
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    _fastapi_app.dependency_overrides[get_current_user] = lambda: _SUPERUSER
    try:
        response = await async_client.delete(
            _ENDPOINT.format(user_id=seeded_alice["id"]),
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
    """F1 — superuser hard-deletes a soft-deleted alice by id; 200 returned."""
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
        await session.refresh(user)
        user_id = user.id

    _fastapi_app.dependency_overrides[get_current_user] = lambda: _SUPERUSER
    try:
        response = await async_client.delete(
            _ENDPOINT.format(user_id=user_id),
            headers={"Authorization": "Bearer fake-token"},
        )
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 200
    assert response.json() == {"message": "User deleted from the database"}


# ── F12: not found → 404 ──────────────────────────────────────────────────────


async def test_delete_db_user_returns_404_for_unknown_user_id(
    async_client: AsyncClient,
) -> None:
    """F12 — target user_id does not exist; 404 returned."""
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    _fastapi_app.dependency_overrides[get_current_user] = lambda: _SUPERUSER
    try:
        response = await async_client.delete(
            _ENDPOINT.format(user_id=999999),
            headers={"Authorization": "Bearer fake-token"},
        )
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 404
    body = response.json()
    assert body["error"]["code"] == "notfound"
    assert body["error"]["message"] == "User not found"


# ── F2: non-integer path param → 422 ──────────────────────────────────────────


async def test_delete_db_user_returns_422_for_non_integer_user_id(
    async_client: AsyncClient,
) -> None:
    """F2 — non-integer user_id is rejected by FastAPI path coercion; 422 returned."""
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    _fastapi_app.dependency_overrides[get_current_user] = lambda: _SUPERUSER
    try:
        response = await async_client.delete(
            _ENDPOINT.format(user_id="abc"),
            headers={"Authorization": "Bearer fake-token"},
        )
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 422


# ── F13: FK violation → 409 ───────────────────────────────────────────────────


async def test_delete_db_user_returns_409_when_user_has_dependent_records(
    async_client: AsyncClient,
    seeded_alice_with_post: dict,
) -> None:
    """F13 — alice has a dependent post; 409 returned."""
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    _fastapi_app.dependency_overrides[get_current_user] = lambda: _SUPERUSER
    try:
        response = await async_client.delete(
            _ENDPOINT.format(user_id=seeded_alice_with_post["id"]),
            headers={"Authorization": "Bearer fake-token"},
        )
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 409
    body = response.json()
    assert body["error"]["code"] == "duplicatevalue"
    assert "dependent" in body["error"]["message"].lower()


# ── F4: non-superuser → 403 ───────────────────────────────────────────────────


async def test_delete_db_user_returns_403_for_regular_user(
    async_client: AsyncClient,
    seeded_alice: dict,
) -> None:
    """F4 — regular (non-superuser) user; 403 returned."""
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    _fastapi_app.dependency_overrides[get_current_user] = lambda: _REGULAR_USER
    try:
        response = await async_client.delete(
            _ENDPOINT.format(user_id=seeded_alice["id"]),
            headers={"Authorization": "Bearer fake-token"},
        )
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 403


# ── F3: missing token → 401 ───────────────────────────────────────────────────


async def test_delete_db_user_returns_401_without_token(
    async_client: AsyncClient,
) -> None:
    """F3 — no Authorization header; 401 returned."""
    response = await async_client.delete(_ENDPOINT.format(user_id=1))
    assert response.status_code == 401
