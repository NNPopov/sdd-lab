# FEATURE: create_post — use-case unit tests.
#
# Covers: F7, F8, F9.
import uuid
from datetime import UTC, datetime
from unittest.mock import AsyncMock, MagicMock

import pytest

from app.domain.errors import ForbiddenDomainError, NotFoundDomainError
from app.features.posts._shared.entities import PostAuthor
from app.features.posts.create_post.domain.commands import CreatePostCommand
from app.features.posts.create_post.domain.entities import CreatedPost
from app.features.posts.create_post.domain.use_case import CreatePostUseCase

_AUTHOR = PostAuthor(id=42, username="alice")
_CMD = CreatePostCommand(
    target_username="alice",
    requester_username="alice",
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


def _make_port(*, author: PostAuthor | None = _AUTHOR, created: CreatedPost = _CREATED_POST) -> MagicMock:
    port = MagicMock()
    port.get_user_by_username = AsyncMock(return_value=author)
    port.create = AsyncMock(return_value=created)
    return port


# ── F7: user not found ────────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_raises_not_found_when_user_missing() -> None:
    """F7 — get_user_by_username returns None → NotFoundDomainError."""
    use_case = CreatePostUseCase(port=_make_port(author=None))  # type: ignore[arg-type]
    with pytest.raises(NotFoundDomainError) as exc_info:
        await use_case(_CMD)
    assert exc_info.value.message == "User not found"


# ── F8: ownership mismatch ────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_raises_forbidden_when_requester_differs() -> None:
    """F8 — requester_username != author.username → ForbiddenDomainError; create not called."""
    cmd = CreatePostCommand(
        target_username="alice",
        requester_username="bob",
        title="Hello",
        text="World",
        media_url=None,
    )
    port = _make_port()
    use_case = CreatePostUseCase(port=port)  # type: ignore[arg-type]
    with pytest.raises(ForbiddenDomainError) as exc_info:
        await use_case(cmd)
    assert exc_info.value.message == "You can only post under your own username"
    port.create.assert_not_called()


# ── F9: happy path ────────────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_happy_path_calls_create_with_correct_internal_command() -> None:
    """F9 — all checks pass → port.create called with created_by_user_id=author.id."""
    from app.features.posts.create_post.domain.commands import CreatePostInternalCommand

    port = _make_port()
    use_case = CreatePostUseCase(port=port)  # type: ignore[arg-type]
    result = await use_case(_CMD)

    port.create.assert_called_once()
    internal: CreatePostInternalCommand = port.create.call_args[0][0]
    assert internal.created_by_user_id == _AUTHOR.id
    assert internal.title == _CMD.title
    assert internal.text == _CMD.text
    assert internal.media_url == _CMD.media_url

    assert result == _CREATED_POST
