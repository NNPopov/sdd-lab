# 0041 · get_user_by_id — Validation

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md
- Requirements: ./requirements.md

## Prerequisites

- App running locally (`uvicorn app.main:app --reload` from `src/`).
- Test Postgres running (`docker compose up test-db -d`).
- No prior `alice` user in the database, or use a fresh DB.

## Manual scenarios

### S1 — Happy path: existing user returns 200 with all fields

**Steps:**

1. Create a user to obtain a known ID:
   ```
   curl -s -X POST http://localhost:8000/api/v1/users \
     -H "Content-Type: application/json" \
     -d '{"username": "alice", "name": "Alice", "email": "alice@example.com", "password": "Pa$$w0rd1"}' \
     | jq '{id, username}'
   ```
   Note the returned `id` (e.g. `42`).

2. Retrieve the user by ID:
   ```
   curl -s http://localhost:8000/api/v1/user/42 | jq .
   ```

**Expected:**

- Status 200.
- Body contains all seven fields: `id`, `name`, `username`, `email`,
  `profile_image_url`, `tier_id`, `is_moderator`.
- `id` matches the value captured in step 1.
- No authentication header is required.

**Covers:** F1, F2, F11.

---

### S2 — Not found: non-existent ID returns 404

**Steps:**

1. Use an ID that does not exist in the database (e.g. `999999`):
   ```
   curl -s -o /dev/null -w "%{http_code}" \
     http://localhost:8000/api/v1/user/999999
   ```

2. Check the response body:
   ```
   curl -s http://localhost:8000/api/v1/user/999999 | jq .
   ```

**Expected:**

- Status 404.
- Body: `{"error": {"code": "notfound", "message": "User not found"}}`.

**Covers:** F3.

---

### S3 — Non-integer path value returns 422

**Steps:**

1. Pass a string where an integer is expected:
   ```
   curl -s http://localhost:8000/api/v1/user/alice | jq .
   ```

**Expected:**

- Status 422.
- Body contains FastAPI validation error detail (Pydantic coercion failure for
  `user_id`).

**Covers:** F4.

---

### S4 — Soft-deleted user returns 404

**Steps:**

1. Create a user (step 1 from S1); note the `id`.
2. Soft-delete the user via the delete endpoint:
   ```
   curl -s -X DELETE \
     -H "Authorization: Bearer <superuser_token>" \
     http://localhost:8000/api/v1/user/alice
   ```
3. Call `GET /user/{id}`:
   ```
   curl -s http://localhost:8000/api/v1/user/42 | jq .
   ```

**Expected:**

- Status 404.
- Body: `{"error": {"code": "notfound", "message": "User not found"}}`.

**Covers:** F3 (soft-delete variant), F7 (is_deleted filter active).

---

### S5 — Old route is gone (no redirect)

**Steps:**

1. Ensure `alice` exists (from S1).
2. Call the old username-based route:
   ```
   curl -s http://localhost:8000/api/v1/user/alice | jq .
   ```

**Expected:**

- Status 422 (FastAPI cannot coerce `"alice"` to `int` for `user_id`).
- No redirect, no 404 — the endpoint now requires an integer.

**Covers:** F10.

---

## Code review checklist

### Architecture

- [ ] Slice folder exists at `src/app/features/users/get_user_by_id/` with
      `domain/`, `data/`, `presentation/` subfolders.
- [ ] `GetUserByIdUseCase` is a class with `__call__()`, takes
      `GetUserByIdQuery`, returns `FoundUser`.
- [ ] `GetUserByIdPort` lives in `domain/ports/get_user_by_id_port.py`, has
      `@runtime_checkable` decorator, inherits from `typing.Protocol`.
- [ ] `GetUserByIdAdapter` class signature is
      `class GetUserByIdAdapter(GetUserByIdPort):` — explicit inheritance from
      the port.
- [ ] `GetUserByIdAdapter` is the only file that imports SQLAlchemy ORM.
- [ ] Router accepts `user_id: int` path parameter, constructs
      `GetUserByIdQuery(user_id=user_id)`, awaits use-case, returns
      `GetUserByIdResponse`.
- [ ] No cross-slice imports outside `_shared/`.
- [ ] All imports inside `src/app/features/users/get_user_by_id/` are
      **relative** — no `from app...` or `from src.app...` anywhere in source.
- [ ] No `HTTPException` raised inside `GetUserByIdUseCase`.

### Error handling

- [ ] `GetUserByIdAdapter.get` has **no `try/except`** — it is a read-only
      query with no business-meaningful infrastructure exception to translate.
- [ ] `NotFoundDomainError` is raised in `GetUserByIdUseCase`, not in the
      adapter.
- [ ] No new `DomainError` subclass was added inside the slice folder.

### Files and headers

- [ ] Every new `.py` file under `get_user_by_id/` starts with
      `# FEATURE: get_user_by_id — <purpose>` on line 1.
- [ ] No STABLE file was modified beyond the permitted entries:
      `bootstrap/container.py` (providers + wiring_config) and `.importlinter`
      (router ignore entry).
- [ ] `GetUserByIdResponse` uses `model_config = ConfigDict(from_attributes=True)`.
- [ ] No `model.dict()` — only `model.model_dump()` if used.

### Old slice removed

- [ ] The entire `src/app/features/users/get_user_by_username/` folder is
      deleted.
- [ ] `grep -r "get_user_by_username" src/` returns zero results.
- [ ] `features/users/router.py` imports `get_user_by_id_router`, not
      `get_user_by_username_router`.

### DI

- [ ] `get_user_by_id_adapter` provider added to `Container`.
- [ ] `get_user_by_id_use_case` provider added to `Container`, wired to
      `get_user_by_id_adapter`.
- [ ] `features.users.get_user_by_id.presentation.router` added to
      `Container.wiring_config.modules`.
- [ ] Endpoint uses
      `Annotated[GetUserByIdUseCase, Depends(Provide[Container.get_user_by_id_use_case])]`.

### `.importlinter`

- [ ] Old `app.features.users.get_user_by_username.presentation.router ->
      app.bootstrap.container` entry replaced with
      `app.features.users.get_user_by_id.presentation.router ->
      app.bootstrap.container`.

### Tests

- [ ] Use-case unit test exists at
      `tests/features/users/0041_get_user_by_id/domain/test_use_case.py` and
      covers both branches (found, not-found).
- [ ] Adapter unit test exists at
      `tests/features/users/0041_get_user_by_id/data/test_adapter.py` and
      covers found, not-found, and soft-deleted cases.
- [ ] Endpoint integration test exists at
      `tests/features/users/0041_get_user_by_id/presentation/test_router.py`
      and covers 200, 404, 422.
- [ ] Outside-in test exists at
      `tests/features/users/0041_get_user_by_id/get_user_by_id_outside_in_test.py`
      and is GREEN.
- [ ] Test `conftest.py` uses `oit_engine` + `async_client` savepoint-rollback
      pattern from `agent_docs/testing.md`.
- [ ] No test leaves rows committed to the database.

### Quality gates

Run from project root:

```
ruff format src/app tests
ruff check src/app tests
mypy src/app
pytest
```

All must pass, including `tests/smoke/test_app_starts.py` (app boots under
uvicorn and responds on `/api/v1/health`). The smoke test is the only check
that catches a relative-vs-absolute import inconsistency that works under
pytest but breaks under uvicorn.
