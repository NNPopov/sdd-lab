# FEATURE: create_post_status — adapter unit tests (real test Postgres).
#
# Covers: F1, F2.
from datetime import datetime

import pytest
from sqlalchemy import text

from app.features.posts.create_post.data.adapter import CreatePostAdapter
from app.features.posts.create_post.domain.commands import CreatePostInternalCommand
from app.features.posts.create_post.domain.entities import CreatedPost

pytestmark = pytest.mark.asyncio


def _make_adapter() -> CreatePostAdapter:
    from app.bootstrap.container import container as _di_container

    return CreatePostAdapter(session_factory=_di_container.session_factory())


async def test_create_returns_created_post_with_status(
    seeded_alice: dict,
) -> None:
    """F1, F2 — create() returns CreatedPost with status=pending_review and the DB row matches."""
    adapter = _make_adapter()
    command = CreatePostInternalCommand(
        created_by_user_id=seeded_alice["id"],
        title="Status Test Post",
        text="Checking status field.",
        media_url=None,
    )
    result = await adapter.create(command)

    assert isinstance(result, CreatedPost)
    assert result.status == "pending_review"
    assert result.title == "Status Test Post"
    assert result.created_by_user_id == seeded_alice["id"]
    assert isinstance(result.id, int)
    assert isinstance(result.created_at, datetime)

    # Confirm the DB row carries status = "pending_review" explicitly (F2).
    from app.bootstrap.container import container as _di_container

    async with _di_container.session_factory()() as session:
        db_result = await session.execute(
            text('SELECT status FROM "post" WHERE id = :post_id'),
            {"post_id": result.id},
        )
        row = db_result.first()
        assert row is not None
        assert row.status == "pending_review"
