# FEATURE: users._shared — policy unit tests.
#
# Covers: F14, F15.
import pytest

from app.domain.errors import ForbiddenDomainError
from app.features.users._shared.policies import check_owner


def test_check_owner_same_username_returns_none() -> None:
    """F15 — same username; no exception raised."""
    assert check_owner("alice", "alice") is None


def test_check_owner_different_username_raises_forbidden() -> None:
    """F14 — different usernames; ForbiddenDomainError raised."""
    with pytest.raises(ForbiddenDomainError):
        check_owner("alice", "bob")


def test_check_owner_forbidden_has_empty_message() -> None:
    """ForbiddenDomainError constructed with no args has empty message."""
    with pytest.raises(ForbiddenDomainError) as exc_info:
        check_owner("alice", "bob")
    assert exc_info.value.message == ""
