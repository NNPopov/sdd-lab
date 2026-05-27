# FEATURE: update_post — outside-in acceptance test.
#
# Covers: F1, F9  (scenario 1 — owner patches their post; GET confirms change)
#         F4      (scenario 2 — ownership violation → 403, DB unchanged)
#
# Migrated to the integer {user_id} route by slice 0056; ownership now delegates
# to the shared check_post_owner, which raises a bare ForbiddenDomainError().
import pytest
from httpx import AsyncClient
from sqlalchemy import text

pytestmark = pytest.mark.asyncio

_PATCH_PATH = "/api/v1/{user_id}/post/{id}"
_GET_PATH = "/api/v1/{user_id}/post/{id}"  # get_post migrated to integer user_id (slice 0054)


async def test_owner_patches_post_and_get_confirms_change(
    async_client: AsyncClient,
    up28_alice: dict,
    up28_alice_post: dict,
) -> None:
    """Scenario 1 — owner PATCHes their post; subsequent GET shows the updated title."""
    from app.bootstrap.container import container as _di_container
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    post_id = up28_alice_post["id"]
    patch_url = _PATCH_PATH.format(user_id=up28_alice["id"], id=post_id)
    get_url = _GET_PATH.format(user_id=up28_alice["id"], id=post_id)

    _fastapi_app.dependency_overrides[get_current_user] = lambda: up28_alice
    try:
        response = await async_client.patch(
            patch_url,
            json={"title": "Updated title"},
        )
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 200, response.text
    assert response.json() == {"message": "Post updated"}

    response = await async_client.get(get_url)
    assert response.status_code == 200, response.text
    body = response.json()
    assert body["title"] == "Updated title"
    assert body["text"] == "Original text."

    async with _di_container.session_factory()() as session:
        result = await session.execute(
            text('SELECT title, updated_at FROM "post" WHERE id = :id'),
            {"id": post_id},
        )
        row = result.first()
        assert row is not None
        assert row.title == "Updated title"
        assert row.updated_at is not None


async def test_ownership_violation_bob_targets_alice_post(
    async_client: AsyncClient,
    up28_alice: dict,
    up28_bob: dict,
    up28_alice_post: dict,
) -> None:
    """Scenario 2 — bob PATCHes alice's post; expects 403 and DB title unchanged."""
    from app.bootstrap.container import container as _di_container
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    post_id = up28_alice_post["id"]
    patch_url = _PATCH_PATH.format(user_id=up28_alice["id"], id=post_id)

    _fastapi_app.dependency_overrides[get_current_user] = lambda: up28_bob
    try:
        response = await async_client.patch(
            patch_url,
            json={"title": "Hijacked title"},
        )
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 403, response.text
    assert response.json() == {"error": {"code": "forbidden", "message": ""}}

    async with _di_container.session_factory()() as session:
        result = await session.execute(
            text('SELECT title FROM "post" WHERE id = :id'),
            {"id": post_id},
        )
        row = result.first()
        assert row is not None
        assert row.title == "Original title"
