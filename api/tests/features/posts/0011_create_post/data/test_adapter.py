# FEATURE: create_post — adapter unit tests (real test Postgres).
#
# Covers: F10, F11, F12, F13.
from datetime import datetime

import pytest
from httpx import AsyncClient

from app.features.posts._shared.entities import PostAuthor
from app.features.posts.create_post.data.adapter import CreatePostAdapter
from app.features.posts.create_post.domain.commands import CreatePostInternalCommand
from app.features.posts.create_post.domain.entities import CreatedPost

pytestmark = pytest.mark.asyncio


def _make_adapter() -> CreatePostAdapter:
    from app.bootstrap.container import container as _di_container

    return CreatePostAdapter(session_factory=_di_container.session_factory())


# ── F10: active user found ────────────────────────────────────────────────────


async def test_get_user_by_username_returns_post_author_for_active_user(
    seeded_alice: dict,
) -> None:
    """F10 — existing active user row → PostAuthor with correct id and username."""
    adapter = _make_adapter()
    author = await adapter.get_user_by_username("alice")
    assert isinstance(author, PostAuthor)
    assert author.username == "alice"
    assert author.id == seeded_alice["id"]


# ── F11: unknown username ─────────────────────────────────────────────────────


async def test_get_user_by_username_returns_none_for_unknown(
    async_client: AsyncClient,
) -> None:
    """F11 — no matching row → None."""
    adapter = _make_adapter()
    result = await adapter.get_user_by_username("does_not_exist_xyz")
    assert result is None


# ── F12: soft-deleted user ────────────────────────────────────────────────────


async def test_get_user_by_username_returns_none_for_soft_deleted(
    async_client: AsyncClient,
) -> None:
    """F12 — user row with is_deleted=True → None."""
    from app.adapters.db.models.user import User
    from app.bootstrap.container import container as _di_container

    async with _di_container.session_factory()() as session:
        user = User(
            name="Deleted Person",
            username="deleted_user_abc",
            email="deleted_abc@example.com",
            hashed_password="fake",
            is_deleted=True,
        )
        session.add(user)
        await session.commit()

    adapter = _make_adapter()
    result = await adapter.get_user_by_username("deleted_user_abc")
    assert result is None


# ── F13: create returns CreatedPost ──────────────────────────────────────────


async def test_create_returns_created_post_with_correct_fields(
    seeded_alice: dict,
) -> None:
    """F13 — create inserts post and returns CreatedPost with all required fields."""
    adapter = _make_adapter()
    command = CreatePostInternalCommand(
        created_by_user_id=seeded_alice["id"],
        title="Test Title",
        text="Test body content.",
        media_url=None,
    )
    result = await adapter.create(command)

    assert isinstance(result, CreatedPost)
    assert result.title == "Test Title"
    assert result.text == "Test body content."
    assert result.media_url is None
    assert result.created_by_user_id == seeded_alice["id"]
    assert isinstance(result.id, int)
    assert isinstance(result.created_at, datetime)
