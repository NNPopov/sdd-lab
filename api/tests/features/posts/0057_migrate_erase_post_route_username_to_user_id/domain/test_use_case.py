# FEATURE: migrate_erase_post_route_username_to_user_id — use-case unit tests.
#
# Covers: F4, F5, F6, F7, F8, F11, F17, F18.
from unittest.mock import AsyncMock, MagicMock

import pytest

from app.domain.errors import ForbiddenDomainError, NotFoundDomainError
from app.features.posts._shared.entities import UserIdentity
from app.features.posts.erase_post.domain.commands import ErasePostCommand
from app.features.posts.erase_post.domain.entities import ErasePostRecord
from app.features.posts.erase_post.domain.use_case import ErasePostUseCase

_AUTHOR = UserIdentity(id=42, username="ep57alice")
_POST = ErasePostRecord(id=10)
_CMD = ErasePostCommand(user_id=42, post_id=10, requester_user_id=42)


def _make_port(*, post: ErasePostRecord | None = _POST) -> MagicMock:
    port = MagicMock()
    port.find_post = AsyncMock(return_value=post)
    port.soft_delete = AsyncMock(return_value=None)
    return port


def _make_user_lookup(*, author: UserIdentity | None = _AUTHOR) -> MagicMock:
    user_lookup = MagicMock()
    user_lookup.get_active_user_by_id = AsyncMock(return_value=author)
    return user_lookup


# ── F6, F17, F18: happy path (owner) ──────────────────────────────────────────


@pytest.mark.asyncio
async def test_happy_path_resolves_by_id_and_calls_soft_delete() -> None:
    """F6, F17, F18 — author resolved by id, ownership passes → soft_delete called once with post_id."""
    port = _make_port()
    user_lookup = _make_user_lookup()
    use_case = ErasePostUseCase(port=port, user_lookup=user_lookup)  # type: ignore[arg-type]

    await use_case(_CMD)

    user_lookup.get_active_user_by_id.assert_called_once_with(_CMD.user_id)
    port.find_post.assert_called_once_with(_CMD.post_id, owner_id=_AUTHOR.id)
    port.soft_delete.assert_called_once_with(_CMD.post_id)


# ── F4, F7, F8: user not found → 404 before any ownership/post step ───────────


@pytest.mark.asyncio
async def test_raises_not_found_when_user_missing() -> None:
    """F4, F7, F8 — user lookup None → NotFoundDomainError; post not fetched, soft_delete not called."""
    port = _make_port()
    use_case = ErasePostUseCase(port=port, user_lookup=_make_user_lookup(author=None))  # type: ignore[arg-type]

    with pytest.raises(NotFoundDomainError) as exc_info:
        await use_case(_CMD)

    assert exc_info.value.message == "User not found"
    port.find_post.assert_not_called()
    port.soft_delete.assert_not_called()


# ── F5, F8, F16: not owner → bare 403 ─────────────────────────────────────────


@pytest.mark.asyncio
async def test_raises_forbidden_when_requester_is_not_author() -> None:
    """F5, F8, F16 — requester != author.id → bare ForbiddenDomainError; post not fetched, soft_delete not called."""
    cmd = ErasePostCommand(user_id=42, post_id=10, requester_user_id=99)
    port = _make_port()
    use_case = ErasePostUseCase(port=port, user_lookup=_make_user_lookup())  # type: ignore[arg-type]

    with pytest.raises(ForbiddenDomainError) as exc_info:
        await use_case(cmd)

    assert exc_info.value.message == ""
    port.find_post.assert_not_called()
    port.soft_delete.assert_not_called()


# ── F6, F8, F18: post not found → 404 after ownership passes ──────────────────


@pytest.mark.asyncio
async def test_raises_not_found_when_post_missing() -> None:
    """F6, F8, F18 — find_post returns None → NotFoundDomainError('Post not found'); soft_delete never called."""
    port = _make_port(post=None)
    use_case = ErasePostUseCase(port=port, user_lookup=_make_user_lookup())  # type: ignore[arg-type]

    with pytest.raises(NotFoundDomainError) as exc_info:
        await use_case(_CMD)

    assert exc_info.value.message == "Post not found"
    port.find_post.assert_called_once_with(_CMD.post_id, owner_id=_AUTHOR.id)
    port.soft_delete.assert_not_called()
