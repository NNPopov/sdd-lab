# FEATURE: migrate_update_post_route_username_to_user_id — endpoint integration tests.
#
# Covers: F1, F2, F3, F4, F5, F6, F7, F10, F11, F14, F15, F16, F17.
import pytest
from httpx import AsyncClient

pytestmark = pytest.mark.asyncio

_ENDPOINT = "/api/v1/{user_id}/post/{id}"


# ── F1, F3, F14: happy path → 200 ────────────────────────────────────────────


async def test_update_post_returns_200_for_owner(
    async_client: AsyncClient,
    up56_alice: dict,
    up56_alice_post: dict,
) -> None:
    """F1, F3, F14 — owner PATCHes own post by integer id → 200 {'message': 'Post updated'}."""
    from app.main import app as _fastapi_app
    from app.shared_dependencies import get_current_user

    url = _ENDPOINT.format(user_id=up56_alice["id"], id=up56_alice_post["id"])
    _fastapi_app.dependency_overrides[get_current_user] = lambda: up56_alice
    try:
        response = await async_client.patch(url, json={"title": "Changed title"})
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 200, response.text
    assert response.json() == {"message": "Post updated"}


# ── F15, F16: cache invalidation — read-after-update returns fresh content ────


async def test_update_post_invalidates_cache_so_read_is_fresh(
    async_client: AsyncClient,
    up56_alice: dict,
    up56_alice_post: dict,
) -> None:
    """F15, F16 — read populates {user_id}_post_cache, update invalidates it → re-read is fresh."""
    from app.main import app as _fastapi_app
    from app.shared_dependencies import get_current_user

    alice_id = up56_alice["id"]
    post_id = up56_alice_post["id"]
    url = _ENDPOINT.format(user_id=alice_id, id=post_id)
    get_url = f"/api/v1/{alice_id}/post/{post_id}"

    # Populate the read cache first.
    first_read = await async_client.get(get_url)
    assert first_read.status_code == 200, first_read.text
    assert first_read.json()["title"] == "Original title"

    _fastapi_app.dependency_overrides[get_current_user] = lambda: up56_alice
    try:
        patch_response = await async_client.patch(url, json={"title": "Fresh title"})
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]
    assert patch_response.status_code == 200, patch_response.text

    second_read = await async_client.get(get_url)
    assert second_read.status_code == 200, second_read.text
    assert second_read.json()["title"] == "Fresh title"


# ── F6, F17: ownership mismatch → bare 403 ────────────────────────────────────


async def test_update_post_returns_403_for_non_owner(
    async_client: AsyncClient,
    up56_alice: dict,
    up56_bob: dict,
    up56_alice_post: dict,
) -> None:
    """F6, F17 — a different user targets the author's id → bare 403 (no ownership message)."""
    from app.main import app as _fastapi_app
    from app.shared_dependencies import get_current_user

    url = _ENDPOINT.format(user_id=up56_alice["id"], id=up56_alice_post["id"])
    _fastapi_app.dependency_overrides[get_current_user] = lambda: up56_bob
    try:
        response = await async_client.patch(url, json={"title": "Hijacked title"})
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 403, response.text
    assert response.json() == {"error": {"code": "forbidden", "message": ""}}
    assert "You can only update your own posts" not in response.text


# ── F5: unknown user_id → 404 (before ownership) ─────────────────────────────


async def test_update_post_returns_404_for_unknown_user(
    async_client: AsyncClient,
    up56_alice: dict,
    up56_alice_post: dict,
) -> None:
    """F5 — target an unknown user_id → NotFoundDomainError → 404 'User not found'."""
    from app.main import app as _fastapi_app
    from app.shared_dependencies import get_current_user

    url = _ENDPOINT.format(user_id=999999, id=up56_alice_post["id"])
    _fastapi_app.dependency_overrides[get_current_user] = lambda: up56_alice
    try:
        response = await async_client.patch(url, json={"title": "Any title"})
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 404, response.text
    body = response.json()
    assert body["error"]["code"] == "notfound"
    assert body["error"]["message"] == "User not found"


# ── F7: unknown post → 404 ────────────────────────────────────────────────────


async def test_update_post_returns_404_for_unknown_post(
    async_client: AsyncClient,
    up56_alice: dict,
) -> None:
    """F7 — owner targets an unknown post id → 404 'Post not found'."""
    from app.main import app as _fastapi_app
    from app.shared_dependencies import get_current_user

    url = _ENDPOINT.format(user_id=up56_alice["id"], id=999999)
    _fastapi_app.dependency_overrides[get_current_user] = lambda: up56_alice
    try:
        response = await async_client.patch(url, json={"title": "Any title"})
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 404, response.text
    body = response.json()
    assert body["error"]["code"] == "notfound"
    assert body["error"]["message"] == "Post not found"


# ── F4: unauthenticated → 401 ─────────────────────────────────────────────────


async def test_update_post_returns_401_when_unauthenticated(
    async_client: AsyncClient,
    up56_alice: dict,
    up56_alice_post: dict,
) -> None:
    """F4 — no credentials → 401; the use-case is never reached."""
    url = _ENDPOINT.format(user_id=up56_alice["id"], id=up56_alice_post["id"])
    response = await async_client.patch(url, json={"title": "Any title"})
    assert response.status_code == 401, response.text


# ── F10: non-integer user_id → 422 ───────────────────────────────────────────


async def test_update_post_returns_422_for_non_integer_user_id(
    async_client: AsyncClient,
    up56_alice: dict,
    up56_alice_post: dict,
) -> None:
    """F10 — non-integer path segment → 422 (path validation)."""
    from app.main import app as _fastapi_app
    from app.shared_dependencies import get_current_user

    _fastapi_app.dependency_overrides[get_current_user] = lambda: up56_alice
    try:
        response = await async_client.patch(
            f"/api/v1/not-an-integer/post/{up56_alice_post['id']}",
            json={"title": "Any title"},
        )
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 422, response.text


# ── F11: old username route gone → 422 ───────────────────────────────────────


async def test_update_post_old_username_route_returns_422(
    async_client: AsyncClient,
    up56_alice: dict,
    up56_alice_post: dict,
) -> None:
    """F11 — the author's username string in the path → 422 (route is now int-typed)."""
    from app.main import app as _fastapi_app
    from app.shared_dependencies import get_current_user

    _fastapi_app.dependency_overrides[get_current_user] = lambda: up56_alice
    try:
        response = await async_client.patch(
            f"/api/v1/{up56_alice['username']}/post/{up56_alice_post['id']}",
            json={"title": "Any title"},
        )
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 422, response.text


# ── F2: invalid body → 422 ────────────────────────────────────────────────────


async def test_update_post_returns_422_for_invalid_body(
    async_client: AsyncClient,
    up56_alice: dict,
    up56_alice_post: dict,
) -> None:
    """F2 — a too-short title and an extra field both violate the request schema → 422."""
    from app.main import app as _fastapi_app
    from app.shared_dependencies import get_current_user

    url = _ENDPOINT.format(user_id=up56_alice["id"], id=up56_alice_post["id"])
    _fastapi_app.dependency_overrides[get_current_user] = lambda: up56_alice
    try:
        response = await async_client.patch(url, json={"title": "x", "rogue": 1})
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 422, response.text
