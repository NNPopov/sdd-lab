# FEATURE: migrate_update_post_route_username_to_user_id — use-case unit tests.
#
# Covers: F5, F6, F7, F8, F9, F12, F19.
import uuid
from datetime import UTC, datetime
from unittest.mock import AsyncMock, MagicMock

import pytest

from app.domain.errors import ForbiddenDomainError, NotFoundDomainError
from app.features.posts._shared.entities import PostItem, UserIdentity
from app.features.posts.update_post.domain.commands import UpdatePostCommand
from app.features.posts.update_post.domain.use_case import UpdatePostUseCase

_AUTHOR = UserIdentity(id=42, username="up56alice")
_POST = PostItem(
    id=10,
    title="Original title",
    text="Original text.",
    media_url=None,
    created_at=datetime(2025, 1, 1, tzinfo=UTC),
    created_by_user_id=42,
    username="up56alice",
    status="approved",
    post_uuid=uuid.UUID("00000000-0000-0000-0000-000000000001"),
)
_CMD = UpdatePostCommand(
    target_user_id=42,
    requester_user_id=42,
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


# ── F6, F19: happy path (owner) ───────────────────────────────────────────────


@pytest.mark.asyncio
async def test_happy_path_resolves_by_id_and_calls_update() -> None:
    """F6, F19 — author resolved by id, ownership passes → update called once with the command."""
    port = _make_port()
    user_lookup = _make_user_lookup()
    use_case = UpdatePostUseCase(port=port, user_lookup=user_lookup)  # type: ignore[arg-type]

    await use_case(_CMD)

    user_lookup.get_active_user_by_id.assert_called_once_with(_CMD.target_user_id)
    port.get_post_by_id.assert_called_once_with(_CMD.post_id)
    port.update.assert_called_once_with(_CMD)


# ── F5, F8, F9: user not found → 404 before any ownership/post step ───────────


@pytest.mark.asyncio
async def test_raises_not_found_when_user_missing() -> None:
    """F5, F8, F9 — user lookup None → NotFoundDomainError; post not fetched, update not called."""
    port = _make_port()
    use_case = UpdatePostUseCase(port=port, user_lookup=_make_user_lookup(author=None))  # type: ignore[arg-type]

    with pytest.raises(NotFoundDomainError) as exc_info:
        await use_case(_CMD)

    assert exc_info.value.message == "User not found"
    port.get_post_by_id.assert_not_called()
    port.update.assert_not_called()


# ── F6, F9, F17: not owner → bare 403 ─────────────────────────────────────────


@pytest.mark.asyncio
async def test_raises_forbidden_when_requester_is_not_author() -> None:
    """F6, F9, F17 — requester != author.id → bare ForbiddenDomainError; post not fetched, update not called."""
    cmd = UpdatePostCommand(
        target_user_id=42,
        requester_user_id=99,
        post_id=10,
        title="Hijacked title",
    )
    port = _make_port()
    use_case = UpdatePostUseCase(port=port, user_lookup=_make_user_lookup())  # type: ignore[arg-type]

    with pytest.raises(ForbiddenDomainError) as exc_info:
        await use_case(cmd)

    assert exc_info.value.message == ""
    port.get_post_by_id.assert_not_called()
    port.update.assert_not_called()


# ── F7, F9: post not found → 404 after ownership passes ───────────────────────


@pytest.mark.asyncio
async def test_raises_not_found_when_post_missing() -> None:
    """F7, F9 — get_post_by_id returns None → NotFoundDomainError('Post not found'); update never called."""
    port = _make_port(post=None)
    use_case = UpdatePostUseCase(port=port, user_lookup=_make_user_lookup())  # type: ignore[arg-type]

    with pytest.raises(NotFoundDomainError) as exc_info:
        await use_case(_CMD)

    assert exc_info.value.message == "Post not found"
    port.update.assert_not_called()
