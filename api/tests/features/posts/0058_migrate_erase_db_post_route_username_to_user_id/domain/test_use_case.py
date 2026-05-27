# FEATURE: migrate_erase_db_post_route_username_to_user_id — use-case unit tests.
#
# Covers: F5, F6, F7, F8, F11, F17.
from unittest.mock import AsyncMock, MagicMock

import pytest

from app.domain.errors import NotFoundDomainError
from app.features.posts._shared.entities import UserIdentity
from app.features.posts.erase_db_post.domain.commands import EraseDbPostCommand
from app.features.posts.erase_db_post.domain.entities import EraseDbPostRecord
from app.features.posts.erase_db_post.domain.use_case import EraseDbPostUseCase

_AUTHOR = UserIdentity(id=42, username="edp58author")
_POST = EraseDbPostRecord(id=10)
_CMD = EraseDbPostCommand(user_id=42, post_id=10)


def _make_port(*, post: EraseDbPostRecord | None = _POST) -> MagicMock:
    port = MagicMock()
    port.find_post = AsyncMock(return_value=post)
    port.hard_delete = AsyncMock(return_value=None)
    return port


def _make_user_lookup(*, author: UserIdentity | None = _AUTHOR) -> MagicMock:
    user_lookup = MagicMock()
    user_lookup.get_active_user_by_id = AsyncMock(return_value=author)
    return user_lookup


# ── F1, F7, F17: happy path — resolve by id, owner-scoped fetch, hard delete ──


@pytest.mark.asyncio
async def test_happy_path_resolves_by_id_and_calls_hard_delete() -> None:
    """F1, F7, F17 — author resolved by id; find_post owner-scoped; hard_delete called once with post_id."""
    port = _make_port()
    user_lookup = _make_user_lookup()
    use_case = EraseDbPostUseCase(port=port, user_lookup=user_lookup)  # type: ignore[arg-type]

    await use_case(_CMD)

    user_lookup.get_active_user_by_id.assert_called_once_with(_CMD.user_id)
    port.find_post.assert_called_once_with(_CMD.post_id, owner_id=_AUTHOR.id)
    port.hard_delete.assert_called_once_with(_CMD.post_id)


# ── F5, F7, F8: user not found → 404 before any post step ─────────────────────


@pytest.mark.asyncio
async def test_raises_not_found_when_user_missing() -> None:
    """F5, F7, F8 — user lookup None → NotFound('User not found'); post not fetched, hard_delete not called."""
    port = _make_port()
    use_case = EraseDbPostUseCase(port=port, user_lookup=_make_user_lookup(author=None))  # type: ignore[arg-type]

    with pytest.raises(NotFoundDomainError) as exc_info:
        await use_case(_CMD)

    assert exc_info.value.message == "User not found"
    port.find_post.assert_not_called()
    port.hard_delete.assert_not_called()


# ── F6, F8: post not found / not owned → 404 after the user resolves ──────────


@pytest.mark.asyncio
async def test_raises_not_found_when_post_missing() -> None:
    """F6, F8 — find_post returns None → NotFoundDomainError('Post not found'); hard_delete never called."""
    port = _make_port(post=None)
    use_case = EraseDbPostUseCase(port=port, user_lookup=_make_user_lookup())  # type: ignore[arg-type]

    with pytest.raises(NotFoundDomainError) as exc_info:
        await use_case(_CMD)

    assert exc_info.value.message == "Post not found"
    port.find_post.assert_called_once_with(_CMD.post_id, owner_id=_AUTHOR.id)
    port.hard_delete.assert_not_called()
