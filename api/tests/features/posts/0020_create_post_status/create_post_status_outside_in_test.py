# FEATURE: create_post_status — outside-in acceptance test.
#
# Covers: F1, F2, F3, F4 (happy path), F5, F6 (forbidden guard).
#
# Red-state trigger: CreatePostResponse and CreatedPost do not yet carry a
# `status` field, so body["status"] raises KeyError in Scenario 1.
import pytest
from httpx import AsyncClient
from sqlalchemy import text

pytestmark = pytest.mark.asyncio

_ENDPOINT = "/api/v1/{user_id}/post"


async def test_create_post_returns_status_pending_review(
    async_client: AsyncClient,
    seeded_alice: dict,
) -> None:
    """Scenario 1 — author creates a post; response and DB row both show pending_review."""
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

    # New field — primary assertion for this slice.
    assert body["status"] == "pending_review"

    # Pre-existing fields must remain intact (F4).
    assert body["title"] == "Hello world"
    assert body["text"] == "My first post."
    assert body["media_url"] is None
    assert body["created_by_user_id"] == seeded_alice["id"]
    assert isinstance(body["id"], int)
    assert "created_at" in body
    assert "uuid" not in body
    assert "is_deleted" not in body

    # DB assertion: the persisted row carries status = "pending_review" (F2).
    from app.bootstrap.container import container as _di_container

    async with _di_container.session_factory()() as session:
        result = await session.execute(
            text('SELECT status FROM "post" WHERE title = :t'),
            {"t": "Hello world"},
        )
        row = result.first()
        assert row is not None, "post row not found after create"
        assert row.status == "pending_review"


async def test_create_post_forbidden_when_requester_is_not_owner(
    async_client: AsyncClient,
    seeded_alice: dict,
    seeded_bob: dict,
) -> None:
    """Scenario 2 — bob posts under alice's id; existing guard still returns 403."""
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    _fastapi_app.dependency_overrides[get_current_user] = lambda: seeded_bob
    try:
        response = await async_client.post(
            _ENDPOINT.format(user_id=seeded_alice["id"]),
            json={"title": "Intruder title", "text": "Intruder content."},
        )
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 403, response.text
    assert response.json() == {"error": {"code": "forbidden", "message": ""}}

    # DB assertion: no post row was created (F5, F6).
    from app.bootstrap.container import container as _di_container

    async with _di_container.session_factory()() as session:
        result = await session.execute(
            text('SELECT id FROM "post" WHERE title = :t'),
            {"t": "Intruder title"},
        )
        row = result.first()
        assert row is None, "post was wrongly created after a forbidden request"
