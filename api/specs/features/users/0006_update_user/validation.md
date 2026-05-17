# 0006 · update_user — Validation

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md
- Requirements: ./requirements.md

## Prerequisites

- App running locally: `uvicorn src.app.main:app --reload` (from project root).
- Test Postgres running and migrated: `alembic upgrade head`.
- Two registered users available — one to own the profile, one to attempt a cross-ownership patch.
- A valid Bearer token for each user. Obtain via `POST /api/v1/login` (OAuth2 password form).

**Helper — register a user:**
```bash
curl -s -X POST http://localhost:8000/api/v1/user \
  -H "Content-Type: application/json" \
  -d '{"name":"Alice","username":"alice","email":"alice@example.com","password":"Str1ngst!"}'
```

**Helper — get a token:**
```bash
curl -s -X POST http://localhost:8000/api/v1/login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=alice&password=Str1ngst!"
# Copy the access_token value; use as: -H "Authorization: Bearer <token>"
```

Register a second user `bob` / `bob@example.com` and obtain his token for cross-ownership tests.

---

## Manual scenarios

### S1 — Happy path: partial update (name only)

**Steps:**

1. Register `alice` and obtain her token (see Prerequisites).
2. ```bash
   curl -s -X PATCH http://localhost:8000/api/v1/user/alice \
     -H "Authorization: Bearer <alice_token>" \
     -H "Content-Type: application/json" \
     -d '{"name":"Alice Updated"}'
   ```

**Expected:**

- Status `200 OK`.
- Body: `{"message": "User updated"}`.
- Subsequent `GET /api/v1/user/alice` returns `name == "Alice Updated"`.

**Covers:** F1, F13.

---

### S2 — Happy path: full update (all fields)

**Steps:**

1. Register `alice` and obtain her token.
2. ```bash
   curl -s -X PATCH http://localhost:8000/api/v1/user/alice \
     -H "Authorization: Bearer <alice_token>" \
     -H "Content-Type: application/json" \
     -d '{"name":"Alice B","username":"aliceb","email":"aliceb@example.com","profile_image_url":"https://example.com/img.png"}'
   ```

**Expected:**

- Status `200 OK`.
- Body: `{"message": "User updated"}`.
- Subsequent `GET /api/v1/user/aliceb` (new username) returns the updated fields.

**Covers:** F1, F13, F22 (all fields written).

---

### S3 — Unauthenticated request

**Steps:**

1. ```bash
   curl -s -X PATCH http://localhost:8000/api/v1/user/alice \
     -H "Content-Type: application/json" \
     -d '{"name":"Alice"}'
   ```

**Expected:**

- Status `401 Unauthorized`.
- Body contains a message indicating missing or invalid credentials.

**Covers:** F2.

---

### S4 — Forbidden: wrong owner

**Steps:**

1. Register both `alice` and `bob`. Obtain `bob`'s token.
2. ```bash
   curl -s -X PATCH http://localhost:8000/api/v1/user/alice \
     -H "Authorization: Bearer <bob_token>" \
     -H "Content-Type: application/json" \
     -d '{"name":"Hacked"}'
   ```

**Expected:**

- Status `403 Forbidden`.
- `alice`'s name is unchanged.

**Covers:** F3, F8.

---

### S5 — Not found: non-existent username

**Steps:**

1. Obtain `alice`'s token.
2. ```bash
   curl -s -X PATCH http://localhost:8000/api/v1/user/nobody \
     -H "Authorization: Bearer <alice_token>" \
     -H "Content-Type: application/json" \
     -d '{"name":"Ghost"}'
   ```

**Expected:**

- Status `404 Not Found`.
- Body contains `"message": "User not found"`.

**Covers:** F4, F7.

---

### S6 — Not found: soft-deleted user

**Steps:**

1. Register `alice`, soft-delete her via `DELETE /api/v1/user/alice`, obtain `alice`'s token (token remains valid).
2. ```bash
   curl -s -X PATCH http://localhost:8000/api/v1/user/alice \
     -H "Authorization: Bearer <alice_token>" \
     -H "Content-Type: application/json" \
     -d '{"name":"Restored"}'
   ```

**Expected:**

- Status `404 Not Found` (adapter filters `is_deleted == False`).

**Covers:** F4, F7, F16, F17.

---

### S7 — Conflict: duplicate email

**Steps:**

1. Register `alice` (`alice@example.com`) and `bob` (`bob@example.com`). Obtain `alice`'s token.
2. ```bash
   curl -s -X PATCH http://localhost:8000/api/v1/user/alice \
     -H "Authorization: Bearer <alice_token>" \
     -H "Content-Type: application/json" \
     -d '{"email":"bob@example.com"}'
   ```

**Expected:**

- Status `409 Conflict`.
- Body contains `"message": "Email is already registered"`.

**Covers:** F5, F9.

---

### S8 — Conflict: duplicate username

**Steps:**

1. Register `alice` and `bob`. Obtain `alice`'s token.
2. ```bash
   curl -s -X PATCH http://localhost:8000/api/v1/user/alice \
     -H "Authorization: Bearer <alice_token>" \
     -H "Content-Type: application/json" \
     -d '{"username":"bob"}'
   ```

**Expected:**

- Status `409 Conflict`.
- Body contains `"message": "Username not available"`.

**Covers:** F5, F10.

---

### S9 — No-op: send the same email (no duplicate error)

**Steps:**

1. Register `alice` (`alice@example.com`) and obtain her token.
2. ```bash
   curl -s -X PATCH http://localhost:8000/api/v1/user/alice \
     -H "Authorization: Bearer <alice_token>" \
     -H "Content-Type: application/json" \
     -d '{"email":"alice@example.com"}'
   ```

**Expected:**

- Status `200 OK` — no conflict raised even though the email "already exists" (it's the same user's own email).

**Covers:** F11 (email_exists not called when value unchanged).

---

### S10 — No-op: send the same username (no duplicate error)

**Steps:**

1. Register `alice` and obtain her token.
2. ```bash
   curl -s -X PATCH http://localhost:8000/api/v1/user/alice \
     -H "Authorization: Bearer <alice_token>" \
     -H "Content-Type: application/json" \
     -d '{"username":"alice"}'
   ```

**Expected:**

- Status `200 OK` — no conflict raised.

**Covers:** F12 (username_exists not called when value unchanged).

---

### S11 — Validation failure: pattern violation

**Steps:**

1. Register `alice` and obtain her token.
2. ```bash
   curl -s -X PATCH http://localhost:8000/api/v1/user/alice \
     -H "Authorization: Bearer <alice_token>" \
     -H "Content-Type: application/json" \
     -d '{"username":"UPPERCASE_NOT_ALLOWED"}'
   ```

**Expected:**

- Status `422 Unprocessable Entity`.
- Body names the `username` field as the failing field.

**Covers:** F6.

---

### S12 — Validation failure: extra field rejected

**Steps:**

1. Register `alice` and obtain her token.
2. ```bash
   curl -s -X PATCH http://localhost:8000/api/v1/user/alice \
     -H "Authorization: Bearer <alice_token>" \
     -H "Content-Type: application/json" \
     -d '{"is_superuser":true}'
   ```

**Expected:**

- Status `422 Unprocessable Entity` — `extra="forbid"` on `UpdateUserRequest`.

**Covers:** F6, N3.

---

## Code review checklist

### Architecture

- [ ] Slice folder exists at `src/app/features/users/update_user/` with `domain/`, `data/`, and `presentation/` subfolders.
- [ ] `src/app/features/users/_shared/` exists and contains `policies.py`.
- [ ] `UpdateUserUseCase` is a class with `async def __call__(self, command: UpdateUserCommand) -> UpdatedUserResult`.
- [ ] `UpdateUserPort` is defined in `domain/ports/update_user_port.py`, decorated with `@runtime_checkable`, inherits from `typing.Protocol`.
- [ ] Adapter class signature is `class UpdateUserAdapter(UpdateUserPort):` — explicit inheritance from the port.
- [ ] Adapter is the only file that imports SQLAlchemy or touches `AsyncSession`.
- [ ] Router builds `UpdateUserCommand` from path param + request body + `current_user["username"]` and returns `UpdateUserResponse`.
- [ ] `check_owner` is imported from `features/users/_shared/policies.py` via relative import in the use case (`from ..._shared.policies import check_owner`).
- [ ] No cross-slice imports outside `features/users/_shared/`.
- [ ] All imports inside `src/app/` are **relative** — no `from app...` or `from src.app...` in any source file.
- [ ] No `HTTPException` raised inside `UpdateUserUseCase` or `check_owner`.
- [ ] No `try/except` in the use case.

### Error handling

- [ ] `UpdateUserAdapter.update` has a narrow `try/except IntegrityError` around `session.commit()` only — not around the entire method body.
- [ ] `UpdateUserAdapter.get_by_username`, `email_exists`, `username_exists` have **no `try/except`** — read-only queries never raise business-meaningful exceptions.
- [ ] The `except IntegrityError` clause re-raises as `raise DuplicateValueDomainError(...) from exc` — cause preserved.
- [ ] Adapter does not call `logger.error` or any logging inside exception handling.
- [ ] No `except Exception` anywhere in the adapter.
- [ ] No new `DomainError` subclass added inside the slice folder — all domain errors live in `app/domain/errors.py`.

### Files and headers

- [ ] `_shared/policies.py` starts with `# FEATURE: users._shared — ownership policy.` on line 1.
- [ ] Every new file in `update_user/` starts with `# FEATURE: update_user — <purpose>` on line 1.
- [ ] No STABLE file was modified except `bootstrap/container.py` (new providers) and `features/users/router.py` (FEATURE file — router swap).
- [ ] `UpdateUserRequest` uses `model_config = ConfigDict(extra="forbid")`.
- [ ] No `model.dict()` calls anywhere — only `model.model_dump()`.

### DI wiring

- [ ] `update_user_adapter` provider added to `Container` in `bootstrap/container.py`.
- [ ] `update_user_use_case` provider added to `Container`, taking `port=update_user_adapter`.
- [ ] Router uses the `_get_update_user_use_case()` helper function pattern (lazy container import, matching the pattern in `create_user`, `list_users`, `get_user_by_username`).
- [ ] `features/users/router.py` uses `router.include_router(update_user_router)` instead of direct function registration.

### Deleted / cleaned up

- [ ] `src/app/features/users/use_cases/user_update.py` is deleted.
- [ ] `UserUpdate` from `features/users/schemas.py` is removed if no remaining file references it (check before deleting).

### Tests

- [ ] Policy unit test exists at `tests/features/users/_shared/test_policies.py` and covers F14 and F15.
- [ ] Use-case unit test exists at `tests/features/users/0006_update_user/domain/test_use_case.py` and covers F7–F13.
- [ ] Adapter unit test exists at `tests/features/users/0006_update_user/data/test_adapter.py` and covers F16–F22 plus propagation of unexpected exceptions.
- [ ] Endpoint integration test exists at `tests/features/users/0006_update_user/presentation/test_router.py` and covers F1–F6.
- [ ] Outside-in test exists at `tests/features/users/0006_update_user/update_user_outside_in_test.py` and is GREEN.
- [ ] No test calls `session.commit()` directly (defeats transaction rollback fixture).
- [ ] All integration tests use the `client` fixture (not a fresh `AsyncClient` constructed inline).

### Quality gates

Run in order from the project root — all must pass before the slice is done:

```bash
ruff format src/app tests
ruff check src/app tests
mypy src/app
pytest
```

The `pytest` run includes `tests/smoke/test_app_starts.py`, which boots the app via `uvicorn` in a subprocess and pings `/api/v1/health`. If the smoke test fails while other tests pass, the most likely cause is an accidental `from app...` absolute import inside `src/app/` (works under pytest's `pythonpath=["src"]` but breaks under uvicorn). Fix the import, not the test.
