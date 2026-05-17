# FEATURE: expose_moderator_flag — endpoint integration tests.
#
# Covers: F3, F4, F5, F6, F7, F8, F9, F10, F12 (see requirements.md).
# Uses async_client + seeded_alice from 0014_expose_moderator_flag/conftest.py
# (real Postgres via savepoint rollback).
import pytest
from httpx import AsyncClient
from sqlalchemy import update as sa_update

pytestmark = pytest.mark.asyncio

_GET_BY_USERNAME = "/api/v1/user/{username}"
_GET_ME = "/api/v1/user/me/"
_USERNAME = "alicetester"


# ── GET /user/{username} ──────────────────────────────────────────────────────


async def test_get_by_username_non_moderator_returns_false(
    async_client: AsyncClient,
    seeded_alice: dict,
) -> None:
    """F5, F7, F12: public endpoint returns is_moderator=false for default user."""
    response = await async_client.get(_GET_BY_USERNAME.format(username=_USERNAME))

    assert response.status_code == 200, response.text
    body = response.json()
    assert "is_moderator" in body
    assert body["is_moderator"] is False


async def test_get_by_username_moderator_returns_true(
    async_client: AsyncClient,
    seeded_alice: dict,
) -> None:
    """F6, F7: public endpoint returns is_moderator=true after DB flag is set."""
    from app.adapters.db.models.user import User
    from app.bootstrap.container import container as _di_container

    async with _di_container.session_factory()() as session:
        await session.execute(sa_update(User).where(User.username == _USERNAME).values(is_moderator=True))
        await session.commit()

    response = await async_client.get(_GET_BY_USERNAME.format(username=_USERNAME))

    assert response.status_code == 200, response.text
    body = response.json()
    assert "is_moderator" in body
    assert body["is_moderator"] is True


# ── GET /user/me/ ─────────────────────────────────────────────────────────────


async def test_get_me_non_moderator_returns_false(
    async_client: AsyncClient,
    seeded_alice: dict,
) -> None:
    """F9, F12: authenticated endpoint returns is_moderator=false for default user."""
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    _fastapi_app.dependency_overrides[get_current_user] = lambda: seeded_alice
    try:
        response = await async_client.get(_GET_ME)

        assert response.status_code == 200, response.text
        body = response.json()
        assert "is_moderator" in body
        assert body["is_moderator"] is False
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]


async def test_get_me_moderator_returns_true(
    async_client: AsyncClient,
    seeded_alice: dict,
) -> None:
    """F10: authenticated endpoint returns is_moderator=true when flag is set."""
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    moderator_alice = {**seeded_alice, "is_moderator": True}
    _fastapi_app.dependency_overrides[get_current_user] = lambda: moderator_alice
    try:
        response = await async_client.get(_GET_ME)

        assert response.status_code == 200, response.text
        body = response.json()
        assert "is_moderator" in body
        assert body["is_moderator"] is True
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]
