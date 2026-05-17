# FEATURE: expose_moderator_flag — outside-in acceptance test.
#
# Covers: F5, F6, F7, F8, F9, F10, F12 (see requirements.md).
# Red-state trigger: FoundUser entity, GetUserByUsernameResponse, and UserMeRead
# do not yet carry is_moderator — assertions on that key raise KeyError.
import pytest
from httpx import AsyncClient
from sqlalchemy import update as sa_update

pytestmark = pytest.mark.asyncio

_GET_BY_USERNAME = "/api/v1/user/{username}"
_GET_ME = "/api/v1/user/me/"
_USERNAME = "alicetester"


async def test_non_moderator_both_endpoints_return_false(
    async_client: AsyncClient,
    seeded_alice: dict,
) -> None:
    """Scenario 1 — default user: GET /user/{username} and GET /user/me/ both return is_moderator: false."""
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    _fastapi_app.dependency_overrides[get_current_user] = lambda: seeded_alice
    try:
        # Public endpoint — no auth required.
        by_username = await async_client.get(_GET_BY_USERNAME.format(username=_USERNAME))
        assert by_username.status_code == 200, by_username.text
        body_by_username = by_username.json()
        assert "is_moderator" in body_by_username, (
            f"is_moderator missing from GET /user/{{username}} response: {body_by_username}"
        )
        assert body_by_username["is_moderator"] is False

        # Authenticated endpoint — get_current_user is overridden to return seeded_alice dict.
        me = await async_client.get(_GET_ME)
        assert me.status_code == 200, me.text
        body_me = me.json()
        assert "is_moderator" in body_me, f"is_moderator missing from GET /user/me/ response: {body_me}"
        assert body_me["is_moderator"] is False
        assert body_me["is_superuser"] is False
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]


async def test_moderator_flag_set_both_endpoints_return_true(
    async_client: AsyncClient,
    seeded_alice: dict,
) -> None:
    """Scenario 2 — after is_moderator=True in DB: both endpoints return is_moderator: true."""
    from app.adapters.db.models.user import User
    from app.bootstrap.container import container as _di_container
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    # Set is_moderator=True directly in the test transaction via the overridden session.
    async with _di_container.session_factory()() as session:
        await session.execute(sa_update(User).where(User.username == _USERNAME).values(is_moderator=True))
        await session.commit()

    # Build an override dict that reflects the updated moderator status.
    moderator_alice = {**seeded_alice, "is_moderator": True}
    _fastapi_app.dependency_overrides[get_current_user] = lambda: moderator_alice
    try:
        # GET /user/{username} — exercises the full hexagonal stack;
        # the adapter reads from the updated ORM row.
        by_username = await async_client.get(_GET_BY_USERNAME.format(username=_USERNAME))
        assert by_username.status_code == 200, by_username.text
        body_by_username = by_username.json()
        assert "is_moderator" in body_by_username, (
            f"is_moderator missing from GET /user/{{username}} response: {body_by_username}"
        )
        assert body_by_username["is_moderator"] is True

        # GET /user/me/ — FastAPI serializes the override dict through UserMeRead.
        me = await async_client.get(_GET_ME)
        assert me.status_code == 200, me.text
        body_me = me.json()
        assert "is_moderator" in body_me, f"is_moderator missing from GET /user/me/ response: {body_me}"
        assert body_me["is_moderator"] is True
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]
