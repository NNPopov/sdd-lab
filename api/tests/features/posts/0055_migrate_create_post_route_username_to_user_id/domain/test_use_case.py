# FEATURE: migrate_create_post_route_username_to_user_id — use-case unit tests.
#
# Covers: F3, F6, F7, F8, F9, F12.
import uuid
from datetime import UTC, datetime
from unittest.mock import AsyncMock, MagicMock

import pytest

from app.domain.errors import ForbiddenDomainError, NotFoundDomainError
from app.features.posts._shared.entities import UserIdentity
from app.features.posts.create_post.domain.commands import (
    CreatePostCommand,
    CreatePostInternalCommand,
)
from app.features.posts.create_post.domain.entities import CreatedPost
from app.features.posts.create_post.domain.use_case import CreatePostUseCase

_AUTHOR = UserIdentity(id=42, username="gp55alice")
_CMD = CreatePostCommand(
    target_user_id=42,
    requester_user_id=42,
    title="Hello",
    text="World",
    media_url=None,
)
_CREATED_POST = CreatedPost(
    id=1,
    title="Hello",
    text="World",
    media_url=None,
    created_by_user_id=42,
    created_at=datetime(2025, 1, 1, tzinfo=UTC),
    status="pending_review",
    post_uuid=uuid.UUID("00000000-0000-0000-0000-000000000001"),
)


def _make_port(*, created: CreatedPost = _CREATED_POST) -> MagicMock:
    port = MagicMock()
    port.create = AsyncMock(return_value=created)
    return port


def _make_user_lookup(*, author: UserIdentity | None = _AUTHOR) -> MagicMock:
    user_lookup = MagicMock()
    user_lookup.get_active_user_by_id = AsyncMock(return_value=author)
    return user_lookup


# ── F3, F9: happy path (owner) ────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_happy_path_calls_create_with_internal_command() -> None:
    """F3, F9 — owner resolves → port.create called with created_by_user_id=author.id."""
    port = _make_port()
    use_case = CreatePostUseCase(port=port, user_lookup=_make_user_lookup())  # type: ignore[arg-type]
    result = await use_case(_CMD)

    port.create.assert_called_once()
    internal: CreatePostInternalCommand = port.create.call_args[0][0]
    assert internal.created_by_user_id == _AUTHOR.id
    assert internal.created_by_user_id == _CMD.target_user_id
    assert internal.title == _CMD.title
    assert internal.text == _CMD.text
    assert internal.media_url == _CMD.media_url
    assert result == _CREATED_POST


# ── F6, F8, F9: user not found → 404 before any ownership check ───────────────


@pytest.mark.asyncio
async def test_raises_not_found_when_user_missing() -> None:
    """F6, F8, F9 — get_active_user_by_id returns None → NotFoundDomainError; create not called."""
    port = _make_port()
    use_case = CreatePostUseCase(port=port, user_lookup=_make_user_lookup(author=None))  # type: ignore[arg-type]
    with pytest.raises(NotFoundDomainError) as exc_info:
        await use_case(_CMD)
    assert exc_info.value.message == "User not found"
    port.create.assert_not_called()


# ── F7, F9: not owner → bare 403 ──────────────────────────────────────────────


@pytest.mark.asyncio
async def test_raises_forbidden_when_requester_is_not_author() -> None:
    """F7, F9 — requester_user_id != author.id → bare ForbiddenDomainError; create not called."""
    cmd = CreatePostCommand(
        target_user_id=42,
        requester_user_id=99,
        title="Hello",
        text="World",
        media_url=None,
    )
    port = _make_port()
    use_case = CreatePostUseCase(port=port, user_lookup=_make_user_lookup())  # type: ignore[arg-type]
    with pytest.raises(ForbiddenDomainError) as exc_info:
        await use_case(cmd)
    assert exc_info.value.message == ""
    port.create.assert_not_called()
