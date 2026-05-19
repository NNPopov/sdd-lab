# FEATURE: migrate_di_wiring — outside-in acceptance test.
#
# Verifies that Provide[Container.x] injections in slice routers and
# shared_dependencies.py resolve to actual instances (not the provider sentinel)
# and that observable HTTP behaviour is preserved end-to-end.
#
# Covers: F1, F4, F5, F6, F8, F9, F10, F13.
import pytest
from httpx import AsyncClient
from sqlalchemy import text

pytestmark = pytest.mark.asyncio

_USER_ENDPOINT = "/api/v1/user"
_LOGIN_ENDPOINT = "/api/v1/login"
_ME_ENDPOINT = "/api/v1/user/me/"


async def test_basic_router_wiring_create_user(
    async_client: AsyncClient,
    oit_db_session: object,
) -> None:
    """Scenario 1 — Category A: Provide[Container.create_user_use_case] resolves to the use-case instance."""
    response = await async_client.post(
        _USER_ENDPOINT,
        json={
            "name": "Wiring Tester",
            "username": "wiringtester",
            "email": "wiring@example.com",
            "password": "Pa$$w0rd1",
        },
    )

    assert response.status_code == 201, response.text
    body = response.json()
    assert isinstance(body["id"], int)
    assert body["username"] == "wiringtester"
    assert body["email"] == "wiring@example.com"

    result = await oit_db_session.execute(  # type: ignore[union-attr]
        text('SELECT username FROM "user" WHERE username = :u'),
        {"u": "wiringtester"},
    )
    row = result.first()
    assert row is not None, "user row not found after creation"


async def test_shared_dependencies_wiring_authenticated_request(
    async_client: AsyncClient,
    oit_db_session: object,
) -> None:
    """Scenario 2 — Category B: Provide[Container.token_blacklist_adapter] in get_current_user resolves correctly."""
    resp = await async_client.post(
        _USER_ENDPOINT,
        json={
            "name": "Wiring Tester 2",
            "username": "wiringtester2",
            "email": "wiring2@example.com",
            "password": "Pa$$w0rd2",
        },
    )
    assert resp.status_code == 201, resp.text

    resp = await async_client.post(
        _LOGIN_ENDPOINT,
        data={"username": "wiring2@example.com", "password": "Pa$$w0rd2"},
    )
    assert resp.status_code == 200, resp.text
    access_token = resp.json()["access_token"]

    resp = await async_client.get(
        _ME_ENDPOINT,
        headers={"Authorization": f"Bearer {access_token}"},
    )

    assert resp.status_code == 200, resp.text
    body = resp.json()
    assert body["username"] == "wiringtester2"
    assert body["is_superuser"] is False

    result = await oit_db_session.execute(  # type: ignore[union-attr]
        text("SELECT EXISTS (SELECT 1 FROM token_blacklist WHERE token = :token)"),
        {"token": access_token},
    )
    assert result.scalar() is False, "token was unexpectedly blacklisted"
