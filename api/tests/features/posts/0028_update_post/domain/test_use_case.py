# FEATURE: update_post — use-case unit tests.
#
# Covers: F3, F4, F5, F6 (updated for the {user_id} migration — slice 0056).
import uuid
from datetime import UTC, datetime
from unittest.mock import AsyncMock, MagicMock

import pytest

from app.domain.errors import ForbiddenDomainError, NotFoundDomainError
from app.features.posts._shared.entities import PostItem, UserIdentity
from app.features.posts.update_post.domain.commands import UpdatePostCommand
from app.features.posts.update_post.domain.use_case import UpdatePostUseCase

_AUTHOR = UserIdentity(id=1, username="alice")
_POST = PostItem(
    id=10,
    title="Original title",
    text="Original text.",
    media_url=None,
    created_at=datetime(2025, 1, 1, tzinfo=UTC),
    created_by_user_id=1,
    username="alice",
    status="approved",
    post_uuid=uuid.UUID("00000000-0000-0000-0000-000000000001"),
)
_CMD = UpdatePostCommand(
    target_user_id=1,
    requester_user_id=1,
    post_id=10,
    title="Updated title",
)


def _make_port(*, post: PostItem | None = _POST) -> MagicMock:
    port = MagicMock()
    port.get_post_by_id = AsyncMock(return_value=post)
    port.update = AsyncMock(return_value=None)
    return port


def _make_user_lookup(*, author: UserIdentity | None = _AUTHOR) -> MagicMock:
    user_lookup = MagicMock()
    user_lookup.get_active_user_by_id = AsyncMock(return_value=author)
    return user_lookup


# ── F3: user not found ────────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_raises_not_found_when_user_missing() -> None:
    """F3 — get_active_user_by_id returns None → NotFoundDomainError('User not found')."""
    use_case = UpdatePostUseCase(port=_make_port(), user_lookup=_make_user_lookup(author=None))  # type: ignore[arg-type]
    with pytest.raises(NotFoundDomainError) as exc_info:
        await use_case(_CMD)
    assert exc_info.value.message == "User not found"


# ── F4: ownership mismatch ────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_raises_forbidden_when_requester_differs() -> None:
    """F4 — requester_user_id != author.id → bare ForbiddenDomainError; update not called."""
    cmd = UpdatePostCommand(
        target_user_id=1,
        requester_user_id=2,
        post_id=10,
        title="Hijacked title",
    )
    port = _make_port()
    use_case = UpdatePostUseCase(port=port, user_lookup=_make_user_lookup())  # type: ignore[arg-type]
    with pytest.raises(ForbiddenDomainError) as exc_info:
        await use_case(cmd)
    assert exc_info.value.message == ""
    port.update.assert_not_called()


# ── F5: post not found ────────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_raises_not_found_when_post_missing() -> None:
    """F5 — get_post_by_id returns None → NotFoundDomainError('Post not found')."""
    use_case = UpdatePostUseCase(port=_make_port(post=None), user_lookup=_make_user_lookup())  # type: ignore[arg-type]
    with pytest.raises(NotFoundDomainError) as exc_info:
        await use_case(_CMD)
    assert exc_info.value.message == "Post not found"


# ── F6: happy path ────────────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_happy_path_calls_update() -> None:
    """F6 — all checks pass → port.update called once with the command."""
    port = _make_port()
    use_case = UpdatePostUseCase(port=port, user_lookup=_make_user_lookup())  # type: ignore[arg-type]
    await use_case(_CMD)
    port.update.assert_called_once_with(_CMD)
