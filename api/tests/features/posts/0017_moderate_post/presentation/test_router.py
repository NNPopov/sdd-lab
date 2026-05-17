# FEATURE: moderate_post — endpoint integration tests.
#
# Covers: F1, F2, F3, F4, F5, F7, F8, F9, F17, F18.
import uuid

import pytest
from httpx import AsyncClient

pytestmark = pytest.mark.asyncio

_ENDPOINT = "/api/v1/posts/{post_uuid}/moderate"


# ── F4: no auth → 401 ────────────────────────────────────────────────────────


async def test_no_auth_returns_401(
    async_client: AsyncClient,
    seeded_pending_post: dict,
) -> None:
    """F4 — missing Authorization header → 401."""
    response = await async_client.post(
        _ENDPOINT.format(post_uuid=seeded_pending_post["uuid"]),
        json={"action": "approved"},
    )
    assert response.status_code == 401


# ── F5: unprivileged user → 403 ──────────────────────────────────────────────


async def test_unprivileged_user_returns_403(
    async_client: AsyncClient,
    seeded_pending_post: dict,
    seeded_post_author: dict,
) -> None:
    """F5 — authenticated user with no moderator/superuser privileges → 403."""
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    _fastapi_app.dependency_overrides[get_current_user] = lambda: seeded_post_author
    try:
        response = await async_client.post(
            _ENDPOINT.format(post_uuid=seeded_pending_post["uuid"]),
            json={"action": "approved"},
        )
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 403


# ── F8: self-review → 403 ────────────────────────────────────────────────────


async def test_self_review_returns_403(
    async_client: AsyncClient,
    seeded_moderator: dict,
) -> None:
    """F8 — moderator tries to approve their own post → 403."""
    from app.adapters.db.models.post import Post
    from app.bootstrap.container import container as _di_container
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    async with _di_container.session_factory()() as session:
        post = Post(
            created_by_user_id=seeded_moderator["id"],
            title="Own Post",
            text="The moderator's own post.",
        )
        session.add(post)
        await session.commit()
        await session.refresh(post)
        own_post_uuid = post.uuid

    _fastapi_app.dependency_overrides[get_current_user] = lambda: seeded_moderator
    try:
        response = await async_client.post(
            _ENDPOINT.format(post_uuid=own_post_uuid),
            json={"action": "approved"},
        )
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 403
    assert response.json()["error"]["message"] == "Moderators may not review their own posts"


# ── F7: post not found → 404 ─────────────────────────────────────────────────


async def test_unknown_post_uuid_returns_404(
    async_client: AsyncClient,
    seeded_moderator: dict,
) -> None:
    """F7 — UUID not in DB → NotFoundDomainError → 404."""
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    _fastapi_app.dependency_overrides[get_current_user] = lambda: seeded_moderator
    try:
        response = await async_client.post(
            _ENDPOINT.format(post_uuid=uuid.uuid4()),
            json={"action": "approved"},
        )
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 404
    assert response.json()["error"]["message"] == "Post not found"


# ── F9: already approved → 409 ────────────────────────────────────────────────


async def test_already_approved_post_returns_409(
    async_client: AsyncClient,
    seeded_moderator: dict,
    seeded_post_author: dict,
) -> None:
    """F9 — post already in 'approved' state → DuplicateValueDomainError → 409."""
    from app.adapters.db.models.post import Post
    from app.bootstrap.container import container as _di_container
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    async with _di_container.session_factory()() as session:
        post = Post(
            created_by_user_id=seeded_post_author["id"],
            title="Already Approved",
            text="This was already approved.",
            status="approved",
        )
        session.add(post)
        await session.commit()
        await session.refresh(post)
        approved_uuid = post.uuid

    _fastapi_app.dependency_overrides[get_current_user] = lambda: seeded_moderator
    try:
        response = await async_client.post(
            _ENDPOINT.format(post_uuid=approved_uuid),
            json={"action": "approved"},
        )
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 409


# ── F3: changes_requested without message → 422 ──────────────────────────────


async def test_changes_requested_without_message_returns_422(
    async_client: AsyncClient,
    seeded_moderator: dict,
    seeded_pending_post: dict,
) -> None:
    """F3 — action='changes_requested' with no message → schema validation → 422."""
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    _fastapi_app.dependency_overrides[get_current_user] = lambda: seeded_moderator
    try:
        response = await async_client.post(
            _ENDPOINT.format(post_uuid=seeded_pending_post["uuid"]),
            json={"action": "changes_requested"},
        )
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 422


# ── F2: invalid action → 422 ─────────────────────────────────────────────────


async def test_invalid_action_returns_422(
    async_client: AsyncClient,
    seeded_moderator: dict,
    seeded_pending_post: dict,
) -> None:
    """F2 — action not in Literal values → schema validation → 422."""
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    _fastapi_app.dependency_overrides[get_current_user] = lambda: seeded_moderator
    try:
        response = await async_client.post(
            _ENDPOINT.format(post_uuid=seeded_pending_post["uuid"]),
            json={"action": "rejected"},
        )
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 422


# ── F1, F17: approve → 200 ────────────────────────────────────────────────────


async def test_approve_returns_200_with_correct_body(
    async_client: AsyncClient,
    seeded_moderator: dict,
    seeded_pending_post: dict,
) -> None:
    """F1, F17 — valid approve request → 200 with correct response body."""
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    _fastapi_app.dependency_overrides[get_current_user] = lambda: seeded_moderator
    try:
        response = await async_client.post(
            _ENDPOINT.format(post_uuid=seeded_pending_post["uuid"]),
            json={"action": "approved"},
        )
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 200
    body = response.json()
    assert str(body["post_uuid"]) == str(seeded_pending_post["uuid"])
    assert body["status"] == "approved"
    assert body["log_entry"]["event_type"] == "moderator_review"
    assert body["log_entry"]["action"] == "approved"
    assert body["log_entry"]["message"] is None
    assert isinstance(body["log_entry"]["id"], int)
    assert "created_at" in body["log_entry"]


# ── F1: changes_requested → 200 ──────────────────────────────────────────────


async def test_changes_requested_returns_200_with_message(
    async_client: AsyncClient,
    seeded_moderator: dict,
    seeded_post_author: dict,
) -> None:
    """F1 — valid changes_requested with message → 200; action and message in log_entry."""
    from app.adapters.db.models.post import Post
    from app.bootstrap.container import container as _di_container
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    async with _di_container.session_factory()() as session:
        post = Post(
            created_by_user_id=seeded_post_author["id"],
            title="Post for CR",
            text="Needs changes.",
        )
        session.add(post)
        await session.commit()
        await session.refresh(post)
        post_uuid = post.uuid

    _fastapi_app.dependency_overrides[get_current_user] = lambda: seeded_moderator
    try:
        response = await async_client.post(
            _ENDPOINT.format(post_uuid=post_uuid),
            json={"action": "changes_requested", "message": "Please fix the intro."},
        )
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 200
    body = response.json()
    assert body["status"] == "changes_requested"
    assert body["log_entry"]["action"] == "changes_requested"
    assert body["log_entry"]["message"] == "Please fix the intro."


# ── F18: superuser (not moderator) can moderate → 200 ────────────────────────


async def test_superuser_without_moderator_flag_can_moderate(
    async_client: AsyncClient,
    seeded_pending_post: dict,
) -> None:
    """F18 — superuser with is_moderator=False can moderate; HTTP 200."""
    from app.adapters.db.models.user import User
    from app.bootstrap.container import container as _di_container
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    async with _di_container.session_factory()() as session:
        superuser = User(
            name="Super User",
            username="superuser_mod_test",
            email="superuser_mod_test@example.com",
            hashed_password="fake_hashed_password",
            is_superuser=True,
        )
        session.add(superuser)
        await session.commit()
        await session.refresh(superuser)
        superuser_dict = {
            "id": superuser.id,
            "username": superuser.username,
            "email": superuser.email,
            "name": superuser.name,
            "is_superuser": superuser.is_superuser,
            "is_moderator": superuser.is_moderator,
        }

    _fastapi_app.dependency_overrides[get_current_user] = lambda: superuser_dict
    try:
        response = await async_client.post(
            _ENDPOINT.format(post_uuid=seeded_pending_post["uuid"]),
            json={"action": "approved"},
        )
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 200
    assert response.json()["status"] == "approved"
