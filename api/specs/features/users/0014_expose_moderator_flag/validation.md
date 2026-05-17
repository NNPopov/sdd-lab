# 0014 · expose_moderator_flag — Validation

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md
- Requirements: ./requirements.md

## Prerequisites

- App running locally (`uvicorn app.main:app --reload` from the project root).
- Test Postgres started (`docker compose up test-db -d` or equivalent).
- Alembic migrations applied (`alembic upgrade head`), including the 0013
  migration that adds `is_moderator` to the `user` table.
- A registered, non-deleted user account available. Keep its `id` handy for
  the direct-DB moderator-flag scenarios.
- A valid Bearer token for that account (obtained via the login endpoint).

---

## Manual scenarios

### S1 — GET /user/{username}: non-moderator user returns `is_moderator: false`

**Steps:**

1. Create a user (if not already seeded):
   ```
   curl -s -X POST http://localhost:8000/api/v1/users \
     -H "Content-Type: application/json" \
     -d '{"username": "alice", "email": "alice@example.com", "password": "Pa$$w0rd1"}' | python -m json.tool
   ```
2. Call the get-by-username endpoint:
   ```
   curl -s http://localhost:8000/api/v1/user/alice | python -m json.tool
   ```

**Expected:**

- Status `200`.
- Response body includes `"is_moderator": false`.
- The field is present (not absent or null).

**Covers:** F5, F7, F12.

---

### S2 — GET /user/{username}: moderator user returns `is_moderator: true`

**Steps:**

1. Using the `id` of `alice` from S1, set `is_moderator=true` directly in the DB:
   ```sql
   UPDATE "user" SET is_moderator = TRUE WHERE username = 'alice';
   ```
2. Call the get-by-username endpoint again:
   ```
   curl -s http://localhost:8000/api/v1/user/alice | python -m json.tool
   ```

**Expected:**

- Status `200`.
- Response body includes `"is_moderator": true`.

**Cleanup:** `UPDATE "user" SET is_moderator = FALSE WHERE username = 'alice';`

**Covers:** F6, F12.

---

### S3 — GET /user/{username}: no authentication required

**Steps:**

1. Call the endpoint with no `Authorization` header:
   ```
   curl -s http://localhost:8000/api/v1/user/alice | python -m json.tool
   ```

**Expected:**

- Status `200`.
- `is_moderator` is present in the response (same value as the DB).
- No 401 response.

**Covers:** F7.

---

### S4 — GET /user/me/: non-moderator user returns `is_moderator: false`

**Steps:**

1. Ensure `alice` has `is_moderator = FALSE` in the DB.
2. Log in to obtain a Bearer token:
   ```
   curl -s -X POST http://localhost:8000/api/v1/auth/login \
     -H "Content-Type: application/x-www-form-urlencoded" \
     -d "username=alice&password=Pa%24%24w0rd1" | python -m json.tool
   ```
3. Call the me endpoint with the token:
   ```
   curl -s http://localhost:8000/api/v1/user/me/ \
     -H "Authorization: Bearer <TOKEN>" | python -m json.tool
   ```

**Expected:**

- Status `200`.
- Response body includes `"is_moderator": false`.
- `is_superuser` is also present (existing field — must not be dropped).

**Covers:** F9, F12.

---

### S5 — GET /user/me/: moderator user returns `is_moderator: true`

**Steps:**

1. Set `is_moderator=TRUE` for `alice` in the DB (see S2).
2. Log in and obtain a fresh token (or reuse from S4 if still valid).
3. Call the me endpoint:
   ```
   curl -s http://localhost:8000/api/v1/user/me/ \
     -H "Authorization: Bearer <TOKEN>" | python -m json.tool
   ```

**Expected:**

- Status `200`.
- Response body includes `"is_moderator": true`.

**Cleanup:** Reset `alice` to non-moderator.

**Covers:** F10, F12.

---

### S6 — GET /users: list endpoint does NOT include `is_moderator`

**Steps:**

1. Call the list-users endpoint (requires superuser token or whichever auth the endpoint uses):
   ```
   curl -s "http://localhost:8000/api/v1/users?page=1&items_per_page=10" \
     -H "Authorization: Bearer <SUPERUSER_TOKEN>" | python -m json.tool
   ```

**Expected:**

- Status `200`.
- Each object in the returned `data` array does **not** contain an `is_moderator` key.

**Covers:** F11.

---

### S7 — Existing 404 path is unaffected

**Steps:**

1. Call get-by-username for a non-existent user:
   ```
   curl -s http://localhost:8000/api/v1/user/doesnotexist_xyz | python -m json.tool
   ```

**Expected:**

- Status `404`.
- Body `{"message": "User not found"}`.
- Behavior is identical to pre-slice behavior.

**Covers:** regression check — no new error paths introduced.

---

## Code review checklist

This slice modifies five existing FEATURE files and introduces no new files,
use-cases, ports, adapters, or DI providers. The checklist is scoped accordingly.

### Slice-specific changes

- [ ] **F1 / F2 — `FoundUser` entity:** `is_moderator: bool` added to
      `get_user_by_username/domain/entities.py`. Field has no default
      (required) and no `Optional` wrapper.
- [ ] **F3 / F4 — Router mapping:** `GetUserByUsernameResponse(...)` in
      `get_user_by_username/presentation/router.py` passes
      `is_moderator=entity.is_moderator` as an explicit keyword argument.
      No field is omitted or set to a literal.
- [ ] **F3 — Response schema:** `is_moderator: bool` added to
      `GetUserByUsernameResponse` in
      `get_user_by_username/presentation/schemas.py`.
- [ ] **F2 — Adapter mapping:** `GetUserByUsernameAdapter.get()` in
      `get_user_by_username/data/adapter.py` passes
      `is_moderator=row.is_moderator` to `FoundUser(...)`. No query
      change and no `try/except` added.
- [ ] **F8 — `UserMeRead`:** `is_moderator: bool` added to `UserMeRead` in
      `features/users/schemas.py`. Field sits alongside `is_superuser`.
      `UserRead` (base class) is unchanged.
- [ ] **F11 — `UserRead` untouched:** `diff features/users/schemas.py` shows
      that `UserRead` fields are identical to pre-slice. `is_moderator` must
      appear only in `UserMeRead`.

### Error handling

- [ ] `GetUserByUsernameAdapter.get()` has no `try/except` block after this
      change (read-only query; per `agent_docs/error_handling.md` § Right
      shape: read-only query, no catch).
- [ ] No `HTTPException` is raised in any modified file at the use-case or
      adapter layer. Per CLAUDE.md § Universal hard rules.

### Files and headers

- [ ] All five modified files retain their `# FEATURE:` header on line 1;
      none has been accidentally stripped or changed to `# STABLE:`. Per
      `agent_docs/stable_vs_feature.md`.
- [ ] No STABLE file was modified. The list of touched files is exactly:
      `get_user_by_username/domain/entities.py`,
      `get_user_by_username/data/adapter.py`,
      `get_user_by_username/presentation/schemas.py`,
      `get_user_by_username/presentation/router.py`,
      `features/users/schemas.py` — nothing else.
- [ ] `GetUserByUsernameResponse` retains
      `model_config = ConfigDict(from_attributes=True)`. Per
      `agent_docs/entry_points/fastapi.md` § Request and Response schemas.

### Architecture

- [ ] No cross-slice imports introduced. `features/users/schemas.py` is
      shared within the `users` feature; modifying `UserMeRead` there is
      permitted. Per `agent_docs/architecture.md` § `_shared/` rules.
- [ ] All imports inside the modified source files remain **relative**
      (`from ..domain...`, `from ...._shared...`). No `from app...` inside
      `src/app/`. Per `agent_docs/architecture.md` § Import conventions.

### Tests

- [ ] Adapter unit test exists at
      `tests/features/users/0014_expose_moderator_flag/data/test_adapter.py`
      and covers both `is_moderator=False` and `is_moderator=True`.
- [ ] Endpoint integration tests exist at
      `tests/features/users/0014_expose_moderator_flag/presentation/test_router.py`
      and cover all four cases (two endpoints × two moderator flag values).
- [ ] Outside-in test at
      `tests/features/users/0014_expose_moderator_flag/expose_moderator_flag_outside_in_test.py`
      is GREEN. This is the acceptance gate; the slice is not done until it
      passes.
- [ ] The existing outside-in test for slice 0004
      (`tests/features/users/0004_get_user_by_username/get_user_by_username_outside_in_test.py`)
      is still GREEN after this change (additive field — should not break
      existing tests unless they assert an exact schema with no extra fields).

### Quality gates

Run from project root before approving:

```
ruff format src/app tests
ruff check src/app tests
mypy src/app
pytest
```

All must pass, including `tests/smoke/test_app_starts.py` (boots the app in
a subprocess and pings `/api/v1/health`). A smoke failure usually means a
relative-import rule was violated in a modified file.
