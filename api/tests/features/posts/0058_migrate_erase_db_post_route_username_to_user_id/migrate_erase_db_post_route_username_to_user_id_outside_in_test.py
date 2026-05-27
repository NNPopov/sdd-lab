# FEATURE: migrate_erase_db_post_route_username_to_user_id — outside-in acceptance test.
#
# Covers: F1, F2, F13, F14, F15, F16, F18 (scenario 1 — superuser hard-deletes by
#                                           integer id; GET → 404 after delete; row gone)
#         F9, F10                          (scenario 2 — old string route gone → 422, row survives)
#
# Red-state trigger: the erase_db_post route is still DELETE /{username}/db_post/{id}
# with a str path param, and the use-case still resolves the target author by
# username (get_active_user_by_username). Against that old code:
#   - Scenario 1 (DELETE /api/v1/{author_id}/db_post/{id}) matches the old str route
#     with username=str(author_id); get_active_user_by_username(str(author_id)) is
#     None → 404 "User not found", failing the 200 assertion.
#   - Scenario 2 (DELETE /api/v1/edp58author/db_post/{id}) still matches the old str
#     route and the username-based lookup succeeds → the post is hard-deleted and
#     200 is returned, failing the 422 assertion.
# After the migration (int path param, get_active_user_by_id, {user_id}_… cache
# keys) both turn green.
import pytest
from httpx import AsyncClient
from sqlalchemy import text

pytestmark = pytest.mark.asyncio


async def test_superuser_hard_deletes_post_by_user_id_and_get_returns_404(
    async_client: AsyncClient,
    edp58_author: dict,
    edp58_superuser: dict,
    edp58_author_post: dict,
) -> None:
    """Scenario 1 — superuser hard-deletes by integer id; DB row gone; a later GET → 404."""
    from app.bootstrap.container import container as _di_container
    from app.main import app as _fastapi_app
    from app.shared_dependencies import get_current_user

    author_id = edp58_author["id"]
    post_id = edp58_author_post["id"]
    assert edp58_superuser["id"] != author_id  # superuser deletes another user's post

    # Read first to populate the {user_id}_post_cache read key (slice 0054).
    pre_get = await async_client.get(f"/api/v1/{author_id}/post/{post_id}")
    assert pre_get.status_code == 200, pre_get.text

    _fastapi_app.dependency_overrides[get_current_user] = lambda: edp58_superuser
    try:
        response = await async_client.delete(f"/api/v1/{author_id}/db_post/{post_id}")
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 200, response.text
    assert response.json() == {"message": "Post deleted from the database"}

    # DB assertion: the row was physically deleted (hard delete, not soft delete).
    async with _di_container.session_factory()() as session:
        result = await session.execute(
            text('SELECT id FROM "post" WHERE id = :id'),
            {"id": post_id},
        )
        row = result.first()
        assert row is None, "post row still exists after hard delete"

    # The delete invalidated the {user_id}_post_cache key the GET reads, so the
    # subsequent read sees the destroyed row and returns 404 (no stale 200).
    get_response = await async_client.get(f"/api/v1/{author_id}/post/{post_id}")
    assert get_response.status_code == 404, get_response.text


async def test_erase_db_post_old_username_route_gone(
    async_client: AsyncClient,
    edp58_author: dict,
    edp58_superuser: dict,
    edp58_author_post: dict,
) -> None:
    """Scenario 2 — the old /{username}/db_post/{id} URL no longer resolves (string segment → 422)."""
    from app.bootstrap.container import container as _di_container
    from app.main import app as _fastapi_app
    from app.shared_dependencies import get_current_user

    post_id = edp58_author_post["id"]

    _fastapi_app.dependency_overrides[get_current_user] = lambda: edp58_superuser
    try:
        response = await async_client.delete(f"/api/v1/edp58author/db_post/{post_id}")
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 422, response.text

    # DB assertion: the post was not deleted via the dead string route.
    async with _di_container.session_factory()() as session:
        result = await session.execute(
            text('SELECT id, is_deleted FROM "post" WHERE id = :id'),
            {"id": post_id},
        )
        row = result.first()
        assert row is not None
        assert row.is_deleted is False
