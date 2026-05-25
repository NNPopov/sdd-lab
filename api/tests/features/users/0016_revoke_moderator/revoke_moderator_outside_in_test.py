# FEATURE: revoke_moderator — outside-in acceptance test.
#
# Migration slice 0047: route migrated from {username} to {user_id}.
# Covers (per 0047 tests.md):
#   F1, F5, F6, F7, F9, F10, F11 (scenario 1 — happy path)
#   F8, F13                      (scenario 2 — not a moderator → 409)
# Red-state trigger: the pre-migration route is /api/v1/users/{username}/...,
# so a request carrying an integer id binds username to the id's string form,
# get_by_username finds nothing, and the call returns 404 — scenario 1's 200
# assertion fails RED until the route is migrated to {user_id} and the lookup
# uses get_by_id.
import pytest
from httpx import AsyncClient
from sqlalchemy import text

pytestmark = pytest.mark.asyncio

_REVOKE_ENDPOINT = "/api/v1/users/{user_id}/revoke-moderator"
_GET_BY_ID = "/api/v1/user/{user_id}"


async def test_revoke_moderator_happy_path(
    async_client: AsyncClient,
    seeded_moderator_user: dict,
    seeded_superuser: dict,
) -> None:
    """Scenario 1 — superuser revokes moderator by integer id; response and DB both updated."""
    from app.bootstrap.container import container as _di_container
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    superuser_dict = seeded_superuser
    target_id = seeded_moderator_user["id"]

    _fastapi_app.dependency_overrides[get_current_user] = lambda: superuser_dict
    try:
        response = await async_client.patch(
            _REVOKE_ENDPOINT.format(user_id=target_id),
        )
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 200, response.text
    body = response.json()
    assert body["id"] == target_id
    assert body["is_moderator"] is False
    assert body["username"] == seeded_moderator_user["username"]
    assert "name" in body
    assert "email" in body
    assert "profile_image_url" in body
    assert "tier_id" in body
    assert "moderator_granted_by_user_id" not in body

    # DB assertions: both columns cleared correctly.
    async with _di_container.session_factory()() as session:
        result = await session.execute(
            text('SELECT is_moderator, moderator_granted_by_user_id FROM "user" WHERE id = :i'),
            {"i": target_id},
        )
        row = result.first()
        assert row is not None
        assert row.is_moderator is False
        assert row.moderator_granted_by_user_id is None

    # Read-path confirmation: GET /user/{id} reflects the revoked state.
    read_response = await async_client.get(_GET_BY_ID.format(user_id=target_id))
    assert read_response.status_code == 200, read_response.text
    assert read_response.json()["is_moderator"] is False


async def test_revoke_moderator_not_a_moderator_returns_409(
    async_client: AsyncClient,
    seeded_regular_user: dict,
    seeded_superuser: dict,
) -> None:
    """Scenario 2 — target is not a moderator; returns 409 and DB is unchanged."""
    from app.bootstrap.container import container as _di_container
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    superuser_dict = seeded_superuser
    target_id = seeded_regular_user["id"]

    _fastapi_app.dependency_overrides[get_current_user] = lambda: superuser_dict
    try:
        response = await async_client.patch(
            _REVOKE_ENDPOINT.format(user_id=target_id),
        )
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 409, response.text
    assert response.json()["error"]["message"] == "User is not a moderator"

    # DB assertion: state is unchanged — is_moderator is still False.
    async with _di_container.session_factory()() as session:
        result = await session.execute(
            text('SELECT is_moderator, moderator_granted_by_user_id FROM "user" WHERE id = :i'),
            {"i": target_id},
        )
        row = result.first()
        assert row is not None
        assert row.is_moderator is False
        assert row.moderator_granted_by_user_id is None
