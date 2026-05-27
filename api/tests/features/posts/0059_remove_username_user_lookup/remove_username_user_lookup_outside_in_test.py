# FEATURE: remove_username_user_lookup — outside-in acceptance test (removal guard).
#
# This slice is a PURE DEAD-CODE REMOVAL with no new HTTP entry point. Per the PRD,
# plan.md, and tests.md, no behavioural outside-in test is written: the behavioural
# acceptance gate is the eight EXISTING post write outside-in tests
# (0011/0028/0029/0030 and their 0055/0056/0057/0058 migration successors) staying
# green, which prove that removing `get_active_user_by_username` broke no consumer.
#
# The deliverable of THIS slice is the removal itself, so the acceptance gate that is
# red-then-green is a structural removal guard: `get_active_user_by_username` must be
# gone from both the shared `UserLookupPort` Protocol and the `UserLookupAdapter`,
# while `get_active_user_by_id` remains. This file encodes that contract.
#
# RED state (before implementation): the username method still exists on both the
# port and the adapter, so the "method is gone" assertions FAIL.
# GREEN state (after implementation): the method is removed; assertions pass.
#
# Covers: F1, F2, F4, F8 (the by-id survival and the absence of the username method).
from app.features.posts._shared.user_lookup_adapter import UserLookupAdapter
from app.features.posts._shared.user_lookup_port import UserLookupPort


def test_username_lookup_removed_from_port() -> None:
    """F2 — get_active_user_by_username is no longer declared on UserLookupPort."""
    assert "get_active_user_by_username" not in UserLookupPort.__dict__


def test_username_lookup_removed_from_adapter() -> None:
    """F4 — get_active_user_by_username is no longer implemented on UserLookupAdapter."""
    assert "get_active_user_by_username" not in UserLookupAdapter.__dict__
    assert not hasattr(UserLookupAdapter, "get_active_user_by_username")


def test_by_id_lookup_survives_on_port_and_adapter() -> None:
    """F1, F5 — get_active_user_by_id remains the sole user-resolution method."""
    assert "get_active_user_by_id" in UserLookupPort.__dict__
    assert "get_active_user_by_id" in UserLookupAdapter.__dict__


def test_adapter_still_satisfies_port() -> None:
    """F6 — the adapter remains a runtime-checkable implementation of the port."""
    adapter = UserLookupAdapter(session_factory=None)  # type: ignore[arg-type]
    assert isinstance(adapter, UserLookupPort)
