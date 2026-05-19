# 0025 · centralize_auth_dependencies — Test spec

## Goal

Prove that `_get_user_by_credential` returns the correct allowlisted dict for a
valid non-deleted user and `None` for a soft-deleted or missing user, and that
`get_current_user` raises `UnauthorizedException` when the token is invalid.

## Outside-in opt-out

This slice introduces no new HTTP entry point and no new acceptance contract.
Per plan.md § 6, the outside-in test is **opted out**.

The acceptance gate for this slice consists of:

1. **Unit tests** in
   `tests/features/architecture/0025_centralize_auth_dependencies/test_shared_dependencies.py`
   — prove the behavior of `_get_user_by_credential` and the auth functions.
2. **Architecture tests** (`pytest tests/architecture/`) — the two previously
   failing parametrize cases `test_vsa_domains_do_not_import_each_other[posts-users]`
   and `[users-posts]` must now be green.
3. **importlinter** (`cd src && lint-imports --config ../.importlinter`) — the
   `vsa-feature-independence` contract must pass.
4. **Smoke test** (`tests/smoke/test_app_starts.py`) — proves the app boots with
   all import paths updated.

## Test file

`tests/features/architecture/0025_centralize_auth_dependencies/test_shared_dependencies.py`

This file starts with `# FEATURE: centralize_auth_dependencies —` on line 1 (N3).

## Wired real

- `_get_user_by_credential` from `app.shared_dependencies` (the private helper
  under test; imported directly for unit testing).
- `get_current_user` from `app.shared_dependencies`.
- The SQLAlchemy query path inside `_get_user_by_credential` (no monkey-patching
  of SQLAlchemy internals; only the session itself is mocked).

## Mocked

- **`AsyncSession`**: `mocker.AsyncMock(spec=AsyncSession)` — substitutes the
  real DB session for all `_get_user_by_credential` scenarios. `db.execute()`
  is configured to return a mock result; `result.scalar_one_or_none()` is set to
  the desired row or `None` per scenario.
- **`verify_token`**: `mocker.patch("app.shared_dependencies.verify_token")` —
  used in `get_current_user` scenarios to control whether token validation
  succeeds or fails.
- **`_get_user_by_credential`**: `mocker.patch("app.shared_dependencies._get_user_by_credential")`
  — used only in `get_current_user` scenarios where the token is already valid and
  the test focuses on the user-lookup branch.

## Fixtures used

- `mocker` (from `pytest-mock`): provides `AsyncMock` and `mocker.patch`.
- No `db_session`, `client`, or `app` fixture — these are unit tests with no
  real database and no HTTP stack.

## Test scenarios

### Scenario 1: happy path — username credential returns the allowlisted dict

**Setup:**

- `db = mocker.AsyncMock(spec=AsyncSession)`.
- `db.execute.return_value.scalar_one_or_none.return_value` is a mock `UserModel`
  row with `id=1`, `username="alice"`, `email="alice@example.com"`,
  `is_superuser=False`, `is_moderator=False`, `tier_id=1`.

**Act:**

- `await _get_user_by_credential(db, "alice")`

**Expect:**

- Returns `{"id": 1, "username": "alice", "email": "alice@example.com",
  "is_superuser": False, "is_moderator": False, "tier_id": 1}`.
- Key `"hashed_password"` is **absent** from the returned dict.
- No other keys are present beyond the six allowlisted ones.

**Covers requirement(s):** F2, F4.

### Scenario 2: most important failure — soft-deleted user lookup returns None

**Setup:**

- `db = mocker.AsyncMock(spec=AsyncSession)`.
- `db.execute.return_value.scalar_one_or_none.return_value = None` — simulates
  the WHERE clause `is_deleted IS FALSE` excluding a soft-deleted row; the
  database returns no match.

**Act:**

- `await _get_user_by_credential(db, "deleted_user")`

**Expect:**

- Returns `None`.

**DB state:** Not applicable — this is a unit test with a mocked session.

**Covers requirement(s):** F1, F5.

### Scenario 3: `get_current_user` raises 401 when `verify_token` returns None

This third scenario is included because the token-validation failure path is a
critical security contract that cannot be delegated to the adapter unit test (there
is no adapter) or the endpoint integration test (there is no new endpoint).

**Setup:**

- `mocker.patch("app.shared_dependencies.verify_token", new=mocker.AsyncMock(return_value=None))`.
- `db = mocker.AsyncMock(spec=AsyncSession)`.

**Act:**

- `await get_current_user(token="garbage.token.here", db=db)`

**Expect:**

- Raises `UnauthorizedException` (from `fastcrud.exceptions.http_exceptions`).
- `_get_user_by_credential` is **never called** (token invalid before lookup).

**Covers requirement(s):** F6.

## Out of scope for this test file

- Email-branch routing (`@` detection in credential) — covered by a dedicated
  unit test case in `test_shared_dependencies.py` (`test_routes_by_at_sign_to_email_branch`).
- `get_current_user` raises 401 when user not found after valid token — covered
  by `test_raises_unauthorized_when_user_not_found` in the same file.
- `get_optional_user` returning `None` for missing / bad-format / invalid-token
  header — covered by three unit test cases in the same file.
- `get_current_superuser` and `get_current_moderator_or_superuser` role checks —
  covered by unit test cases in the same file (F13, F14).
- VSA independence contract — covered by `tests/architecture/test_architecture.py`.
- Import-layer contract — covered by `importlinter`.
- App boot with updated imports — covered by `tests/smoke/test_app_starts.py`.
- Performance, concurrency, load.
