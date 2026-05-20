# FEATURE: erase_db_post — outside-in acceptance test.
#
# Covers: F1, F4, F7, F10  (scenario 1 — admin hard-deletes alice's post;
#                            DB row gone; subsequent GET → 404)
#         F3, F8, F11       (scenario 2 — wrong namespace → 404; non-superuser
#                            → 403; post survives both; correct delete → 200)
#
# Red-state trigger: scenario 2, step 1 — admin uses bob's username namespace
# to target alice's post_id. The existing flat erase_db_post handler finds the
# post by id only (no created_by_user_id filter) and permanently deletes it,
# returning 200. The new EraseDbPostAdapter.find_post filters by
# created_by_user_id so the post is not found for bob's namespace → 404.
import pytest
from httpx import AsyncClient
from sqlalchemy import text

pytestmark = pytest.mark.asyncio

_DELETE_PATH = "/api/v1/{username}/db_post/{id}"
_GET_PATH = "/api/v1/{username}/post/{id}"

# Superuser identity injected via dependency_overrides on get_current_user.
_SUPERUSER = {
    "id": 9999,
    "username": "ep30admin",
    "email": "ep30admin@example.com",
    "name": "EP30 Admin",
    "is_superuser": True,
}


async def test_admin_hard_deletes_post_row_is_gone_and_get_returns_404(
    async_client: AsyncClient,
    ep30_alice: dict,
    ep30_alice_post: dict,
) -> None:
    """Scenario 1 — admin hard-deletes alice's post; DB row and all moderation logs permanently gone; GET → 404."""
    from app.bootstrap.container import container as _di_container
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    post_id = ep30_alice_post["id"]
    delete_url = _DELETE_PATH.format(username="ep30alice", id=post_id)
    get_url = _GET_PATH.format(username="ep30alice", id=post_id)

    # Seed a PostModerationLog row to exercise the cascade-delete path (F2, N2).
    async with _di_container.session_factory()() as session:
        log_insert = await session.execute(
            text(
                "INSERT INTO post_moderation_log"
                " (post_id, user_id, event_type, action, message, created_at)"
                " VALUES (:post_id, :user_id, :event_type, :action, :message, NOW()) RETURNING id"
            ),
            {
                "post_id": post_id,
                "user_id": ep30_alice["id"],
                "event_type": "moderate",
                "action": "approve",
                "message": "seeded for cascade test",
            },
        )
        await session.commit()
        log_id = log_insert.scalar_one()

    # Warm any cache that may be present (also proves the post is visible pre-deletion).
    get_pre = await async_client.get(get_url)
    assert get_pre.status_code == 200, get_pre.text

    _fastapi_app.dependency_overrides[get_current_user] = lambda: _SUPERUSER
    try:
        response = await async_client.delete(delete_url)
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 200, response.text
    assert response.json() == {"message": "Post deleted from the database"}

    # DB assertion: the row must not exist — permanently deleted, not soft-deleted.
    async with _di_container.session_factory()() as session:
        result = await session.execute(
            text('SELECT id FROM "post" WHERE id = :id'),
            {"id": post_id},
        )
        row = result.first()
        assert row is None, "post row still exists after hard delete"

        # Cascade assertion: moderation log rows for the post must also be gone (F2).
        log_result = await session.execute(
            text("SELECT id FROM post_moderation_log WHERE post_id = :post_id"),
            {"post_id": post_id},
        )
        log_row = log_result.first()
        assert log_row is None, f"post_moderation_log row {log_id} still exists after hard delete"

    # Cache invalidation: subsequent GET must not serve stale data.
    get_post = await async_client.get(get_url)
    assert get_post.status_code == 404, get_post.text


async def test_ownership_enforcement_wrong_namespace_and_non_superuser(
    async_client: AsyncClient,
    ep30_alice: dict,
    ep30_bob: dict,
    ep30_alice_post: dict,
) -> None:
    """Scenario 2 — wrong namespace → 404; non-superuser → 403; post survives both; correct delete → 200."""
    from app.bootstrap.container import container as _di_container
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    post_id = ep30_alice_post["id"]

    # Step 1: admin uses bob's namespace for alice's post → 404 (ownership filter).
    wrong_ns_url = _DELETE_PATH.format(username="ep30bob", id=post_id)
    _fastapi_app.dependency_overrides[get_current_user] = lambda: _SUPERUSER
    try:
        resp_wrong_ns = await async_client.delete(wrong_ns_url)
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert resp_wrong_ns.status_code == 404, resp_wrong_ns.text
    assert resp_wrong_ns.json() == {"error": {"code": "notfound", "message": "Post not found"}}

    # DB assertion: alice's post must still exist after the wrong-namespace attempt.
    async with _di_container.session_factory()() as session:
        result = await session.execute(
            text('SELECT id FROM "post" WHERE id = :id'),
            {"id": post_id},
        )
        row = result.first()
        assert row is not None, "post was wrongly deleted despite wrong namespace"

    # Step 2: non-superuser (alice herself) attempts delete → 403.
    alice_url = _DELETE_PATH.format(username="ep30alice", id=post_id)
    _fastapi_app.dependency_overrides[get_current_user] = lambda: ep30_alice
    try:
        resp_non_super = await async_client.delete(alice_url)
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert resp_non_super.status_code == 403, resp_non_super.text

    # Step 3: admin, correct namespace → 200; post is permanently deleted.
    _fastapi_app.dependency_overrides[get_current_user] = lambda: _SUPERUSER
    try:
        resp_correct = await async_client.delete(alice_url)
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert resp_correct.status_code == 200, resp_correct.text
    assert resp_correct.json() == {"message": "Post deleted from the database"}

    # DB assertion: row must be permanently gone after correct hard-delete.
    async with _di_container.session_factory()() as session:
        result = await session.execute(
            text('SELECT id FROM "post" WHERE id = :id'),
            {"id": post_id},
        )
        row = result.first()
        assert row is None, "post row still exists after correct hard delete"
