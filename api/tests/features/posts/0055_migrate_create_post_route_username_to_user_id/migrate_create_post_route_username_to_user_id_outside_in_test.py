# FEATURE: migrate_create_post_route_username_to_user_id — outside-in acceptance test.
#
# Covers: F1, F2, F3, F7, F8, F9, F10, F11, F14, F18 (see requirements.md).
#
# Red-state trigger: the create_post route is still POST /{username}/post with a
# str path param, and the use-case still resolves the author by username and
# compares usernames. Against that old code:
#   - Scenario 1 (POST /api/v1/{author_id}/post) matches the old str route with
#     username=str(author_id); get_active_user_by_username(str(author_id)) is None
#     → 404 "User not found", failing the 201 assertion.
#   - Scenario 2 (POST /api/v1/{other_id}/post) likewise resolves no user by the
#     numeric-string username → 404, failing the 403 assertion.
#   - Scenario 3 (POST /api/v1/gp55alice/post) still matches the old str route and
#     the username-based ownership check passes → 201, failing the 422 assertion.
# After the migration (int path param, get_active_user_by_id, id-based
# check_post_owner) all three turn green.
import pytest
from httpx import AsyncClient
from sqlalchemy import text

pytestmark = pytest.mark.asyncio


async def test_create_post_happy_path_by_user_id(
    async_client: AsyncClient,
    seeded_author: dict,
) -> None:
    """Scenario 1 — owner creates a post under their own integer id; response is 201."""
    from app.bootstrap.container import container as _di_container
    from app.main import app as _fastapi_app
    from app.shared_dependencies import get_current_user

    author_id = seeded_author["id"]
    _fastapi_app.dependency_overrides[get_current_user] = lambda: seeded_author
    try:
        response = await async_client.post(
            f"/api/v1/{author_id}/post",
            json={"title": "Hello", "text": "First post", "media_url": None},
        )
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 201, response.text
    body = response.json()

    assert body["title"] == "Hello"
    assert body["text"] == "First post"
    assert body["media_url"] is None
    assert body["created_by_user_id"] == author_id
    assert body["status"] == "pending_review"
    assert isinstance(body["id"], int)
    assert "post_uuid" in body
    assert "created_at" in body
    assert "username" not in body

    # DB assertion: exactly one post row was committed for the author.
    async with _di_container.session_factory()() as session:
        result = await session.execute(
            text('SELECT created_by_user_id, status, is_deleted FROM "post" WHERE title = :t'),
            {"t": "Hello"},
        )
        rows = result.all()
        assert len(rows) == 1, "expected exactly one post row after create"
        row = rows[0]
        assert row.created_by_user_id == author_id
        assert row.status == "pending_review"
        assert row.is_deleted is False


async def test_create_post_forbidden_under_other_user_id(
    async_client: AsyncClient,
    seeded_author: dict,
    seeded_other_user: dict,
) -> None:
    """Scenario 2 — author targets another user's id; must receive 403 and create nothing."""
    from app.bootstrap.container import container as _di_container
    from app.main import app as _fastapi_app
    from app.shared_dependencies import get_current_user

    other_id = seeded_other_user["id"]
    assert other_id != seeded_author["id"]

    _fastapi_app.dependency_overrides[get_current_user] = lambda: seeded_author
    try:
        response = await async_client.post(
            f"/api/v1/{other_id}/post",
            json={"title": "Intruder title", "text": "Intruder text", "media_url": None},
        )
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 403, response.text
    # The bare ForbiddenDomainError() carries no ownership-specific message; the
    # old "You can only post under your own username" text is gone.
    assert "You can only post under your own username" not in response.text

    # DB assertion: no post row was created for the other user.
    async with _di_container.session_factory()() as session:
        result = await session.execute(
            text('SELECT id FROM "post" WHERE created_by_user_id = :uid'),
            {"uid": other_id},
        )
        assert result.first() is None, "post was wrongly created for a non-owner target"


async def test_create_post_old_username_route_gone(
    async_client: AsyncClient,
    seeded_author: dict,
) -> None:
    """Scenario 3 — the old /{username}/post URL no longer resolves (string segment → 422)."""
    from app.bootstrap.container import container as _di_container
    from app.main import app as _fastapi_app
    from app.shared_dependencies import get_current_user

    _fastapi_app.dependency_overrides[get_current_user] = lambda: seeded_author
    try:
        response = await async_client.post(
            "/api/v1/gp55alice/post",
            json={"title": "Via username", "text": "Body", "media_url": None},
        )
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 422, response.text

    # DB assertion: no post row was created via the dead string route.
    async with _di_container.session_factory()() as session:
        result = await session.execute(
            text('SELECT id FROM "post" WHERE title = :t'),
            {"t": "Via username"},
        )
        assert result.first() is None, "post was wrongly created via the old string route"
