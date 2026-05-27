# FEATURE: migrate_erase_post_route_username_to_user_id — outside-in acceptance test.
#
# Covers: F1, F2, F13, F14, F15 (scenario 1 — owner DELETEs by integer id; GET → 404 after delete)
#         F5, F8, F16           (scenario 2 — non-owner → bare 403, post not deleted)
#         F9, F10               (scenario 3 — old string route gone → 422, post not deleted)
#
# Red-state trigger: the erase_post route is still DELETE /{username}/post/{id}
# with a str path param, and the use-case still resolves the target author by
# username (get_active_user_by_username). Against that old code:
#   - Scenario 1 (DELETE /api/v1/{alice_id}/post/{id}) matches the old str route
#     with username=str(alice_id); get_active_user_by_username(str(alice_id)) is
#     None → 404 "User not found", failing the 200 assertion.
#   - Scenario 2 (DELETE /api/v1/{alice_id}/post/{id} as bob) likewise resolves no
#     user by the numeric-string username → 404, failing the 403 assertion.
#   - Scenario 3 (DELETE /api/v1/ep57alice/post/{id}) still matches the old str
#     route and the username-based lookup + ownership check passes → 200, failing
#     the 422 assertion.
# After the migration (int path param, get_active_user_by_id, {user_id}_… cache
# keys) all three turn green.
import pytest
from httpx import AsyncClient
from sqlalchemy import text

pytestmark = pytest.mark.asyncio


async def test_owner_deletes_post_by_user_id_and_get_returns_404(
    async_client: AsyncClient,
    ep57_alice: dict,
    ep57_alice_post: dict,
) -> None:
    """Scenario 1 — owner DELETEs their post by integer id; DB shows soft-deleted; a later GET → 404."""
    from app.bootstrap.container import container as _di_container
    from app.main import app as _fastapi_app
    from app.shared_dependencies import get_current_user

    alice_id = ep57_alice["id"]
    post_id = ep57_alice_post["id"]

    # Read first to populate the {user_id}_post_cache read key (slice 0054).
    pre_get = await async_client.get(f"/api/v1/{alice_id}/post/{post_id}")
    assert pre_get.status_code == 200, pre_get.text

    _fastapi_app.dependency_overrides[get_current_user] = lambda: ep57_alice
    try:
        response = await async_client.delete(f"/api/v1/{alice_id}/post/{post_id}")
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 200, response.text
    assert response.json() == {"message": "Post deleted"}

    # DB assertion: the row was actually soft-deleted.
    async with _di_container.session_factory()() as session:
        result = await session.execute(
            text('SELECT is_deleted, deleted_at FROM "post" WHERE id = :id'),
            {"id": post_id},
        )
        row = result.first()
        assert row is not None
        assert row.is_deleted is True
        assert row.deleted_at is not None

    # The delete invalidated the {user_id}_post_cache key the GET reads, so the
    # subsequent read sees the soft-deleted row and returns 404 (no stale 200).
    get_response = await async_client.get(f"/api/v1/{alice_id}/post/{post_id}")
    assert get_response.status_code == 404, get_response.text


async def test_erase_post_forbidden_for_non_owner(
    async_client: AsyncClient,
    ep57_alice: dict,
    ep57_bob: dict,
    ep57_alice_post: dict,
) -> None:
    """Scenario 2 — bob targets alice's post by alice's id; must receive a bare 403 and delete nothing."""
    from app.bootstrap.container import container as _di_container
    from app.main import app as _fastapi_app
    from app.shared_dependencies import get_current_user

    alice_id = ep57_alice["id"]
    post_id = ep57_alice_post["id"]
    assert ep57_bob["id"] != alice_id

    _fastapi_app.dependency_overrides[get_current_user] = lambda: ep57_bob
    try:
        response = await async_client.delete(f"/api/v1/{alice_id}/post/{post_id}")
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 403, response.text

    # DB assertion: the post was not deleted (ownership fails before soft_delete).
    async with _di_container.session_factory()() as session:
        result = await session.execute(
            text('SELECT is_deleted FROM "post" WHERE id = :id'),
            {"id": post_id},
        )
        row = result.first()
        assert row is not None
        assert row.is_deleted is False


async def test_erase_post_old_username_route_gone(
    async_client: AsyncClient,
    ep57_alice: dict,
    ep57_alice_post: dict,
) -> None:
    """Scenario 3 — the old /{username}/post/{id} URL no longer resolves (string segment → 422)."""
    from app.bootstrap.container import container as _di_container
    from app.main import app as _fastapi_app
    from app.shared_dependencies import get_current_user

    post_id = ep57_alice_post["id"]

    _fastapi_app.dependency_overrides[get_current_user] = lambda: ep57_alice
    try:
        response = await async_client.delete(f"/api/v1/ep57alice/post/{post_id}")
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 422, response.text

    # DB assertion: the post was not deleted via the dead string route.
    async with _di_container.session_factory()() as session:
        result = await session.execute(
            text('SELECT is_deleted FROM "post" WHERE id = :id'),
            {"id": post_id},
        )
        row = result.first()
        assert row is not None
        assert row.is_deleted is False
