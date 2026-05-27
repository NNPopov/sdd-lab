# FEATURE: create_post_status — endpoint integration tests.
#
# Covers: F3, F4.
import pytest
from httpx import AsyncClient

pytestmark = pytest.mark.asyncio

_ENDPOINT = "/api/v1/{user_id}/post"
_VALID_BODY = {"title": "Hello world", "text": "My first post.", "media_url": None}


async def test_create_post_returns_status_in_response(
    async_client: AsyncClient,
    seeded_alice: dict,
) -> None:
    """F3, F4 — POST returns 201 with status=pending_review and all pre-existing fields."""
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    _fastapi_app.dependency_overrides[get_current_user] = lambda: seeded_alice
    try:
        response = await async_client.post(
            _ENDPOINT.format(user_id=seeded_alice["id"]),
            json=_VALID_BODY,
        )
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 201
    body = response.json()

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
