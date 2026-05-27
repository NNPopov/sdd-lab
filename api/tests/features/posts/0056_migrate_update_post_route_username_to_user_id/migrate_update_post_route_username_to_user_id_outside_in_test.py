# FEATURE: migrate_update_post_route_username_to_user_id — outside-in acceptance test.
#
# Covers: F1, F3, F14, F15, F16 (scenario 1 — owner PATCHes by integer id; GET shows fresh title)
#         F6, F9, F17           (scenario 2 — non-owner → bare 403, DB title unchanged)
#         F10, F11              (scenario 3 — old string route gone → 422, DB unchanged)
#
# Red-state trigger: the update_post route is still PATCH /{username}/post/{id}
# with a str path param, and the use-case still resolves the author by username
# and compares usernames with the message "You can only update your own posts".
# Against that old code:
#   - Scenario 1 (PATCH /api/v1/{alice_id}/post/{id}) matches the old str route
#     with username=str(alice_id); get_active_user_by_username(str(alice_id)) is
#     None → 404 "User not found", failing the 200 assertion.
#   - Scenario 2 (PATCH /api/v1/{alice_id}/post/{id} as bob) likewise resolves no
#     user by the numeric-string username → 404, failing the 403 assertion.
#   - Scenario 3 (PATCH /api/v1/up56alice/post/{id}) still matches the old str
#     route and the username-based ownership check passes → 200, failing the 422
#     assertion.
# After the migration (int path param, get_active_user_by_id, id-based
# check_post_owner, {user_id}_… cache keys) all three turn green.
import pytest
from httpx import AsyncClient
from sqlalchemy import text

pytestmark = pytest.mark.asyncio


async def test_owner_updates_post_by_user_id_and_get_confirms_change(
    async_client: AsyncClient,
    up56_alice: dict,
    up56_alice_post: dict,
) -> None:
    """Scenario 1 — owner PATCHes their post by integer id; a later GET shows the updated title."""
    from app.bootstrap.container import container as _di_container
    from app.main import app as _fastapi_app
    from app.shared_dependencies import get_current_user

    alice_id = up56_alice["id"]
    post_id = up56_alice_post["id"]

    _fastapi_app.dependency_overrides[get_current_user] = lambda: up56_alice
    try:
        response = await async_client.patch(
            f"/api/v1/{alice_id}/post/{post_id}",
            json={"title": "Updated title"},
        )
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 200, response.text
    assert response.json() == {"message": "Post updated"}

    # The update repoints/invalidates the {user_id}_post_cache key the GET reads,
    # so the subsequent read returns fresh content (no stale read).
    get_response = await async_client.get(f"/api/v1/{alice_id}/post/{post_id}")
    assert get_response.status_code == 200, get_response.text
    body = get_response.json()
    assert body["title"] == "Updated title"
    assert body["text"] == "Original text."  # untouched field unchanged

    # DB assertion: the row was actually updated.
    async with _di_container.session_factory()() as session:
        result = await session.execute(
            text('SELECT title, updated_at FROM "post" WHERE id = :id'),
            {"id": post_id},
        )
        row = result.first()
        assert row is not None
        assert row.title == "Updated title"
        assert row.updated_at is not None


async def test_update_post_forbidden_for_non_owner(
    async_client: AsyncClient,
    up56_alice: dict,
    up56_bob: dict,
    up56_alice_post: dict,
) -> None:
    """Scenario 2 — bob targets alice's post by alice's id; must receive a bare 403 and change nothing."""
    from app.bootstrap.container import container as _di_container
    from app.main import app as _fastapi_app
    from app.shared_dependencies import get_current_user

    alice_id = up56_alice["id"]
    post_id = up56_alice_post["id"]
    assert up56_bob["id"] != alice_id

    _fastapi_app.dependency_overrides[get_current_user] = lambda: up56_bob
    try:
        response = await async_client.patch(
            f"/api/v1/{alice_id}/post/{post_id}",
            json={"title": "Hijacked title"},
        )
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 403, response.text
    # The bare ForbiddenDomainError() carries no ownership-specific message; the
    # old "You can only update your own posts" text is gone.
    assert "You can only update your own posts" not in response.text

    # DB assertion: the title was not changed.
    async with _di_container.session_factory()() as session:
        result = await session.execute(
            text('SELECT title FROM "post" WHERE id = :id'),
            {"id": post_id},
        )
        row = result.first()
        assert row is not None
        assert row.title == "Original title"


async def test_update_post_old_username_route_gone(
    async_client: AsyncClient,
    up56_alice: dict,
    up56_alice_post: dict,
) -> None:
    """Scenario 3 — the old /{username}/post/{id} URL no longer resolves (string segment → 422)."""
    from app.bootstrap.container import container as _di_container
    from app.main import app as _fastapi_app
    from app.shared_dependencies import get_current_user

    post_id = up56_alice_post["id"]

    _fastapi_app.dependency_overrides[get_current_user] = lambda: up56_alice
    try:
        response = await async_client.patch(
            f"/api/v1/up56alice/post/{post_id}",
            json={"title": "Via username"},
        )
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 422, response.text

    # DB assertion: the title was not changed via the dead string route.
    async with _di_container.session_factory()() as session:
        result = await session.execute(
            text('SELECT title FROM "post" WHERE id = :id'),
            {"id": post_id},
        )
        row = result.first()
        assert row is not None
        assert row.title == "Original title"
