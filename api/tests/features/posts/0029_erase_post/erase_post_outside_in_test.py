# FEATURE: erase_post — outside-in acceptance test.
#
# Covers: F1, F6, F9, F11  (scenario 1 — owner deletes their post; DB and GET confirm)
#         F5, F8            (scenario 2 — ownership gap fix; bob uses bob's path,
#                            alice's post_id → 404 because find_post filters by
#                            created_by_user_id; old flat handler returns 200)
#
# Red-state trigger: scenario 2 asserts 404 but the existing flat erase_post handler
# returns 200 because it does not filter posts by owner — the authorization gap that
# ErasePostAdapter.find_post(post_id, owner_id) closes.
import pytest
from httpx import AsyncClient
from sqlalchemy import text

pytestmark = pytest.mark.asyncio

_DELETE_PATH = "/api/v1/{username}/post/{id}"
_GET_PATH = "/api/v1/{username}/post/{id}"


async def test_owner_deletes_post_db_shows_deleted_and_get_returns_404(
    async_client: AsyncClient,
    ep29_alice: dict,
    ep29_alice_post: dict,
) -> None:
    """Scenario 1 — owner deletes their post; DB has is_deleted=True; subsequent GET → 404."""
    from app.bootstrap.container import container as _di_container
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    post_id = ep29_alice_post["id"]
    delete_url = _DELETE_PATH.format(username="ep29alice", id=post_id)
    get_url = _GET_PATH.format(username="ep29alice", id=post_id)

    _fastapi_app.dependency_overrides[get_current_user] = lambda: ep29_alice
    try:
        response = await async_client.delete(delete_url)
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 200, response.text
    assert response.json() == {"message": "Post deleted"}

    async with _di_container.session_factory()() as session:
        result = await session.execute(
            text('SELECT is_deleted, deleted_at FROM "post" WHERE id = :id'),
            {"id": post_id},
        )
        row = result.first()
        assert row is not None
        assert row.is_deleted is True
        assert row.deleted_at is not None

    get_response = await async_client.get(get_url)
    assert get_response.status_code == 404, get_response.text


async def test_ownership_gap_bob_uses_bobs_path_to_delete_alices_post_returns_404(
    async_client: AsyncClient,
    ep29_alice: dict,
    ep29_bob: dict,
    ep29_alice_post: dict,
) -> None:
    """Scenario 2 — ownership gap fix: Bob targets his own path with Alice's post_id → 404."""
    from app.bootstrap.container import container as _di_container
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    post_id = ep29_alice_post["id"]
    # Bob uses BOB's path segment (not Alice's), so no 403 check fires.
    # The new find_post(post_id, owner_id=bob.id) returns None because the post
    # belongs to alice — that is what closes the authorization gap.
    delete_url = _DELETE_PATH.format(username="ep29bob", id=post_id)

    _fastapi_app.dependency_overrides[get_current_user] = lambda: ep29_bob
    try:
        response = await async_client.delete(delete_url)
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 404, response.text
    assert response.json() == {"error": {"code": "notfound", "message": "Post not found"}}

    async with _di_container.session_factory()() as session:
        result = await session.execute(
            text('SELECT is_deleted FROM "post" WHERE id = :id'),
            {"id": post_id},
        )
        row = result.first()
        assert row is not None
        assert row.is_deleted is False
