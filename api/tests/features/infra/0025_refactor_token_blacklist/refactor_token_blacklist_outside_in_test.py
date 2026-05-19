# FEATURE: refactor_token_blacklist — outside-in acceptance test.
#
# Verifies that after the architectural refactor:
#   1. A token blacklisted on logout is rejected on a subsequent authenticated request.
#   2. A fresh (non-blacklisted) token is accepted on an authenticated request.
#   3. The architecture gate "Core must not import Adapters" is KEPT without workarounds.
#
# Covers: F9, F10, F12, F15, F17, F21, F22, N5.
import subprocess
import sys
from pathlib import Path

from httpx import AsyncClient
from sqlalchemy import text

_PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent.parent.parent

_USERS_ENDPOINT = "/api/v1/user"
_LOGIN_ENDPOINT = "/api/v1/login"
_LOGOUT_ENDPOINT = "/api/v1/logout"
_ME_ENDPOINT = "/api/v1/user/me/"


async def test_blacklisted_access_token_is_rejected(async_client: AsyncClient, oit_db_session: object) -> None:
    """Scenario 1 — blacklisted token is rejected on subsequent authenticated request with 401."""
    resp = await async_client.post(
        _USERS_ENDPOINT,
        json={
            "name": "Alice Auth",
            "username": "aliceauth",
            "email": "alice.auth@example.com",
            "password": "Pa$$w0rd1",
        },
    )
    assert resp.status_code == 201, resp.text

    resp = await async_client.post(
        _LOGIN_ENDPOINT,
        data={"username": "alice.auth@example.com", "password": "Pa$$w0rd1"},
    )
    assert resp.status_code == 200, resp.text
    access_token = resp.json()["access_token"]

    # The client base_url is https:// so the Secure cookie from login is sent
    # automatically on this request.
    resp = await async_client.post(
        _LOGOUT_ENDPOINT,
        headers={"Authorization": f"Bearer {access_token}"},
    )
    assert resp.status_code == 200, resp.text
    assert resp.json() == {"message": "Logged out successfully"}

    resp = await async_client.get(
        _ME_ENDPOINT,
        headers={"Authorization": f"Bearer {access_token}"},
    )
    assert resp.status_code == 401
    assert resp.json() == {"detail": "User not authenticated."}

    result = await oit_db_session.execute(  # type: ignore[union-attr]
        text("SELECT EXISTS (SELECT 1 FROM token_blacklist WHERE token = :token)"),
        {"token": access_token},
    )
    assert result.scalar() is True


async def test_valid_token_is_accepted(async_client: AsyncClient, oit_db_session: object) -> None:
    """Scenario 2 — valid (non-blacklisted) token returns 200 with UserMeRead shape."""
    resp = await async_client.post(
        _USERS_ENDPOINT,
        json={
            "name": "Bob Valid",
            "username": "bobvalid",
            "email": "bob.valid@example.com",
            "password": "Pa$$w0rd2",
        },
    )
    assert resp.status_code == 201, resp.text

    resp = await async_client.post(
        _LOGIN_ENDPOINT,
        data={"username": "bob.valid@example.com", "password": "Pa$$w0rd2"},
    )
    assert resp.status_code == 200, resp.text
    access_token = resp.json()["access_token"]

    resp = await async_client.get(
        _ME_ENDPOINT,
        headers={"Authorization": f"Bearer {access_token}"},
    )
    assert resp.status_code == 200, resp.text
    body = resp.json()
    assert body["username"] == "bobvalid"
    assert body["email"] == "bob.valid@example.com"
    assert body["is_superuser"] is False
    assert body["is_moderator"] is False

    result = await oit_db_session.execute(  # type: ignore[union-attr]
        text("SELECT EXISTS (SELECT 1 FROM token_blacklist WHERE token = :token)"),
        {"token": access_token},
    )
    assert result.scalar() is False


def test_architecture_gate_core_must_not_import_adapters() -> None:
    """Scenario 3 — architecture gate: Core must not import Adapters is KEPT cleanly.

    Two checks run in sequence:
    - check_arch.py exits 0 and the import-linter reports the contract as Kept.
    - The architecture pytest test for this contract reports PASSED (not XFAIL),
      confirming the @pytest.mark.xfail workaround has been removed alongside the fix.
    """
    # Full architecture gate
    full_gate = subprocess.run(
        [sys.executable, "scripts/check_arch.py"],
        capture_output=True,
        text=True,
        cwd=str(_PROJECT_ROOT),
    )
    assert full_gate.returncode == 0, (
        f"check_arch.py failed (exit {full_gate.returncode}).\nstdout:\n{full_gate.stdout}\nstderr:\n{full_gate.stderr}"
    )

    lines = full_gate.stdout.splitlines()
    contract_idx = next(
        (i for i, line in enumerate(lines) if "Core must not import Adapters" in line),
        None,
    )
    assert contract_idx is not None, (
        f"'Core must not import Adapters' contract not found in check_arch.py output.\nstdout:\n{full_gate.stdout}"
    )
    context = "\n".join(lines[contract_idx : min(len(lines), contract_idx + 5)])
    assert "Kept" in context or "KEPT" in context, (
        f"'Core must not import Adapters' is not reported as Kept.\n"
        f"Context:\n{context}\n"
        f"Full stdout:\n{full_gate.stdout}"
    )

    for line in lines:
        assert "Broken" not in line and "BROKEN" not in line, (
            f"A contract is now BROKEN.\nLine: {line!r}\nFull stdout:\n{full_gate.stdout}"
        )

    # Verify the architecture test PASSES (not merely XFAIL)
    # Before the refactor: test is xfail(strict=True) and reports XFAILED.
    # After the refactor: xfail is removed and the test reports PASSED.
    arch_test = subprocess.run(
        [
            sys.executable,
            "-m",
            "pytest",
            "tests/architecture/test_architecture.py::test_core_does_not_import_adapters",
            "-v",
            "--no-header",
            "--tb=short",
        ],
        capture_output=True,
        text=True,
        cwd=str(_PROJECT_ROOT),
    )
    assert arch_test.returncode == 0, (
        f"Architecture test runner failed (exit {arch_test.returncode}).\n"
        f"stdout:\n{arch_test.stdout}\n"
        f"stderr:\n{arch_test.stderr}"
    )
    assert "XFAIL" not in arch_test.stdout, (
        "test_core_does_not_import_adapters reports XFAIL instead of PASSED.\n"
        "The refactor must remove the @pytest.mark.xfail decorator and fix the violation.\n"
        f"stdout:\n{arch_test.stdout}"
    )
    assert "PASSED" in arch_test.stdout, (
        f"test_core_does_not_import_adapters did not report PASSED.\nstdout:\n{arch_test.stdout}"
    )
