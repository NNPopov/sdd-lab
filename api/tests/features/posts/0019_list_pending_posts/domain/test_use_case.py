# FEATURE: list_pending_posts — use-case unit tests.
#
# Covers: F14.
from unittest.mock import AsyncMock, MagicMock

import pytest

from app.domain.errors import ForbiddenDomainError
from app.features.posts.list_pending_posts.domain.commands import ListPendingPostsQuery
from app.features.posts.list_pending_posts.domain.entities import PendingPostPage
from app.features.posts.list_pending_posts.domain.use_case import ListPendingPostsUseCase

_PAGE = PendingPostPage(
    items=[],
    total_count=0,
    page=1,
    items_per_page=10,
)


def _make_port() -> MagicMock:
    port = MagicMock()
    port.list = AsyncMock(return_value=_PAGE)
    return port


def _query(**overrides) -> ListPendingPostsQuery:
    defaults: dict = {"page": 1, "items_per_page": 10, "requester_is_privileged": True}
    defaults.update(overrides)
    return ListPendingPostsQuery(**defaults)


# ── F14: privilege check ──────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_forbidden_when_not_privileged() -> None:
    """F14 — requester_is_privileged=False → ForbiddenDomainError; port.list not called."""
    port = _make_port()
    use_case = ListPendingPostsUseCase(port=port)  # type: ignore[arg-type]
    with pytest.raises(ForbiddenDomainError) as exc_info:
        await use_case(_query(requester_is_privileged=False))
    assert exc_info.value.message == "Moderator or superuser privilege required"
    port.list.assert_not_called()


# ── F14: happy path ───────────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_happy_path_delegates_to_port() -> None:
    """F14 — requester_is_privileged=True → port.list called; result passed through."""
    port = _make_port()
    use_case = ListPendingPostsUseCase(port=port)  # type: ignore[arg-type]
    q = _query(requester_is_privileged=True)
    result = await use_case(q)
    port.list.assert_called_once_with(q)
    assert result is _PAGE
