# FEATURE: users._shared — policy unit tests.
#
# Covers: F8.
import pytest

from app.domain.errors import ForbiddenDomainError
from app.features.users._shared.policies import check_owner


def test_check_owner_same_id_returns_none() -> None:
    """F8 — same integer ID; no exception raised."""
    assert check_owner(1, 1) is None


def test_check_owner_different_id_raises_forbidden() -> None:
    """F8 — different integer IDs; ForbiddenDomainError raised."""
    with pytest.raises(ForbiddenDomainError):
        check_owner(1, 2)


def test_check_owner_forbidden_has_empty_message() -> None:
    """ForbiddenDomainError constructed with no args has empty message."""
    with pytest.raises(ForbiddenDomainError) as exc_info:
        check_owner(1, 2)
    assert exc_info.value.message == ""
