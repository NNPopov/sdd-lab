# 0025 · refactor_token_blacklist — Validation

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md
- Requirements: ./requirements.md

## Prerequisites

- App running locally (`uvicorn app.main:app --reload` from `src/`).
- Test Postgres running and migrated (`alembic upgrade head`).
- A seeded user account — `email: alice@example.com`, `password: Pa$$w0rd` (or
  substitute real credentials from your local seed).
- `python scripts/check_arch.py` available from the project root.

---

## Manual scenarios

### S1 — Login returns tokens

**Steps:**

1. ```bash
   curl -s -c cookies.txt -X POST http://localhost:8000/api/v1/login \
     -H "Content-Type: application/x-www-form-urlencoded" \
     -d "username=alice@example.com&password=Pa%24%24w0rd"
   ```

**Expected:**

- Status 200.
- Body contains `"access_token"` and `"token_type": "bearer"`.
- Response sets a `refresh_token` HttpOnly cookie (visible in `cookies.txt`).
- Copy the `access_token` value for use in later scenarios.

**Covers:** F21 (prerequisite — establishes tokens before blacklisting).

---

### S2 — Valid access token accepted on authenticated endpoint

**Steps:**

1. Complete S1 and note the `access_token`.
2. ```bash
   curl -s -X GET http://localhost:8000/api/v1/users/me \
     -H "Authorization: Bearer <access_token>"
   ```

**Expected:**

- Status 200.
- Body contains the current user's profile fields (e.g. `"email": "alice@example.com"`).

**Covers:** F21 (confirms the happy path still works after the refactor; no regression).

---

### S3 — Logout succeeds

**Steps:**

1. Complete S1 and note the `access_token`.
2. ```bash
   curl -s -b cookies.txt -c cookies.txt \
     -X POST http://localhost:8000/api/v1/logout \
     -H "Authorization: Bearer <access_token>"
   ```

**Expected:**

- Status 200.
- Body `{"message": "Logged out successfully"}` (or equivalent existing message).
- The `refresh_token` cookie is cleared in the response.

**Covers:** F17, F21 (logout endpoint continues to function after wiring change).

---

### S4 — Blacklisted access token rejected on subsequent authenticated request

**Steps:**

1. Complete S3 (login → logout with `<access_token>`).
2. Use the **same** `<access_token>` from step 1 on an authenticated endpoint:
   ```bash
   curl -s -X GET http://localhost:8000/api/v1/users/me \
     -H "Authorization: Bearer <access_token>"
   ```

**Expected:**

- Status 401.
- Body contains an error message such as `{"detail": "Token has been revoked"}` or
  `{"message": "..."}` — the exact wording matches the existing pre-refactor response.

**Covers:** F21.

---

### S5 — Blacklisted refresh token rejected on token refresh

**Steps:**

1. Complete S3 (login → logout, which blacklists both tokens).
2. Attempt a token refresh using the now-blacklisted refresh cookie:
   ```bash
   curl -s -b cookies.txt \
     -X POST http://localhost:8000/api/v1/refresh
   ```

**Expected:**

- Status 401 (or 400 if the cookie was cleared by logout).
- Body contains an error indicating the refresh token is invalid or blacklisted.

**Covers:** F18, F21.

---

### S6 — Refresh endpoint with a valid refresh token still works

**Steps:**

1. Complete S1 (login — tokens issued, **do not logout**).
2. ```bash
   curl -s -b cookies.txt -c cookies.txt \
     -X POST http://localhost:8000/api/v1/refresh
   ```

**Expected:**

- Status 200.
- Body contains a new `"access_token"`.

**Covers:** F18 (refresh endpoint wiring regression check).

---

### S7 — Architecture gate passes

**Steps:**

1. From the project root:
   ```bash
   python scripts/check_arch.py
   ```

**Expected:**

- Exit code 0.
- Output contains `KEPT` next to `Core must not import Adapters`.
- No other previously-KEPT contract has regressed to BROKEN.

**Covers:** F22.

---

## Code review checklist

### Architecture

- [ ] `src/app/ports/token_blacklist.py` declares exactly two methods:
      `async def is_blacklisted(self, token: str) -> bool` and
      `async def blacklist(self, token: str, expires_at: datetime) -> None`. (F1)
- [ ] `TokenBlacklistPort` carries the `@runtime_checkable` decorator. (N7)
- [ ] `TokenBlacklistAdapter` class declaration is
      `class TokenBlacklistAdapter(TokenBlacklistPort):` — explicit port
      inheritance, no implicit structural conformance. (F2)
- [ ] `TokenBlacklistAdapter.__init__` signature is
      `def __init__(self, session_factory: async_sessionmaker[AsyncSession]) -> None`.
      No `session` parameter on port methods. (F3)
- [ ] `adapters/db/token_blacklist/adapter.py` uses only plain SQLAlchemy
      (`select`, `exists`, `session.add`, `session.commit`). No FastCRUD import
      anywhere in the file. (N1)
- [ ] All imports inside `src/app/` are relative (`from ...ports.token_blacklist
      import TokenBlacklistPort`). No `from app...` or `from src.app...` inside
      source files. (N4)
- [ ] `src/app/core/security.py` imports `TokenBlacklistPort` from
      `..ports.token_blacklist`, not from `adapters/`. (F12, N5)
- [ ] `verify_token` signature has `blacklist: TokenBlacklistPort` as third
      parameter; the `db: AsyncSession` parameter is removed. (F9)
- [ ] `blacklist_tokens` signature has `blacklist: TokenBlacklistPort` as third
      parameter; `db: AsyncSession` removed. (F10)
- [ ] `blacklist_token` signature has `blacklist: TokenBlacklistPort` as second
      parameter; `db: AsyncSession` removed. (F11)
- [ ] No import from `sqlalchemy.ext.asyncio` remains in `core/security.py`
      unless `AsyncSession` is still used elsewhere in that file. (F12)
- [ ] No cross-slice imports: `adapters/db/token_blacklist/adapter.py` imports
      nothing from `features/`. (N6)

### Error handling

- [ ] `TokenBlacklistAdapter` contains **no `try/except` block** — neither in
      `is_blacklisted` nor in `blacklist`. Infrastructure exceptions propagate
      unchanged. (F7, F8, N2)
- [ ] No broad `except Exception` introduced anywhere in the refactored path.
- [ ] Adapter does not log exceptions.

### Files and headers

- [ ] `src/app/adapters/db/token_blacklist/adapter.py` starts with
      `# STABLE:` on line 1. (N3)
- [ ] `src/app/core/token_blacklist_service.py` is deleted (not just
      emptied or commented out). (F19)
- [ ] `src/app/adapters/db/token_blacklist/repository.py` is deleted. (F20)
- [ ] No remaining reference to `TokenBlacklistService` anywhere in `src/`. (F13)
- [ ] No remaining reference to `crud_token_blacklist` anywhere in `src/`. (F12, F20)
- [ ] No `model.dict()` — only `model.model_dump()` if schemas are touched.

### DI

- [ ] `bootstrap/container.py` declares
      `token_blacklist_adapter = providers.Factory(TokenBlacklistAdapter, session_factory=session_factory)`. (F13)
- [ ] `bootstrap/container.py` no longer imports or references `TokenBlacklistService`. (F13)
- [ ] Wiring configuration includes `"app.shared_dependencies"` and
      `"app.features.auth.router"`. (F14)
- [ ] `get_current_user` in `shared_dependencies.py` uses
      `Depends(Provide[Container.token_blacklist_adapter])` for the
      `blacklist` parameter. (F15)
- [ ] `get_optional_user` in `shared_dependencies.py` does the same. (F16)
- [ ] `logout` endpoint injects `blacklist: TokenBlacklistPort` via
      `Depends(Provide[Container.token_blacklist_adapter])`. (F17)
- [ ] `refresh_access_token` endpoint injects `blacklist: TokenBlacklistPort`
      via `Depends(Provide[Container.token_blacklist_adapter])`. (F18)
- [ ] Neither `logout` nor `refresh_access_token` has a `db: AsyncSession`
      parameter remaining. (F17, F18)

### Tests

- [ ] Adapter unit test (`tests/adapters/db/token_blacklist/test_adapter.py`)
      exists and covers: `is_blacklisted` → False, `is_blacklisted` → True,
      `blacklist` inserts and commits, `OperationalError` propagates unchanged
      from both methods.
- [ ] Endpoint integration test (`tests/features/auth/test_auth.py`) exists
      and covers the login → logout → 401 flow.
- [ ] Outside-in test exists at
      `tests/features/infra/0025_refactor_token_blacklist/refactor_token_blacklist_outside_in_test.py`
      and is GREEN.
- [ ] No test file imports `TokenBlacklistService` or `crud_token_blacklist`.

### Quality gates

Run from project root:

```
ruff format src/app tests
ruff check src/app tests
mypy src/app
pytest
python scripts/check_arch.py
```

All must pass. The smoke test inside `pytest` (`tests/smoke/test_app_starts.py`)
boots the app in a subprocess and pings `/api/v1/health`. A failure there
typically means a broken import path that works under pytest's `PYTHONPATH` but
breaks under uvicorn — the slice is **not done** until the smoke test is green.

`python scripts/check_arch.py` must report `KEPT` for `Core must not import
Adapters`. If it regresses any other previously-KEPT contract, that regression
must be investigated before merging.
