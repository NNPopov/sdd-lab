# FEATURE: erase_post — use-case unit tests.
#
# Covers: F3, F4, F5, F6 (updated for the {user_id} migration — slice 0057).
from unittest.mock import AsyncMock, MagicMock

import pytest

from app.domain.errors import ForbiddenDomainError, NotFoundDomainError
from app.features.posts._shared.entities import UserIdentity
from app.features.posts.erase_post.domain.commands import ErasePostCommand
from app.features.posts.erase_post.domain.entities import ErasePostRecord
from app.features.posts.erase_post.domain.use_case import ErasePostUseCase

_AUTHOR = UserIdentity(id=1, username="alice")
_POST = ErasePostRecord(id=10)
_CMD = ErasePostCommand(user_id=1, post_id=10, requester_user_id=1)


def _make_port(*, post: ErasePostRecord | None = _POST) -> MagicMock:
    port = MagicMock()
    port.find_post = AsyncMock(return_value=post)
    port.soft_delete = AsyncMock(return_value=None)
    return port


def _make_user_lookup(*, author: UserIdentity | None = _AUTHOR) -> MagicMock:
    user_lookup = MagicMock()
    user_lookup.get_active_user_by_id = AsyncMock(return_value=author)
    return user_lookup


# ── F3: user not found ────────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_raises_not_found_when_user_missing() -> None:
    """F3 — get_active_user_by_id returns None → NotFoundDomainError('User not found')."""
    use_case = ErasePostUseCase(port=_make_port(), user_lookup=_make_user_lookup(author=None))  # type: ignore[arg-type]
    with pytest.raises(NotFoundDomainError) as exc_info:
        await use_case(_CMD)
    assert exc_info.value.message == "User not found"


# ── F4: ownership mismatch ────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_raises_forbidden_when_requester_differs() -> None:
    """F4 — requester_user_id != user.id → ForbiddenDomainError; soft_delete not called."""
    cmd = ErasePostCommand(user_id=1, post_id=10, requester_user_id=2)
    port = _make_port()
    use_case = ErasePostUseCase(port=port, user_lookup=_make_user_lookup())  # type: ignore[arg-type]
    with pytest.raises(ForbiddenDomainError):
        await use_case(cmd)
    port.soft_delete.assert_not_called()


# ── F5: post not found ────────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_raises_not_found_when_post_missing() -> None:
    """F5 — find_post returns None → NotFoundDomainError('Post not found')."""
    use_case = ErasePostUseCase(port=_make_port(post=None), user_lookup=_make_user_lookup())  # type: ignore[arg-type]
    with pytest.raises(NotFoundDomainError) as exc_info:
        await use_case(_CMD)
    assert exc_info.value.message == "Post not found"


# ── F6: happy path ────────────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_happy_path_calls_soft_delete_once() -> None:
    """F6 — all checks pass → port.soft_delete called exactly once with post_id."""
    port = _make_port()
    use_case = ErasePostUseCase(port=port, user_lookup=_make_user_lookup())  # type: ignore[arg-type]
    await use_case(_CMD)
    port.soft_delete.assert_called_once_with(_CMD.post_id)
