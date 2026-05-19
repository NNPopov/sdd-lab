# FEATURE: refactor_token_blacklist — unit tests for TokenBlacklistAdapter.
#
# Covers: F2, F3, F4, F5, F6, F7, F8, N1, N2.
from datetime import UTC, datetime, timedelta
from unittest.mock import AsyncMock, MagicMock

import pytest
from sqlalchemy.exc import OperationalError

from app.adapters.db.token_blacklist.adapter import TokenBlacklistAdapter
from app.ports.token_blacklist import TokenBlacklistPort

_EXPIRES = datetime.now(UTC).replace(tzinfo=None) + timedelta(hours=1)


def _make_adapter() -> tuple[TokenBlacklistAdapter, MagicMock, MagicMock]:
    """Return (adapter, session_mock, session_factory_mock)."""
    session = MagicMock()
    session.execute = AsyncMock()
    session.add = MagicMock()
    session.commit = AsyncMock()
    session.__aenter__ = AsyncMock(return_value=session)
    session.__aexit__ = AsyncMock(return_value=False)

    factory = MagicMock()
    factory.return_value = session

    adapter = TokenBlacklistAdapter(session_factory=factory)
    return adapter, session, factory


# ── F2: adapter explicitly inherits TokenBlacklistPort ────────────────────────


def test_adapter_satisfies_port_protocol() -> None:
    """F2, N7: TokenBlacklistAdapter is an instance of TokenBlacklistPort."""
    adapter, _, _ = _make_adapter()
    assert isinstance(adapter, TokenBlacklistPort)


# ── F3: constructor stores session_factory ────────────────────────────────────


def test_constructor_stores_session_factory() -> None:
    """F3: __init__ stores the factory as _session_factory."""
    adapter, _, factory = _make_adapter()
    assert adapter._session_factory is factory


# ── F4: is_blacklisted returns False when EXISTS query returns falsy ───────────


async def test_is_blacklisted_returns_false_when_not_found() -> None:
    """F4: is_blacklisted returns False when no row with that token exists."""
    adapter, session, _ = _make_adapter()
    result_mock = MagicMock()
    result_mock.scalar.return_value = False
    session.execute.return_value = result_mock

    result = await adapter.is_blacklisted("some.token.value")

    assert result is False


# ── F5: is_blacklisted returns True when EXISTS query returns truthy ───────────


async def test_is_blacklisted_returns_true_when_found() -> None:
    """F5: is_blacklisted returns True when a row with that token exists."""
    adapter, session, _ = _make_adapter()
    result_mock = MagicMock()
    result_mock.scalar.return_value = True
    session.execute.return_value = result_mock

    result = await adapter.is_blacklisted("blacklisted.token.value")

    assert result is True


# ── F6: blacklist inserts row and commits ─────────────────────────────────────


async def test_blacklist_adds_row_and_commits() -> None:
    """F6: blacklist adds a TokenBlacklist row with correct fields and commits."""
    from app.adapters.db.token_blacklist.model import TokenBlacklist

    adapter, session, _ = _make_adapter()

    await adapter.blacklist("tok", _EXPIRES)

    session.add.assert_called_once()
    added: TokenBlacklist = session.add.call_args[0][0]
    assert isinstance(added, TokenBlacklist)
    assert added.token == "tok"
    assert added.expires_at == _EXPIRES
    session.commit.assert_awaited_once()


# ── F7: OperationalError from execute propagates unchanged ───────────────────


async def test_is_blacklisted_propagates_operational_error() -> None:
    """F7: OperationalError from session.execute propagates unchanged."""
    adapter, session, _ = _make_adapter()
    session.execute.side_effect = OperationalError("stmt", {}, Exception("db down"))

    with pytest.raises(OperationalError):
        await adapter.is_blacklisted("any.token")


# ── F8: OperationalError from commit propagates unchanged ────────────────────


async def test_blacklist_propagates_operational_error_from_commit() -> None:
    """F8: OperationalError from session.commit propagates unchanged."""
    adapter, session, _ = _make_adapter()
    session.commit.side_effect = OperationalError("stmt", {}, Exception("db down"))

    with pytest.raises(OperationalError):
        await adapter.blacklist("tok", _EXPIRES)
