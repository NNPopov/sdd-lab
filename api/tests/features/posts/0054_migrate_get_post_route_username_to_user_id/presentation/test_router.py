# FEATURE: migrate_get_post_route_username_to_user_id — endpoint integration tests.
#
# Covers: F1, F2, F3, F4, F5, F6, F7, F8, F9, F10, F15, F16.
# Full HTTP stack against the test Postgres; get_optional_user overridden to
# simulate the authenticated requester.
import pytest
from httpx import AsyncClient

import app.adapters.cache.redis_cache as _cache_module

pytestmark = pytest.mark.asyncio

_ENDPOINT = "/api/v1/{user_id}/post/{id}"


def _url(user_id, post_id: int) -> str:
    return _ENDPOINT.format(user_id=user_id, id=post_id)


async def _seed_user(session_factory, *, username: str, is_moderator: bool = False, is_superuser: bool = False) -> dict:
    from app.adapters.db.models.user import User

    async with session_factory() as session:
        user = User(
            name=f"GP54 {username}",
            username=username,
            email=f"{username}@example.com",
            hashed_password="x",
            is_moderator=is_moderator,
            is_superuser=is_superuser,
        )
        session.add(user)
        await session.commit()
        await session.refresh(user)
        return {
            "id": user.id,
            "username": user.username,
            "is_moderator": user.is_moderator,
            "is_superuser": user.is_superuser,
        }


async def _seed_post(session_factory, *, user_id: int, status: str = "approved") -> object:
    from app.adapters.db.models.post import Post

    async with session_factory() as session:
        post = Post(created_by_user_id=user_id, title="Test Post", text="body", status=status)
        session.add(post)
        await session.commit()
        await session.refresh(post)
        return post


# ── F1/F3/F10: approved post, unauthenticated → 200 ───────────────────────────


async def test_approved_post_returns_200_unauthenticated(async_client: AsyncClient) -> None:
    """F1/F3/F10 — approved post, unauthenticated → 200 with username from the JOIN."""
    from app.bootstrap.container import container as _di_container

    sf = _di_container.session_factory()
    author = await _seed_user(sf, username="gp54rt_alice1")
    post = await _seed_post(sf, user_id=author["id"], status="approved")

    response = await async_client.get(_url(author["id"], post.id))

    assert response.status_code == 200, response.text
    body = response.json()
    assert body["id"] == post.id
    assert body["status"] == "approved"
    assert body["created_by_user_id"] == author["id"]
    assert body["username"] == author["username"]
    for field in ("title", "text", "media_url", "created_at", "post_uuid"):
        assert field in body


# ── F16: cache key is prefixed by user_id ─────────────────────────────────────


async def test_cache_key_is_keyed_by_user_id(async_client: AsyncClient) -> None:
    """F16 — the @cache decorator writes a key beginning with '{user_id}_post_cache:'."""
    from app.bootstrap.container import container as _di_container

    sf = _di_container.session_factory()
    author = await _seed_user(sf, username="gp54rt_cachekey")
    post = await _seed_post(sf, user_id=author["id"], status="approved")

    response = await async_client.get(_url(author["id"], post.id))
    assert response.status_code == 200, response.text

    # On a GET cache miss the decorator writes the result under "<user_id>_post_cache:<post_id>".
    assert _cache_module.client.set.await_args is not None, "expected the cache to be populated"
    written_key = _cache_module.client.set.await_args.args[0]
    assert written_key == f"{author['id']}_post_cache:{post.id}", written_key


# ── F4: non-approved post, author → 200 ───────────────────────────────────────


async def test_pending_post_author_returns_200(async_client: AsyncClient) -> None:
    """F4 — non-approved post, authenticated as the author → 200."""
    from app.bootstrap.container import container as _di_container
    from app.main import app as _fastapi_app
    from app.shared_dependencies import get_optional_user

    sf = _di_container.session_factory()
    author = await _seed_user(sf, username="gp54rt_alice2")
    post = await _seed_post(sf, user_id=author["id"], status="pending")

    _fastapi_app.dependency_overrides[get_optional_user] = lambda: {
        "id": author["id"],
        "username": author["username"],
        "is_superuser": False,
        "is_moderator": False,
    }
    try:
        response = await async_client.get(_url(author["id"], post.id))
    finally:
        del _fastapi_app.dependency_overrides[get_optional_user]

    assert response.status_code == 200, response.text
    assert response.json()["status"] == "pending"


# ── F5: non-approved post, privileged viewers → 200 ───────────────────────────


async def test_pending_post_moderator_returns_200(async_client: AsyncClient) -> None:
    """F5 — non-approved post, moderator (non-author) → 200."""
    from app.bootstrap.container import container as _di_container
    from app.main import app as _fastapi_app
    from app.shared_dependencies import get_optional_user

    sf = _di_container.session_factory()
    author = await _seed_user(sf, username="gp54rt_alice3")
    mod = await _seed_user(sf, username="gp54rt_mod3", is_moderator=True)
    post = await _seed_post(sf, user_id=author["id"], status="pending")

    _fastapi_app.dependency_overrides[get_optional_user] = lambda: mod
    try:
        response = await async_client.get(_url(author["id"], post.id))
    finally:
        del _fastapi_app.dependency_overrides[get_optional_user]

    assert response.status_code == 200, response.text


async def test_pending_post_superuser_returns_200(async_client: AsyncClient) -> None:
    """F5 — non-approved post, superuser (non-author) → 200."""
    from app.bootstrap.container import container as _di_container
    from app.main import app as _fastapi_app
    from app.shared_dependencies import get_optional_user

    sf = _di_container.session_factory()
    author = await _seed_user(sf, username="gp54rt_alice4")
    superuser = await _seed_user(sf, username="gp54rt_su4", is_superuser=True)
    post = await _seed_post(sf, user_id=author["id"], status="pending")

    _fastapi_app.dependency_overrides[get_optional_user] = lambda: superuser
    try:
        response = await async_client.get(_url(author["id"], post.id))
    finally:
        del _fastapi_app.dependency_overrides[get_optional_user]

    assert response.status_code == 200, response.text


# ── F6: non-approved post, non-author non-privileged → 404 ────────────────────


async def test_pending_post_other_user_returns_404(async_client: AsyncClient) -> None:
    """F6 — non-approved post, non-author non-privileged user → 404."""
    from app.bootstrap.container import container as _di_container
    from app.main import app as _fastapi_app
    from app.shared_dependencies import get_optional_user

    sf = _di_container.session_factory()
    author = await _seed_user(sf, username="gp54rt_alice5")
    bob = await _seed_user(sf, username="gp54rt_bob5")
    post = await _seed_post(sf, user_id=author["id"], status="pending")

    _fastapi_app.dependency_overrides[get_optional_user] = lambda: bob
    try:
        response = await async_client.get(_url(author["id"], post.id))
    finally:
        del _fastapi_app.dependency_overrides[get_optional_user]

    assert response.status_code == 404, response.text
    assert response.json() == {"error": {"code": "notfound", "message": "Post not found"}}


async def test_pending_post_unauthenticated_returns_404(async_client: AsyncClient) -> None:
    """F6 — non-approved post, unauthenticated → 404."""
    from app.bootstrap.container import container as _di_container

    sf = _di_container.session_factory()
    author = await _seed_user(sf, username="gp54rt_alice6")
    post = await _seed_post(sf, user_id=author["id"], status="pending")

    response = await async_client.get(_url(author["id"], post.id))
    assert response.status_code == 404, response.text


# ── F7: unknown post id → 404 ─────────────────────────────────────────────────


async def test_unknown_post_id_returns_404(async_client: AsyncClient) -> None:
    """F7 — post id not in DB → 404."""
    from app.bootstrap.container import container as _di_container

    sf = _di_container.session_factory()
    author = await _seed_user(sf, username="gp54rt_alice7")

    response = await async_client.get(_url(author["id"], 99999))
    assert response.status_code == 404, response.text


# ── F8: unknown user_id → 404 (no leak) ───────────────────────────────────────


async def test_unknown_user_id_returns_404(async_client: AsyncClient) -> None:
    """F8 — user_id matches no user → 404, no distinct 'user not found'."""
    response = await async_client.get(_url(999999, 1))
    assert response.status_code == 404, response.text
    assert response.json() == {"error": {"code": "notfound", "message": "Post not found"}}


# ── F2/F9: non-integer user_id → 422 (old string route is gone) ───────────────


async def test_non_integer_user_id_returns_422(async_client: AsyncClient) -> None:
    """F2/F9 — a non-integer author segment cannot bind to int user_id → 422."""
    response = await async_client.get("/api/v1/not-an-integer/post/1")
    assert response.status_code == 422, response.text
