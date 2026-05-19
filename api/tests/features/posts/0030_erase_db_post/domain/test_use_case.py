# FEATURE: erase_db_post — use-case unit tests.
#
# Covers: F2, F3, F4.
from unittest.mock import AsyncMock, MagicMock

import pytest

from app.domain.errors import NotFoundDomainError
from app.features.posts._shared.entities import PostAuthor
from app.features.posts.erase_db_post.domain.commands import EraseDbPostCommand
from app.features.posts.erase_db_post.domain.entities import EraseDbPostRecord
from app.features.posts.erase_db_post.domain.use_case import EraseDbPostUseCase

_AUTHOR = PostAuthor(id=1, username="alice")
_POST = EraseDbPostRecord(id=10)
_CMD = EraseDbPostCommand(username="alice", post_id=10)


def _make_port(
    *,
    author: PostAuthor | None = _AUTHOR,
    post: EraseDbPostRecord | None = _POST,
) -> MagicMock:
    port = MagicMock()
    port.get_user_by_username = AsyncMock(return_value=author)
    port.find_post = AsyncMock(return_value=post)
    port.hard_delete = AsyncMock(return_value=None)
    return port


# ── F2: user not found ────────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_raises_not_found_when_user_missing() -> None:
    """F2 — get_user_by_username returns None → NotFoundDomainError('User not found')."""
    use_case = EraseDbPostUseCase(port=_make_port(author=None))  # type: ignore[arg-type]
    with pytest.raises(NotFoundDomainError) as exc_info:
        await use_case(_CMD)
    assert exc_info.value.message == "User not found"


# ── F3: post not found ────────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_raises_not_found_when_post_missing() -> None:
    """F3 — user found, find_post returns None → NotFoundDomainError('Post not found')."""
    use_case = EraseDbPostUseCase(port=_make_port(post=None))  # type: ignore[arg-type]
    with pytest.raises(NotFoundDomainError) as exc_info:
        await use_case(_CMD)
    assert exc_info.value.message == "Post not found"


# ── F4: happy path ────────────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_happy_path_calls_hard_delete_once() -> None:
    """F4 — all checks pass → port.hard_delete called exactly once with post_id."""
    port = _make_port()
    use_case = EraseDbPostUseCase(port=port)  # type: ignore[arg-type]
    await use_case(_CMD)
    port.hard_delete.assert_called_once_with(_CMD.post_id)
