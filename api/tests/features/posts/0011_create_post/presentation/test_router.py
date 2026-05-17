# FEATURE: create_post — endpoint integration tests.
#
# Covers: F1, F2, F3, F5, F6, F7, F8, F14, F15.
import pytest
from httpx import AsyncClient

pytestmark = pytest.mark.asyncio

_ENDPOINT = "/api/v1/{username}/post"
_VALID_BODY = {"title": "Hello world", "text": "My first post.", "media_url": None}


# ── F1, F6, F14: happy path → 201 ────────────────────────────────────────────


async def test_create_post_returns_201_with_correct_schema(
    async_client: AsyncClient,
    seeded_alice: dict,
) -> None:
    """F1, F6, F14 — valid payload → 201; response matches CreatePostResponse schema."""
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    _fastapi_app.dependency_overrides[get_current_user] = lambda: seeded_alice
    try:
        response = await async_client.post(
            _ENDPOINT.format(username="alice"),
            json=_VALID_BODY,
        )
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 201
    body = response.json()
    assert body["title"] == "Hello world"
    assert body["text"] == "My first post."
    assert body["media_url"] is None
    assert body["created_by_user_id"] == seeded_alice["id"]
    assert isinstance(body["id"], int)
    assert "created_at" in body
    assert "uuid" not in body
    assert "is_deleted" not in body


# ── F7: unknown username → 404 ────────────────────────────────────────────────


async def test_create_post_returns_404_for_unknown_username(
    async_client: AsyncClient,
    seeded_alice: dict,
) -> None:
    """F7 — username not in DB → NotFoundDomainError → 404."""
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    _fastapi_app.dependency_overrides[get_current_user] = lambda: seeded_alice
    try:
        response = await async_client.post(
            _ENDPOINT.format(username="ghost_xyz"),
            json=_VALID_BODY,
        )
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 404
    body = response.json()
    assert body["error"]["code"] == "notfound"
    assert body["error"]["message"] == "User not found"


# ── F8: ownership mismatch → 403 ─────────────────────────────────────────────


async def test_create_post_returns_403_when_requester_is_not_owner(
    async_client: AsyncClient,
    seeded_alice: dict,
    seeded_bob: dict,
) -> None:
    """F8 — bob posts under alice's path → ForbiddenDomainError → 403."""
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    _fastapi_app.dependency_overrides[get_current_user] = lambda: seeded_bob
    try:
        response = await async_client.post(
            _ENDPOINT.format(username="alice"),
            json=_VALID_BODY,
        )
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 403
    assert response.json() == {
        "error": {
            "code": "forbidden",
            "message": "You can only post under your own username",
        }
    }


# ── F2: missing title → 422 ───────────────────────────────────────────────────


async def test_create_post_returns_422_when_title_missing(
    async_client: AsyncClient,
    seeded_alice: dict,
) -> None:
    """F2 — missing title field → 422 validation error."""
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    _fastapi_app.dependency_overrides[get_current_user] = lambda: seeded_alice
    try:
        response = await async_client.post(
            _ENDPOINT.format(username="alice"),
            json={"text": "Some text."},
        )
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 422


# ── F3: missing text → 422 ───────────────────────────────────────────────────


async def test_create_post_returns_422_when_text_missing(
    async_client: AsyncClient,
    seeded_alice: dict,
) -> None:
    """F3 — missing text field → 422 validation error."""
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    _fastapi_app.dependency_overrides[get_current_user] = lambda: seeded_alice
    try:
        response = await async_client.post(
            _ENDPOINT.format(username="alice"),
            json={"title": "A Title"},
        )
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 422
