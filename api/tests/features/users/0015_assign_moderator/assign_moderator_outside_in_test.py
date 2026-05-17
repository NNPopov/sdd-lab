# FEATURE: assign_moderator — outside-in acceptance test.
#
# Covers: F1, F7, F9, F10, F11, F12, F13, F14 (scenario 1 — happy path)
#         F6, F19 (scenario 2 — already moderator → 409)
# Red-state trigger: PATCH /api/v1/user/{username}/assign-moderator route does
# not yet exist → requests return 404 and the status assertions fail.
import pytest
from httpx import AsyncClient
from sqlalchemy import update as sa_update

pytestmark = pytest.mark.asyncio

_ASSIGN_ENDPOINT = "/api/v1/user/{username}/assign-moderator"
_GET_BY_USERNAME = "/api/v1/user/{username}"
_TARGET_USERNAME = "targetmod"


async def test_assign_moderator_happy_path(
    async_client: AsyncClient,
    seeded_target_user: dict,
    seeded_superuser: dict,
) -> None:
    """Scenario 1 — superuser assigns moderator; response and DB state both updated."""
    from sqlalchemy import text

    from app.bootstrap.container import container as _di_container
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    superuser_dict = seeded_superuser  # real DB row, id is valid for FK

    _fastapi_app.dependency_overrides[get_current_user] = lambda: superuser_dict
    try:
        response = await async_client.patch(
            _ASSIGN_ENDPOINT.format(username=_TARGET_USERNAME),
        )
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 200, response.text
    body = response.json()
    assert body["is_moderator"] is True
    assert body["username"] == _TARGET_USERNAME
    assert "id" in body
    assert "name" in body
    assert "email" in body
    assert "profile_image_url" in body
    assert "tier_id" in body
    assert "moderator_granted_by_user_id" not in body

    # DB assertions: both columns written correctly.
    async with _di_container.session_factory()() as session:
        result = await session.execute(
            text('SELECT is_moderator, moderator_granted_by_user_id FROM "user" WHERE username = :u'),
            {"u": _TARGET_USERNAME},
        )
        row = result.first()
        assert row is not None
        assert row.is_moderator is True
        assert row.moderator_granted_by_user_id == seeded_superuser["id"]

    # Read-path confirmation: GET /user/{username} reflects the new state.
    read_response = await async_client.get(_GET_BY_USERNAME.format(username=_TARGET_USERNAME))
    assert read_response.status_code == 200, read_response.text
    assert read_response.json()["is_moderator"] is True


async def test_assign_moderator_already_moderator_returns_409(
    async_client: AsyncClient,
    seeded_target_user: dict,
    seeded_superuser: dict,
) -> None:
    """Scenario 2 — target is already a moderator; returns 409 and DB is unchanged."""
    from sqlalchemy import text

    from app.adapters.db.models.user import User
    from app.bootstrap.container import container as _di_container
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    # Promote target_user directly in the test transaction to simulate prior assignment.
    async with _di_container.session_factory()() as session:
        await session.execute(
            sa_update(User)
            .where(User.username == _TARGET_USERNAME)
            .values(
                is_moderator=True,
                moderator_granted_by_user_id=seeded_superuser["id"],
            )
        )
        await session.commit()

    superuser_dict = seeded_superuser
    _fastapi_app.dependency_overrides[get_current_user] = lambda: superuser_dict
    try:
        response = await async_client.patch(
            _ASSIGN_ENDPOINT.format(username=_TARGET_USERNAME),
        )
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 409, response.text
    assert response.json()["error"]["message"] == "User is already a moderator"

    # DB assertion: state is unchanged from before the failed call.
    async with _di_container.session_factory()() as session:
        result = await session.execute(
            text('SELECT is_moderator, moderator_granted_by_user_id FROM "user" WHERE username = :u'),
            {"u": _TARGET_USERNAME},
        )
        row = result.first()
        assert row is not None
        assert row.is_moderator is True
        assert row.moderator_granted_by_user_id == seeded_superuser["id"]
