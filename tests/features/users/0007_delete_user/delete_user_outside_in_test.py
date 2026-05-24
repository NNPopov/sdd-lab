# FEATURE: delete_user — outside-in acceptance test.
#
# Covers: F1, F7, F9, F10, F11, F12 (happy path) + F5, F6, F8, F14 (forbidden wrong owner).
# Red-state trigger: the current implementation uses /user/{username} (str) and
# get_by_username; calling /user/{id} (int) routes to the old handler as a string
# param, get_by_username("42") finds nothing, and the happy-path test fails with
# a 404 instead of the expected 200.
import pytest
from httpx import AsyncClient

pytestmark = pytest.mark.asyncio

_ENDPOINT = "/api/v1/user/{user_id}"


async def test_delete_user_happy_path(
    async_client: AsyncClient,
    seeded_alice: dict,
    alice_token: str,
) -> None:
    """Scenario 1 — owner deletes their own account by integer ID; row is soft-deleted and token is blacklisted."""
    from sqlalchemy import text

    from app.bootstrap.container import container as _di_container
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

    assert response.status_code == 200, response.text
    assert response.json() == {"message": "User deleted"}

    # DB assertion: user row must be soft-deleted.
    async with _di_container.session_factory()() as session:
        result = await session.execute(
            text('SELECT is_deleted, deleted_at FROM "user" WHERE username = :u'),
            {"u": "alice"},
        )
        row = result.first()
        assert row is not None, "alice row not found after delete"
        assert row.is_deleted is True
        assert row.deleted_at is not None

    # DB assertion: access token must appear in the blacklist.
    async with _di_container.session_factory()() as session:
        result = await session.execute(
            text("SELECT token FROM token_blacklist WHERE token = :t"),
            {"t": alice_token},
        )
        bl_row = result.first()
        assert bl_row is not None, "access token not found in token_blacklist after delete"


async def test_delete_user_forbidden_wrong_owner(
    async_client: AsyncClient,
    seeded_alice: dict,
    seeded_bob: dict,
    alice_token: str,
) -> None:
    """Scenario 2 — alice attempts to delete bob's account by bob's integer ID; must receive 403."""
    from sqlalchemy import text

    from app.bootstrap.container import container as _di_container
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

    assert response.status_code == 403, response.text
    assert response.json() == {"error": {"code": "forbidden", "message": ""}}

    # DB assertion: bob's row must be unchanged (not soft-deleted).
    async with _di_container.session_factory()() as session:
        result = await session.execute(
            text('SELECT is_deleted FROM "user" WHERE username = :u'),
            {"u": "bob"},
        )
        row = result.first()
        assert row is not None, "bob row not found"
        assert row.is_deleted is False

    # DB assertion: no blacklist entry was created (forbidden raised before blacklisting).
    async with _di_container.session_factory()() as session:
        result = await session.execute(
            text("SELECT token FROM token_blacklist WHERE token = :t"),
            {"t": alice_token},
        )
        bl_row = result.first()
        assert bl_row is None, "token was wrongly blacklisted on a forbidden request"
