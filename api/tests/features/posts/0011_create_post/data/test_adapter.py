# FEATURE: create_post — adapter unit tests (real test Postgres).
#
# Covers: F13.
from datetime import datetime

import pytest

from app.features.posts.create_post.data.adapter import CreatePostAdapter
from app.features.posts.create_post.domain.commands import CreatePostInternalCommand
from app.features.posts.create_post.domain.entities import CreatedPost

pytestmark = pytest.mark.asyncio


def _make_adapter() -> CreatePostAdapter:
    from app.bootstrap.container import container as _di_container

    return CreatePostAdapter(session_factory=_di_container.session_factory())


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
