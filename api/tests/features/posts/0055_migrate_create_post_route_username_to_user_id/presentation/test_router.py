# FEATURE: migrate_create_post_route_username_to_user_id — endpoint integration tests.
#
# Covers: F1, F2, F3, F4, F5, F6, F7, F10, F11, F14, F18.
import pytest
from httpx import AsyncClient

pytestmark = pytest.mark.asyncio

_ENDPOINT = "/api/v1/{user_id}/post"
_VALID_BODY = {"title": "Hello", "text": "First post", "media_url": None}


# ── F1, F2, F3, F14: happy path → 201 ────────────────────────────────────────


async def test_create_post_returns_201_for_owner(
    async_client: AsyncClient,
    seeded_author: dict,
) -> None:
    """F1, F2, F3, F14 — owner posts under own id → 201 with default status."""
    from app.main import app as _fastapi_app
    from app.shared_dependencies import get_current_user

    _fastapi_app.dependency_overrides[get_current_user] = lambda: seeded_author
    try:
        response = await async_client.post(
            _ENDPOINT.format(user_id=seeded_author["id"]),
            json=_VALID_BODY,
        )
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 201, response.text
    body = response.json()
    assert body["title"] == "Hello"
    assert body["text"] == "First post"
    assert body["media_url"] is None
    assert body["created_by_user_id"] == seeded_author["id"]
    assert body["status"] == "pending_review"
    assert isinstance(body["id"], int)
    assert "post_uuid" in body
    assert "created_at" in body
    assert "username" not in body


# ── F7, F18: ownership mismatch → 403 (no message) ───────────────────────────


async def test_create_post_returns_403_for_non_owner(
    async_client: AsyncClient,
    seeded_author: dict,
    seeded_other_user: dict,
) -> None:
    """F7, F18 — author targets another user's id → bare 403."""
    from app.main import app as _fastapi_app
    from app.shared_dependencies import get_current_user

    _fastapi_app.dependency_overrides[get_current_user] = lambda: seeded_author
    try:
        response = await async_client.post(
            _ENDPOINT.format(user_id=seeded_other_user["id"]),
            json=_VALID_BODY,
        )
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 403, response.text
    assert response.json() == {"error": {"code": "forbidden", "message": ""}}
    assert "You can only post under your own username" not in response.text


# ── F6: unknown user_id → 404 (before ownership) ─────────────────────────────


async def test_create_post_returns_404_for_unknown_user_id(
    async_client: AsyncClient,
    seeded_author: dict,
) -> None:
    """F6 — unknown target id → NotFoundDomainError → 404."""
    from app.main import app as _fastapi_app
    from app.shared_dependencies import get_current_user

    _fastapi_app.dependency_overrides[get_current_user] = lambda: seeded_author
    try:
        response = await async_client.post(
            _ENDPOINT.format(user_id=999999),
            json=_VALID_BODY,
        )
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 404, response.text
    body = response.json()
    assert body["error"]["code"] == "notfound"
    assert body["error"]["message"] == "User not found"


# ── F5: unauthenticated → 401 ────────────────────────────────────────────────


async def test_create_post_returns_401_when_unauthenticated(
    async_client: AsyncClient,
    seeded_author: dict,
) -> None:
    """F5 — no credentials → 401; the use-case is never reached."""
    response = await async_client.post(
        _ENDPOINT.format(user_id=seeded_author["id"]),
        json=_VALID_BODY,
    )
    assert response.status_code == 401, response.text


# ── F10: non-integer user_id → 422 ───────────────────────────────────────────


async def test_create_post_returns_422_for_non_integer_user_id(
    async_client: AsyncClient,
    seeded_author: dict,
) -> None:
    """F10 — non-integer path segment → 422 (path validation)."""
    from app.main import app as _fastapi_app
    from app.shared_dependencies import get_current_user

    _fastapi_app.dependency_overrides[get_current_user] = lambda: seeded_author
    try:
        response = await async_client.post(
            "/api/v1/not-an-integer/post",
            json=_VALID_BODY,
        )
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 422, response.text


# ── F11: old username route gone → 422 ───────────────────────────────────────


async def test_create_post_old_username_route_returns_422(
    async_client: AsyncClient,
    seeded_author: dict,
) -> None:
    """F11 — the author's username string in the path → 422 (route is now int-typed)."""
    from app.main import app as _fastapi_app
    from app.shared_dependencies import get_current_user

    _fastapi_app.dependency_overrides[get_current_user] = lambda: seeded_author
    try:
        response = await async_client.post(
            f"/api/v1/{seeded_author['username']}/post",
            json=_VALID_BODY,
        )
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 422, response.text


# ── F4: invalid body → 422 ───────────────────────────────────────────────────


async def test_create_post_returns_422_for_invalid_body(
    async_client: AsyncClient,
    seeded_author: dict,
) -> None:
    """F4 — empty title and an extra field both violate the request schema → 422."""
    from app.main import app as _fastapi_app
    from app.shared_dependencies import get_current_user

    _fastapi_app.dependency_overrides[get_current_user] = lambda: seeded_author
    try:
        response = await async_client.post(
            _ENDPOINT.format(user_id=seeded_author["id"]),
            json={"title": "", "text": "Body", "media_url": None, "rogue": 1},
        )
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 422, response.text
