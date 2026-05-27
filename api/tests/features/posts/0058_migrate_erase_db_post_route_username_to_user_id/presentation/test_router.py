# FEATURE: migrate_erase_db_post_route_username_to_user_id — endpoint integration tests.
#
# Covers: F1, F2, F3, F4, F5, F6, F9, F10, F13, F14, F15, F16.
import pytest
from httpx import AsyncClient

pytestmark = pytest.mark.asyncio

_ENDPOINT = "/api/v1/{user_id}/db_post/{id}"


# ── F1, F2, F13, F16: happy path → 200 (superuser deletes another user's post) ─


async def test_erase_db_post_returns_200_for_superuser(
    async_client: AsyncClient,
    edp58_author: dict,
    edp58_superuser: dict,
    edp58_author_post: dict,
) -> None:
    """F1, F2, F13, F16 — superuser DELETEs the author's post by integer id → 200 with the unchanged body."""
    from app.main import app as _fastapi_app
    from app.shared_dependencies import get_current_user

    url = _ENDPOINT.format(user_id=edp58_author["id"], id=edp58_author_post["id"])
    _fastapi_app.dependency_overrides[get_current_user] = lambda: edp58_superuser
    try:
        response = await async_client.delete(url)
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 200, response.text
    assert response.json() == {"message": "Post deleted from the database"}


# ── F14, F15: cache invalidation — read-after-delete returns 404 ──────────────


async def test_erase_db_post_invalidates_cache_so_read_after_delete_is_404(
    async_client: AsyncClient,
    edp58_author: dict,
    edp58_superuser: dict,
    edp58_author_post: dict,
) -> None:
    """F14, F15 — read populates {user_id}_post_cache, the hard delete invalidates it → re-read is 404."""
    from app.main import app as _fastapi_app
    from app.shared_dependencies import get_current_user

    author_id = edp58_author["id"]
    post_id = edp58_author_post["id"]
    url = _ENDPOINT.format(user_id=author_id, id=post_id)
    get_url = f"/api/v1/{author_id}/post/{post_id}"

    first_read = await async_client.get(get_url)
    assert first_read.status_code == 200, first_read.text

    _fastapi_app.dependency_overrides[get_current_user] = lambda: edp58_superuser
    try:
        delete_response = await async_client.delete(url)
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]
    assert delete_response.status_code == 200, delete_response.text

    second_read = await async_client.get(get_url)
    assert second_read.status_code == 404, second_read.text


# ── F4: non-superuser → 403 ───────────────────────────────────────────────────


async def test_erase_db_post_returns_403_for_non_superuser(
    async_client: AsyncClient,
    edp58_author: dict,
    edp58_author_post: dict,
) -> None:
    """F4 — authenticated but not a superuser → 403 from the get_current_superuser gate."""
    from app.main import app as _fastapi_app
    from app.shared_dependencies import get_current_user

    url = _ENDPOINT.format(user_id=edp58_author["id"], id=edp58_author_post["id"])
    _fastapi_app.dependency_overrides[get_current_user] = lambda: edp58_author
    try:
        response = await async_client.delete(url)
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 403, response.text


# ── F5: unknown user_id → 404 (before the post lookup) ───────────────────────


async def test_erase_db_post_returns_404_for_unknown_user(
    async_client: AsyncClient,
    edp58_superuser: dict,
    edp58_author_post: dict,
) -> None:
    """F5 — superuser targets an unknown user_id → 404 'User not found'."""
    from app.main import app as _fastapi_app
    from app.shared_dependencies import get_current_user

    url = _ENDPOINT.format(user_id=999999, id=edp58_author_post["id"])
    _fastapi_app.dependency_overrides[get_current_user] = lambda: edp58_superuser
    try:
        response = await async_client.delete(url)
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 404, response.text
    body = response.json()
    assert body["error"]["code"] == "notfound"
    assert body["error"]["message"] == "User not found"


# ── F6: unknown post → 404 (after the user resolves) ─────────────────────────


async def test_erase_db_post_returns_404_for_unknown_post(
    async_client: AsyncClient,
    edp58_author: dict,
    edp58_superuser: dict,
) -> None:
    """F6 — superuser, valid user_id, unknown post id → 404 'Post not found'."""
    from app.main import app as _fastapi_app
    from app.shared_dependencies import get_current_user

    url = _ENDPOINT.format(user_id=edp58_author["id"], id=999999)
    _fastapi_app.dependency_overrides[get_current_user] = lambda: edp58_superuser
    try:
        response = await async_client.delete(url)
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 404, response.text
    body = response.json()
    assert body["error"]["code"] == "notfound"
    assert body["error"]["message"] == "Post not found"


# ── F3: unauthenticated → 401 ─────────────────────────────────────────────────


async def test_erase_db_post_returns_401_when_unauthenticated(
    async_client: AsyncClient,
    edp58_author: dict,
    edp58_author_post: dict,
) -> None:
    """F3 — no credentials → 401; the use-case is never reached."""
    url = _ENDPOINT.format(user_id=edp58_author["id"], id=edp58_author_post["id"])
    response = await async_client.delete(url)
    assert response.status_code == 401, response.text


# ── F9: non-integer user_id → 422 ────────────────────────────────────────────


async def test_erase_db_post_returns_422_for_non_integer_user_id(
    async_client: AsyncClient,
    edp58_superuser: dict,
    edp58_author_post: dict,
) -> None:
    """F9 — non-integer path segment → 422 (FastAPI path validation)."""
    from app.main import app as _fastapi_app
    from app.shared_dependencies import get_current_user

    _fastapi_app.dependency_overrides[get_current_user] = lambda: edp58_superuser
    try:
        response = await async_client.delete(f"/api/v1/not-an-integer/db_post/{edp58_author_post['id']}")
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 422, response.text


# ── F10: old username route gone → 422 ───────────────────────────────────────


async def test_erase_db_post_old_username_route_returns_422(
    async_client: AsyncClient,
    edp58_author: dict,
    edp58_superuser: dict,
    edp58_author_post: dict,
) -> None:
    """F10 — the author's username string in the path → 422 (route is now int-typed)."""
    from app.main import app as _fastapi_app
    from app.shared_dependencies import get_current_user

    _fastapi_app.dependency_overrides[get_current_user] = lambda: edp58_superuser
    try:
        response = await async_client.delete(f"/api/v1/{edp58_author['username']}/db_post/{edp58_author_post['id']}")
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 422, response.text
