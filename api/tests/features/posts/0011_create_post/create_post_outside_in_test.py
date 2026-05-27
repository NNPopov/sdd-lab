# FEATURE: create_post — outside-in acceptance test.
#
# Covers: F1, F6, F8, F9, F10, F13, F14 (see requirements.md).
#
# Red-state trigger: features/posts/create_post/ does not exist yet.
# POST /{username}/post is handled by the old write_post handler which uses
# async_get_db (not the container's session_factory override), so alice seeded
# in the test transaction is invisible to it → returns 404, failing the 201
# assertion. After the new slice replaces write_post, the container-scoped
# session sees the seeded data and both tests turn green.
import pytest
from httpx import AsyncClient
from sqlalchemy import text

pytestmark = pytest.mark.asyncio

_ENDPOINT = "/api/v1/{user_id}/post"


async def test_create_post_happy_path(
    async_client: AsyncClient,
    seeded_alice: dict,
) -> None:
    """Scenario 1 — owner creates a post under their own user_id; response is 201."""
    from app.bootstrap.container import container as _di_container
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    _fastapi_app.dependency_overrides[get_current_user] = lambda: seeded_alice
    try:
        response = await async_client.post(
            _ENDPOINT.format(user_id=seeded_alice["id"]),
            json={"title": "Hello world", "text": "My first post.", "media_url": None},
        )
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 201, response.text
    body = response.json()

    assert body["title"] == "Hello world"
    assert body["text"] == "My first post."
    assert body["media_url"] is None
    assert body["created_by_user_id"] == seeded_alice["id"]
    assert isinstance(body["id"], int)
    assert "created_at" in body
    assert "uuid" not in body
    assert "is_deleted" not in body

    # DB assertion: a post row was committed and is visible in the test transaction.
    async with _di_container.session_factory()() as session:
        result = await session.execute(
            text('SELECT title, created_by_user_id, is_deleted FROM "post" WHERE title = :t'),
            {"t": "Hello world"},
        )
        row = result.first()
        assert row is not None, "post row not found after create"
        assert row.title == "Hello world"
        assert row.created_by_user_id == seeded_alice["id"]
        assert row.is_deleted is False


async def test_create_post_forbidden_wrong_owner(
    async_client: AsyncClient,
    seeded_alice: dict,
    seeded_bob: dict,
) -> None:
    """Scenario 2 — bob posts under alice's id; must receive 403 and no post is created."""
    from app.bootstrap.container import container as _di_container
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    _fastapi_app.dependency_overrides[get_current_user] = lambda: seeded_bob
    try:
        response = await async_client.post(
            _ENDPOINT.format(user_id=seeded_alice["id"]),
            json={"title": "Intruder title", "text": "Intruder text."},
        )
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 403, response.text
    assert response.json() == {"error": {"code": "forbidden", "message": ""}}

    # DB assertion: no post row was created.
    async with _di_container.session_factory()() as session:
        result = await session.execute(
            text('SELECT id FROM "post" WHERE title = :t'),
            {"t": "Intruder title"},
        )
        row = result.first()
        assert row is None, "post was wrongly created after a forbidden request"
