# FEATURE: get_post — endpoint integration tests.
#
# Covers: F1, F6, F7, F8, F9, F10, F11, F12, F13, F14.
import pytest
from httpx import AsyncClient

pytestmark = pytest.mark.asyncio

_ENDPOINT = "/api/v1/{username}/post/{id}"


def _url(username: str, post_id: int) -> str:
    return _ENDPOINT.format(username=username, id=post_id)


async def _seed_user(session_factory, *, username: str, is_moderator: bool = False, is_superuser: bool = False) -> dict:
    from app.adapters.db.models.user import User

    async with session_factory() as session:
        user = User(
            name=f"GP26 {username}",
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


# ── F1: approved post, unauthenticated → 200 ─────────────────────────────────


async def test_approved_post_returns_200_unauthenticated(async_client: AsyncClient) -> None:
    """F1 — approved post, unauthenticated → 200 with full response body."""
    from app.bootstrap.container import container as _di_container

    sf = _di_container.session_factory()
    author = await _seed_user(sf, username="gp26rt_alice1")
    post = await _seed_post(sf, user_id=author["id"], status="approved")

    response = await async_client.get(_url(author["username"], post.id))

    assert response.status_code == 200
    body = response.json()
    assert body["id"] == post.id
    assert body["status"] == "approved"
    assert body["username"] == author["username"]
    assert "post_uuid" in body
    assert "title" in body
    assert "text" in body


# ── F7: pending post, unauthenticated → 404 ──────────────────────────────────


async def test_pending_post_unauthenticated_returns_404(async_client: AsyncClient) -> None:
    """F7 — pending_review post, no auth → 404."""
    from app.bootstrap.container import container as _di_container

    sf = _di_container.session_factory()
    author = await _seed_user(sf, username="gp26rt_alice2")
    post = await _seed_post(sf, user_id=author["id"], status="pending_review")

    response = await async_client.get(_url(author["username"], post.id))

    assert response.status_code == 404


# ── F9: pending post, author → 200 ───────────────────────────────────────────


async def test_pending_post_author_returns_200(async_client: AsyncClient) -> None:
    """F9 — pending_review post, authenticated as author → 200."""
    from app.bootstrap.container import container as _di_container
    from app.features.users.dependencies import get_optional_user
    from app.main import app as _fastapi_app

    sf = _di_container.session_factory()
    author = await _seed_user(sf, username="gp26rt_alice3")
    post = await _seed_post(sf, user_id=author["id"], status="pending_review")

    _fastapi_app.dependency_overrides[get_optional_user] = lambda: author
    try:
        response = await async_client.get(_url(author["username"], post.id))
    finally:
        del _fastapi_app.dependency_overrides[get_optional_user]

    assert response.status_code == 200
    assert response.json()["status"] == "pending_review"


# ── F8: pending post, different user → 404 ───────────────────────────────────


async def test_pending_post_other_user_returns_404(async_client: AsyncClient) -> None:
    """F8 — pending_review post, non-author non-privileged user → 404."""
    from app.bootstrap.container import container as _di_container
    from app.features.users.dependencies import get_optional_user
    from app.main import app as _fastapi_app

    sf = _di_container.session_factory()
    author = await _seed_user(sf, username="gp26rt_alice4")
    bob = await _seed_user(sf, username="gp26rt_bob4")
    post = await _seed_post(sf, user_id=author["id"], status="pending_review")

    _fastapi_app.dependency_overrides[get_optional_user] = lambda: bob
    try:
        response = await async_client.get(_url(author["username"], post.id))
    finally:
        del _fastapi_app.dependency_overrides[get_optional_user]

    assert response.status_code == 404


# ── F10: pending post, moderator → 200 ───────────────────────────────────────


async def test_pending_post_moderator_returns_200(async_client: AsyncClient) -> None:
    """F10 — pending_review post, moderator authenticated → 200; F14 privilege flag computed."""
    from app.bootstrap.container import container as _di_container
    from app.features.users.dependencies import get_optional_user
    from app.main import app as _fastapi_app

    sf = _di_container.session_factory()
    author = await _seed_user(sf, username="gp26rt_alice5")
    mod = await _seed_user(sf, username="gp26rt_mod5", is_moderator=True)
    post = await _seed_post(sf, user_id=author["id"], status="pending_review")

    _fastapi_app.dependency_overrides[get_optional_user] = lambda: mod
    try:
        response = await async_client.get(_url(author["username"], post.id))
    finally:
        del _fastapi_app.dependency_overrides[get_optional_user]

    assert response.status_code == 200


# ── F11: pending post, superuser → 200 ───────────────────────────────────────


async def test_pending_post_superuser_returns_200(async_client: AsyncClient) -> None:
    """F11 — pending_review post, superuser authenticated → 200; F14 privilege flag computed."""
    from app.bootstrap.container import container as _di_container
    from app.features.users.dependencies import get_optional_user
    from app.main import app as _fastapi_app

    sf = _di_container.session_factory()
    author = await _seed_user(sf, username="gp26rt_alice6")
    superuser = await _seed_user(sf, username="gp26rt_su6", is_superuser=True)
    post = await _seed_post(sf, user_id=author["id"], status="pending_review")

    _fastapi_app.dependency_overrides[get_optional_user] = lambda: superuser
    try:
        response = await async_client.get(_url(author["username"], post.id))
    finally:
        del _fastapi_app.dependency_overrides[get_optional_user]

    assert response.status_code == 200


# ── F12/F13: changes_requested post, visibility matrix ───────────────────────


async def test_changes_requested_post_unauthenticated_returns_404(async_client: AsyncClient) -> None:
    """F12 — changes_requested post, no auth → 404."""
    from app.bootstrap.container import container as _di_container

    sf = _di_container.session_factory()
    author = await _seed_user(sf, username="gp26rt_alice7")
    post = await _seed_post(sf, user_id=author["id"], status="changes_requested")

    response = await async_client.get(_url(author["username"], post.id))

    assert response.status_code == 404


async def test_changes_requested_post_author_returns_200(async_client: AsyncClient) -> None:
    """F13 — changes_requested post, author authenticated → 200."""
    from app.bootstrap.container import container as _di_container
    from app.features.users.dependencies import get_optional_user
    from app.main import app as _fastapi_app

    sf = _di_container.session_factory()
    author = await _seed_user(sf, username="gp26rt_alice8")
    post = await _seed_post(sf, user_id=author["id"], status="changes_requested")

    _fastapi_app.dependency_overrides[get_optional_user] = lambda: author
    try:
        response = await async_client.get(_url(author["username"], post.id))
    finally:
        del _fastapi_app.dependency_overrides[get_optional_user]

    assert response.status_code == 200
    assert response.json()["status"] == "changes_requested"


# ── F6: unknown username → 404 ───────────────────────────────────────────────


async def test_unknown_username_returns_404(async_client: AsyncClient) -> None:
    """F6 — username not in DB → 404."""
    response = await async_client.get(_url("unknown_gp26rt_xyz", 1))
    assert response.status_code == 404


# ── F6: unknown post id → 404 ────────────────────────────────────────────────


async def test_unknown_post_id_returns_404(async_client: AsyncClient) -> None:
    """F6 — post id not in DB → 404."""
    from app.bootstrap.container import container as _di_container

    sf = _di_container.session_factory()
    author = await _seed_user(sf, username="gp26rt_alice9")

    response = await async_client.get(_url(author["username"], 99999))
    assert response.status_code == 404


# ── F6: post id belongs to different user → 404 ──────────────────────────────


async def test_post_id_of_different_user_returns_404(async_client: AsyncClient) -> None:
    """F6 — post exists but belongs to a different user → 404."""
    from app.bootstrap.container import container as _di_container

    sf = _di_container.session_factory()
    alice = await _seed_user(sf, username="gp26rt_alice10")
    bob = await _seed_user(sf, username="gp26rt_bob10")
    post = await _seed_post(sf, user_id=bob["id"], status="approved")

    response = await async_client.get(_url(alice["username"], post.id))
    assert response.status_code == 404
