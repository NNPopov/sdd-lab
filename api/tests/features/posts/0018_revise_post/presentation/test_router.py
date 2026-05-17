# FEATURE: revise_post — endpoint integration tests.
#
# Covers: F1, F2, F3, F4, F5, F6, F15.
import uuid

import pytest
from httpx import AsyncClient

pytestmark = pytest.mark.asyncio

_ENDPOINT = "/api/v1/posts/{post_uuid}/revise"


# ── F3: no auth → 401 ────────────────────────────────────────────────────────


async def test_no_auth_returns_401(
    async_client: AsyncClient,
    seeded_changes_requested_post: dict,
) -> None:
    """F3 — missing Authorization header → 401."""
    response = await async_client.patch(
        _ENDPOINT.format(post_uuid=seeded_changes_requested_post["uuid"]),
        json={"title": "New Title"},
    )
    assert response.status_code == 401


# ── F5: ownership guard → 403 ────────────────────────────────────────────────


async def test_other_user_returns_403(
    async_client: AsyncClient,
    seeded_changes_requested_post: dict,
) -> None:
    """F5 — authenticated as a different user than the post author → 403."""
    from app.adapters.db.models.user import User
    from app.bootstrap.container import container as _di_container
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    async with _di_container.session_factory()() as session:
        other = User(
            name="Other User",
            username="otheruser_revise",
            email="other_revise@example.com",
            hashed_password="fake_hashed_password",
        )
        session.add(other)
        await session.commit()
        await session.refresh(other)
        other_dict = {
            "id": other.id,
            "username": other.username,
            "email": other.email,
            "name": other.name,
            "is_superuser": other.is_superuser,
            "is_moderator": other.is_moderator,
        }

    _fastapi_app.dependency_overrides[get_current_user] = lambda: other_dict
    try:
        response = await async_client.patch(
            _ENDPOINT.format(post_uuid=seeded_changes_requested_post["uuid"]),
            json={"title": "Stolen revision"},
        )
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 403
    assert response.json()["error"]["message"] == "You may only revise your own posts"


# ── F6: status guard — pending_review → 403 ───────────────────────────────────


async def test_pending_review_post_returns_403(
    async_client: AsyncClient,
    seeded_revise_author: dict,
    seeded_pending_review_post: dict,
) -> None:
    """F6 — post in 'pending_review' → ForbiddenDomainError → 403."""
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    _fastapi_app.dependency_overrides[get_current_user] = lambda: seeded_revise_author
    try:
        response = await async_client.patch(
            _ENDPOINT.format(post_uuid=seeded_pending_review_post["uuid"]),
            json={"title": "Attempted revision"},
        )
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 403
    assert response.json()["error"]["message"] == "Post is not in changes_requested status"


# ── F6: status guard — approved → 403 ────────────────────────────────────────


async def test_approved_post_returns_403(
    async_client: AsyncClient,
    seeded_revise_author: dict,
) -> None:
    """F6 — post in 'approved' status → ForbiddenDomainError → 403."""
    from app.adapters.db.models.post import Post
    from app.bootstrap.container import container as _di_container
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    async with _di_container.session_factory()() as session:
        post = Post(
            created_by_user_id=seeded_revise_author["id"],
            title="Approved Post",
            text="Already approved.",
            status="approved",
        )
        session.add(post)
        await session.commit()
        await session.refresh(post)
        approved_uuid = post.uuid

    _fastapi_app.dependency_overrides[get_current_user] = lambda: seeded_revise_author
    try:
        response = await async_client.patch(
            _ENDPOINT.format(post_uuid=approved_uuid),
            json={"title": "Trying to revise"},
        )
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 403
    assert response.json()["error"]["message"] == "Post is not in changes_requested status"


# ── F4: non-existent UUID → 404 ───────────────────────────────────────────────


async def test_unknown_post_uuid_returns_404(
    async_client: AsyncClient,
    seeded_revise_author: dict,
) -> None:
    """F4 — UUID not in DB → NotFoundDomainError → 404."""
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    _fastapi_app.dependency_overrides[get_current_user] = lambda: seeded_revise_author
    try:
        response = await async_client.patch(
            _ENDPOINT.format(post_uuid=uuid.uuid4()),
            json={"title": "Ghost revision"},
        )
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 404
    assert response.json()["error"]["message"] == "Post not found"


# ── F2: neither title nor text → 422 ─────────────────────────────────────────


async def test_no_title_or_text_returns_422(
    async_client: AsyncClient,
    seeded_revise_author: dict,
    seeded_changes_requested_post: dict,
) -> None:
    """F2 — body {} (neither title nor text) → model_validator fires → 422."""
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    _fastapi_app.dependency_overrides[get_current_user] = lambda: seeded_revise_author
    try:
        response = await async_client.patch(
            _ENDPOINT.format(post_uuid=seeded_changes_requested_post["uuid"]),
            json={},
        )
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 422


# ── F1, F15: 200 — title update ───────────────────────────────────────────────


async def test_revise_title_returns_200(
    async_client: AsyncClient,
    seeded_revise_author: dict,
    seeded_changes_requested_post: dict,
) -> None:
    """F1, F15 — valid title update → 200 with correct response body."""
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    _fastapi_app.dependency_overrides[get_current_user] = lambda: seeded_revise_author
    try:
        response = await async_client.patch(
            _ENDPOINT.format(post_uuid=seeded_changes_requested_post["uuid"]),
            json={"title": "Revised Title"},
        )
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 200
    body = response.json()
    assert str(body["post_uuid"]) == str(seeded_changes_requested_post["uuid"])
    assert body["title"] == "Revised Title"
    assert body["text"] == seeded_changes_requested_post["text"]
    assert body["status"] == "pending_review"
    assert "updated_at" in body
    assert body["log_entry"]["event_type"] == "author_revision"
    assert body["log_entry"]["action"] is None
    assert isinstance(body["log_entry"]["id"], int)
    assert "created_at" in body["log_entry"]


# ── F1, F15: 200 — with message ───────────────────────────────────────────────


async def test_revise_with_message_returns_200(
    async_client: AsyncClient,
    seeded_revise_author: dict,
) -> None:
    """F1, F15 — revision with message → 200; log_entry.message matches."""
    from app.adapters.db.models.post import Post
    from app.bootstrap.container import container as _di_container
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    async with _di_container.session_factory()() as session:
        post = Post(
            created_by_user_id=seeded_revise_author["id"],
            title="Post for message test",
            text="Body content.",
            status="changes_requested",
        )
        session.add(post)
        await session.commit()
        await session.refresh(post)
        post_uuid = post.uuid

    _fastapi_app.dependency_overrides[get_current_user] = lambda: seeded_revise_author
    try:
        response = await async_client.patch(
            _ENDPOINT.format(post_uuid=post_uuid),
            json={"title": "Fixed Title", "message": "I fixed the title as requested."},
        )
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 200
    body = response.json()
    assert body["status"] == "pending_review"
    assert body["log_entry"]["event_type"] == "author_revision"
    assert body["log_entry"]["message"] == "I fixed the title as requested."
