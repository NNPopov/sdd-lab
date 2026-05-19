# 0027 · migrate_di_wiring — Validation

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md
- Requirements: ./requirements.md

## Prerequisites

- App running locally (`uvicorn app.main:app --reload` from `src/`).
- Test database seeded with at least one user, one post, and a superuser account.
- Valid Bearer tokens for a regular user and a superuser at hand.
- `ruff`, `mypy`, and `pytest` available in the virtualenv.

## Manual scenarios

### S1 — Create user (users · create_user router)

**Steps:**

1. `curl -s -X POST http://localhost:8000/api/v1/users -H "Content-Type: application/json" -d '{"username": "valuser01", "email": "valuser01@example.com", "password": "Pa$$w0rd1"}' | python -m json.tool`

**Expected:**

- Status 201.
- Response body contains `id`, `username`, and `email`.
- No `AttributeError` or `TypeError` in server logs (confirms `Provide[Container.create_user_use_case]` resolved correctly).

**Covers:** F1, F4, F6, F10, F13.

---

### S2 — List users (users · list_users router)

**Steps:**

1. Obtain a superuser Bearer token (login via `/api/v1/auth/login`).
2. `curl -s http://localhost:8000/api/v1/users -H "Authorization: Bearer <superuser_token>" | python -m json.tool`

**Expected:**

- Status 200.
- Response is a JSON array of user objects.

**Covers:** F1, F4, F6, F10, F13.

---

### S3 — Get user by username

**Steps:**

1. `curl -s http://localhost:8000/api/v1/users/valuser01 -H "Authorization: Bearer <token>" | python -m json.tool`

**Expected:**

- Status 200.
- Response body contains the `valuser01` user record.

**Covers:** F6, F13.

---

### S4 — Delete user (tests `shared_dependencies` token-blacklist wiring)

**Steps:**

1. Log in as `valuser01` to obtain their token:
   `curl -s -X POST http://localhost:8000/api/v1/auth/login -d "username=valuser01&password=Pa$$w0rd1" -H "Content-Type: application/x-www-form-urlencoded"`
2. Delete the account:
   `curl -s -X DELETE http://localhost:8000/api/v1/users/valuser01 -H "Authorization: Bearer <valuser01_token>" | python -m json.tool`

**Expected:**

- Status 200.
- Token is blacklisted; a subsequent request with the same token returns 401.
- No `AttributeError` in server logs (confirms `Provide[Container.token_blacklist_adapter]` resolved for both `delete_user` router and `shared_dependencies.get_current_user`).

**Covers:** F7, F8, F10, F13.

---

### S5 — Authenticated optional-user endpoint (tests `get_optional_user` wiring)

**Steps:**

1. Obtain a valid Bearer token.
2. Call any endpoint that uses `get_optional_user` (e.g. listing public posts):
   `curl -s http://localhost:8000/api/v1/posts -H "Authorization: Bearer <token>" | python -m json.tool`
3. Repeat without the `Authorization` header.

**Expected:**

- Step 2: Status 200, posts returned with user context visible.
- Step 3: Status 200, posts returned without user context (anonymous view).
- No `AttributeError` in server logs for either call (confirms `Provide[Container.token_blacklist_adapter]` in `get_optional_user` resolved correctly).

**Covers:** F9, F10, F13.

---

### S6 — Post endpoint wiring check (posts · create_post router)

**Steps:**

1. Obtain a valid user Bearer token.
2. `curl -s -X POST http://localhost:8000/api/v1/posts -H "Content-Type: application/json" -H "Authorization: Bearer <token>" -d '{"title": "Validation post", "content": "Testing DI wiring."}' | python -m json.tool`

**Expected:**

- Status 201.
- Response body contains `id`, `title`, and `content`.

**Covers:** F6, F10, F13.

---

### S7 — Smoke test (import-level wiring check)

**Steps:**

1. Stop the running server.
2. `pytest tests/smoke/test_app_starts.py -v`

**Expected:**

- Test passes.
- No `ImportError`, `CircularImportError`, or wiring-related error appears in the output.

**Covers:** F14.

---

### S8 — Zero PLC0415 suppressions after migration (linter gate)

**Steps:**

1. `ruff check src/app/features src/app/shared_dependencies.py --select PLC0415`

**Expected:**

- Zero violations reported.
- All `# noqa: PLC0415` comments have been removed.

**Covers:** F2, F3, F11.

---

### S9 — Full regression suite

**Steps:**

1. `pytest -v`

**Expected:**

- All outside-in tests in `tests/features/` pass.
- All integration tests in `tests/features/**/presentation/test_router.py` pass.
- Smoke test passes.
- No new failures compared to the pre-migration baseline.

**Covers:** F13, F14.

---

### S10 — Override compatibility (DI mock injection still works)

**Steps:**

1. Run the integration test suite with coverage to confirm overrides still function:
   `pytest tests/features/ -v -k "test_router"`

**Expected:**

- All router integration tests pass, confirming that `container.<provider>.override(mock)` continues to work after wiring is enabled.

**Covers:** F13 (override-compatibility aspect of user story 5).

---

## Code review checklist

### Architecture

- [ ] Slice folder is not created — this is a pure migration; no new slice folder exists.
- [ ] No domain, port, adapter, or use-case files are added or modified; only `bootstrap/container.py`, `shared_dependencies.py`, the 17 `presentation/router.py` files, and `agent_docs/entry_points/fastapi.md` are changed (N1).
- [ ] No cross-slice imports were introduced by the migration (N4).
- [ ] All imports inside `src/app/` are **relative** — feature router modules import `Container` as `from .....bootstrap.container import Container`, not `from app.bootstrap.container import Container` (N2).

### Wiring configuration

- [ ] `bootstrap/container.py` declares `wiring_config = containers.WiringConfiguration(modules=[...])` as the **first** attribute of the `Container` class body, before any provider declaration (F1).
- [ ] The `modules` list contains exactly 18 entries: all 17 `presentation.router` dotted paths and `"app.shared_dependencies"` (F1).
- [ ] No `packages=` argument is used — the list is explicit (per PRD implementation decision).
- [ ] Provider definitions (`providers.Factory`, `providers.Object`) are unchanged (N1, out-of-scope).

### Helper removal

- [ ] All 17 `_get_<name>_use_case()` helper functions are removed from their respective `presentation/router.py` files (F2).
- [ ] `_get_token_blacklist_adapter()` is removed from `shared_dependencies.py` (F3).
- [ ] `_get_token_blacklist_adapter()` is also removed from `delete_user/presentation/router.py` (F7, F2).
- [ ] Zero `# noqa: PLC0415` comments remain in `src/app/features/` or `src/app/shared_dependencies.py` (F11).

### New imports

- [ ] Each of the 17 `presentation/router.py` files has `from dependency_injector.wiring import Provide, inject` and a relative `from .....bootstrap.container import Container` (or appropriate dot-depth) at module level (F4).
- [ ] `shared_dependencies.py` has `from dependency_injector.wiring import Provide, inject` and `from .bootstrap.container import Container` at module level (F5).
- [ ] No absolute imports (`from app...`) inside any file under `src/app/` (N2).

### Endpoint and dependency signatures

- [ ] Every endpoint that previously used `Depends(_get_<name>_use_case)` now uses `Depends(Provide[Container.<name>_use_case])` with the correct provider name from the mapping in plan.md § 5 Step 2 (F6).
- [ ] `delete_user` endpoint carries **two** `Provide[...]` parameters: `Depends(Provide[Container.delete_user_use_case])` and `Depends(Provide[Container.token_blacklist_adapter])` (F7).
- [ ] `shared_dependencies.get_current_user` signature includes `blacklist: Annotated[TokenBlacklistPort, Depends(Provide[Container.token_blacklist_adapter])]` (F8).
- [ ] `shared_dependencies.get_optional_user` signature includes `blacklist: TokenBlacklistPort = Depends(Provide[Container.token_blacklist_adapter])` retaining the legacy `= Depends(...)` style (F9).

### Decorator order

- [ ] Every endpoint and dependency function that uses `Provide[...]` carries `@inject` (F10).
- [ ] `@inject` is the **innermost** decorator — placed directly above `async def`, below `@router.*` and below `@cache` when both are present (F10).
- [ ] No function has `@inject` above `@router.*` or above `@cache` (F10 — silent injection failure if violated).

### Files and headers

- [ ] No new `.py` files are created (N5).
- [ ] Every modified `.py` file retains its original `# STABLE:` or `# FEATURE:` header on line 1 (N5).
- [ ] No STABLE file other than `bootstrap/container.py` and `shared_dependencies.py` was modified (N1).
- [ ] `agent_docs/entry_points/fastapi.md` documents all three mandatory bootstrap steps for a new slice, including step 3 (`wiring_config.modules`), and explains the silent-failure mode if step 3 is omitted (F12).

### Error handling

- [ ] Adapter catches **only** business-meaningful infrastructure exceptions. No broad `except Exception` blocks added (no adapter files changed — verify unchanged).
- [ ] No `HTTPException` raised inside any use-case (no use-case files changed — verify unchanged).
- [ ] No new `DomainError` subclass added in a slice folder.

### Tests

- [ ] No new test files added (migration produces no new tests — this is expected and correct per plan.md § 6).
- [ ] All existing outside-in tests remain green (F13).
- [ ] Smoke test passes (F14).
- [ ] All existing `test_router.py` integration tests pass, confirming override compatibility (F13).

### Quality gates

Run from project root:

```
ruff format src/app tests
ruff check src/app tests
mypy src/app
pytest
```

All must pass. Additionally verify:

```
ruff check src/app/features src/app/shared_dependencies.py --select PLC0415
```

Must report zero violations (F11). The smoke test inside `pytest`
(`tests/smoke/test_app_starts.py`) boots the app in a subprocess and pings
`/api/v1/health`. If it fails, the migration has introduced a circular import
or a missing `wiring_config.modules` entry that manifests only under uvicorn's
import context — the slice is **not done** until it passes.
