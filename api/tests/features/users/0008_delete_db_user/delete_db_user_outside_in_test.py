# FEATURE: delete_db_user — outside-in acceptance test.
#
# Covers: F1, F3, F5 (happy path) + F6, F10 (FK violation → 409).
# Red-state trigger: the old erase_db_user implementation uses async_get_db
# directly (bypasses the container session_factory override) and therefore
# cannot see users seeded in the test transaction → returns 404 instead of
# the expected 200 / 409. Once the new DeleteDbUserUseCase / DeleteDbUserAdapter
# slice replaces it, the container-scoped session sees the seeded data and
# the tests turn green.
import pytest
from httpx import AsyncClient

pytestmark = pytest.mark.asyncio

_ENDPOINT = "/api/v1/db_user/{username}"

# Superuser identity injected via dependency_overrides on get_current_user.
_SUPERUSER = {
    "id": 9999,
    "username": "admin",
    "email": "admin@example.com",
    "name": "Admin",
    "is_superuser": True,
}


async def test_delete_db_user_happy_path(
    async_client: AsyncClient,
    seeded_alice: dict,
) -> None:
    """Scenario 1 — superuser permanently deletes alice; row is gone from DB."""
    from sqlalchemy import text

    from app.bootstrap.container import container as _di_container
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

    assert response.status_code == 200, response.text
    assert response.json() == {"message": "User deleted from the database"}

    # DB assertion: alice row must no longer exist.
    async with _di_container.session_factory()() as session:
        result = await session.execute(
            text('SELECT id FROM "user" WHERE username = :u'),
            {"u": "alice"},
        )
        row = result.first()
        assert row is None, "alice row still exists after hard delete"


async def test_delete_db_user_fk_violation(
    async_client: AsyncClient,
    seeded_alice_with_post: dict,
) -> None:
    """Scenario 2 — alice has a dependent post; DELETE returns 409; row is unchanged."""
    from sqlalchemy import text

    from app.bootstrap.container import container as _di_container
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

    assert response.status_code == 409, response.text
    body = response.json()
    assert body["error"]["code"] == "duplicatevalue"
    assert "dependent" in body["error"]["message"].lower()

    # DB assertion: alice row must still exist (delete was rejected).
    async with _di_container.session_factory()() as session:
        result = await session.execute(
            text('SELECT id FROM "user" WHERE username = :u'),
            {"u": "alice"},
        )
        row = result.first()
        assert row is not None, "alice row was wrongly deleted despite FK violation"
