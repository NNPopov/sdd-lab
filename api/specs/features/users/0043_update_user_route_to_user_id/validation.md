# 0043 · update_user_route_to_user_id — Validation

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md
- Requirements: ./requirements.md

## Prerequisites

- App running locally (`uvicorn app.main:app --reload` from `src/`).
- Test Postgres running (`docker compose up test-db -d`).
- A registered user whose `id` you know. The scripts `create_first_superuser`
  and `create_first_tier` must have been run at least once.
- A valid Bearer token obtained via `POST /api/v1/login`.

For clarity, the examples below use these placeholders:

- `$TOKEN_A` — JWT for user A (owns profile with `user_id=1`)
- `$TOKEN_B` — JWT for user B (a different, already-registered user)
- `$USER_A_ID` — integer primary key of user A
- `$USER_B_ID` — integer primary key of user B

---

## Manual scenarios

### S1 — Happy path: update own profile by integer ID

**Steps:**

1. Register user A and note the returned `id`.
2. Log in as A to obtain `$TOKEN_A`.
3. Send:
   ```
   curl -X PATCH http://localhost:8000/api/v1/user/$USER_A_ID \
     -H "Authorization: Bearer $TOKEN_A" \
     -H "Content-Type: application/json" \
     -d '{"name": "Alice Updated"}'
   ```

**Expected:**

- Status 200.
- Body: `{"message": "User updated"}`.
- `GET /api/v1/user/$USER_A_ID` reflects the new name.

**Covers:** F1, F11, F15.

---

### S2 — Non-integer `user_id` in path

**Steps:**

1. Send:
   ```
   curl -X PATCH http://localhost:8000/api/v1/user/alice \
     -H "Authorization: Bearer $TOKEN_A" \
     -H "Content-Type: application/json" \
     -d '{"name": "Alice"}'
   ```

**Expected:**

- Status 422.
- Body contains a `detail` array naming the path parameter.

**Covers:** F2.

---

### S3 — Missing token (unauthenticated)

**Steps:**

1. Send without `Authorization` header:
   ```
   curl -X PATCH http://localhost:8000/api/v1/user/$USER_A_ID \
     -H "Content-Type: application/json" \
     -d '{"name": "Alice"}'
   ```

**Expected:**

- Status 401.

**Covers:** F3.

---

### S4 — Not found: `user_id` does not exist

**Steps:**

1. Send with an ID that has never been inserted (e.g., 999999):
   ```
   curl -X PATCH http://localhost:8000/api/v1/user/999999 \
     -H "Authorization: Bearer $TOKEN_A" \
     -H "Content-Type: application/json" \
     -d '{"name": "Ghost"}'
   ```

**Expected:**

- Status 404.
- Body: `{"error": {"code": "notfound", "message": "User not found"}}`.

**Covers:** F4, F14.

---

### S5 — Forbidden: updating another user's profile

**Steps:**

1. Log in as user B to obtain `$TOKEN_B`.
2. Send (using A's ID but B's token):
   ```
   curl -X PATCH http://localhost:8000/api/v1/user/$USER_A_ID \
     -H "Authorization: Bearer $TOKEN_B" \
     -H "Content-Type: application/json" \
     -d '{"name": "Hijack"}'
   ```

**Expected:**

- Status 403.
- Body: `{"error": {"code": "forbidden", "message": ""}}`.

**Covers:** F5, F13, F14.

---

### S6 — Conflict: duplicate email

**Steps:**

1. Register two users with different emails (e.g., `a@a.com` and `b@b.com`).
2. Log in as user A.
3. Send:
   ```
   curl -X PATCH http://localhost:8000/api/v1/user/$USER_A_ID \
     -H "Authorization: Bearer $TOKEN_A" \
     -H "Content-Type: application/json" \
     -d '{"email": "b@b.com"}'
   ```

**Expected:**

- Status 409.
- Body: `{"error": {"code": "duplicatevalue", "message": "Email is already registered"}}`.

**Covers:** F6, F14.

---

### S7 — Conflict: duplicate username

**Steps:**

1. Register user B with username `bob`.
2. Log in as user A.
3. Send:
   ```
   curl -X PATCH http://localhost:8000/api/v1/user/$USER_A_ID \
     -H "Authorization: Bearer $TOKEN_A" \
     -H "Content-Type: application/json" \
     -d '{"username": "bob"}'
   ```

**Expected:**

- Status 409.
- Body: `{"error": {"code": "duplicatevalue", "message": "Username not available"}}`.

**Covers:** F8, F14.

---

### S8 — Field validation failure (Pydantic)

**Steps:**

1. Send with a username that violates the regex:
   ```
   curl -X PATCH http://localhost:8000/api/v1/user/$USER_A_ID \
     -H "Authorization: Bearer $TOKEN_A" \
     -H "Content-Type: application/json" \
     -d '{"username": "UPPERCASE"}'
   ```

**Expected:**

- Status 422.
- Body contains `detail` naming the `username` field violation.

**Covers:** F2 (field-level constraint from `UpdateUserRequest`).

---

### S9 — Update with no payload fields changed (no-op)

**Steps:**

1. Send with an empty body (all fields `null` / omitted):
   ```
   curl -X PATCH http://localhost:8000/api/v1/user/$USER_A_ID \
     -H "Authorization: Bearer $TOKEN_A" \
     -H "Content-Type: application/json" \
     -d '{}'
   ```

**Expected:**

- Status 200.
- Body: `{"message": "User updated"}`.
- DB row unchanged (no fields written, only `updated_at` may update).

**Covers:** F1, F7, F9.

---

## Code review checklist

### Architecture

- [ ] `update_user` slice files are modified in place; no new slice folder was created.
- [ ] `UpdateUserUseCase` is a class with `__call__(command: UpdateUserCommand) -> UpdatedUserResult`.
- [ ] `UpdateUserPort` lives in `domain/ports/update_user_port.py`, carries `@runtime_checkable`, inherits `Protocol`.
- [ ] `UpdateUserAdapter` class signature is `class UpdateUserAdapter(UpdateUserPort):` — explicit inheritance.
- [ ] `UpdateUserAdapter` is the only file that uses SQLAlchemy directly; `domain/` and `presentation/` have no ORM imports.
- [ ] Router accepts `UpdateUserRequest`, constructs `UpdateUserCommand`, awaits use-case, returns `UpdateUserResponse`.
- [ ] No cross-slice imports outside `features/users/_shared/`.
- [ ] All imports inside `src/app/` are **relative** (`from ..domain...`, `from ...._shared...`). No `from app...` or `from src.app...` inside source.
- [ ] No `HTTPException` raised inside `UpdateUserUseCase`.
- [ ] `check_owner` in `_shared/policies.py` now takes two `int` parameters; no `str`-based comparison remains.

### Error handling

- [ ] `UpdateUserAdapter.update` wraps only `session.commit()` in a narrow `try/except IntegrityError` — not the entire method body.
- [ ] `get_by_id`, `email_exists`, `username_exists` have **no `try/except`**.
- [ ] Each `except` clause names a specific exception type (`IntegrityError`), not `Exception`.
- [ ] `raise DuplicateValueDomainError(...) from exc` preserves the cause.
- [ ] `UpdateUserAdapter` does **not** log exceptions.
- [ ] No new `DomainError` subclass was added inside the slice. Existing subclasses (`NotFoundDomainError`, `ForbiddenDomainError`, `DuplicateValueDomainError`) are the only ones used.

### Files and headers

- [ ] Every modified `.py` file retains its `# FEATURE:` header on line 1.
- [ ] No STABLE file was modified beyond `bootstrap/container.py` wiring entries (if any were needed — per plan, none were required for this slice).
- [ ] `ExistingUser` now has `id: int`, `username: str`, `email: str` — no fields removed, one added.
- [ ] `UpdateUserCommand` has `target_user_id: int` and `requester_user_id: int` — `target_username` and `requester_username` are gone.

### DI

- [ ] `bootstrap/container.py` `update_user_adapter` and `update_user_use_case` providers unchanged (no import path changes needed).
- [ ] `Container.wiring_config.modules` still includes `update_user` router module.
- [ ] Endpoint still uses `Annotated[UpdateUserUseCase, Depends(Provide[Container.update_user_use_case])]`.

### Tests

- [ ] Use-case unit test updated/created at `tests/features/users/0043_update_user_route_to_user_id/domain/test_use_case.py`; all branches pass.
- [ ] Adapter unit test updated/created at `tests/features/users/0043_update_user_route_to_user_id/data/test_adapter.py`; `IntegrityError` → `DuplicateValueDomainError` translation verified; propagation of unexpected exceptions verified.
- [ ] Endpoint integration test updated/created at `tests/features/users/0043_update_user_route_to_user_id/presentation/test_router.py`; all 8 status code scenarios covered.
- [ ] Outside-in test at `tests/features/users/0043_update_user_route_to_user_id/update_user_route_to_user_id_outside_in_test.py` is GREEN.
- [ ] `conftest.py` uses savepoint-mode rollback (`join_transaction_mode="create_savepoint"`); no test leaves rows in the DB.
- [ ] Old slice 0006 tests (`tests/features/users/0006_update_user/`) are updated (or removed) to reflect the new integer-based command and port; they still pass.

### Quality gates

Run from project root:

```
ruff format src/app tests
ruff check src/app tests
mypy src/app
pytest
```

All must pass. Pay particular attention to `tests/smoke/test_app_starts.py` — if it fails after modifying relative imports in the existing `update_user` files, an import is using the wrong convention for its layer.
