# 0044 · delete_user_route_to_user_id — Validation

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md
- Requirements: ./requirements.md

## Prerequisites

- App running locally: `cd src && uvicorn app.main:app --reload`
- Postgres accessible; schema up-to-date (`alembic upgrade head`).
- Redis running (required for token blacklisting).
- Two test users registered with known IDs. Use the create-user endpoint or the
  seed script. Capture `alice_id` and `bob_id` from the registration responses.
- A valid access token for alice obtained via the login endpoint.

```bash
# Register alice (note the returned id field):
curl -s -X POST http://localhost:8000/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{"username":"alice","email":"alice@example.com","password":"Pa$$w0rd1"}' \
  | python -m json.tool
# → { "id": 42, "username": "alice", ... }  ← capture alice_id

# Register bob:
curl -s -X POST http://localhost:8000/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{"username":"bob","email":"bob@example.com","password":"Pa$$w0rd2"}' \
  | python -m json.tool
# → { "id": 43, ... }  ← capture bob_id

# Login as alice:
curl -s -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=alice&password=Pa%24%24w0rd1" \
  | python -m json.tool
# → { "access_token": "<alice_token>", ... }
```

---

## Manual scenarios

### S1 — Happy path: owner deletes their own account

**Steps:**

1. Obtain `alice_id` and `alice_token` from prerequisites.
2. Send:

```bash
curl -s -X DELETE http://localhost:8000/api/v1/user/<alice_id> \
  -H "Authorization: Bearer <alice_token>" \
  | python -m json.tool
```

**Expected:**

- HTTP 200.
- Body: `{"message": "User deleted"}`.
- DB: alice's row has `is_deleted = true` and `deleted_at` is non-null.
- DB: `alice_token` value appears in the `token_blacklist` table.

**Covers:** F1, F4, F5, F6, F7, F9, F10, F11, F12.

---

### S2 — Token is invalidated: reusing the blacklisted token returns 401

**Steps:**

1. Complete S1 (alice's token is now blacklisted).
2. Repeat the same DELETE request using the same `alice_token`:

```bash
curl -s -X DELETE http://localhost:8000/api/v1/user/<alice_id> \
  -H "Authorization: Bearer <alice_token>" \
  | python -m json.tool
```

**Expected:**

- HTTP 401.
- The re-used token is rejected before the use-case is reached.

**Covers:** F3, F12.

---

### S3 — Missing authentication token

**Steps:**

1. Send the delete request without any `Authorization` header:

```bash
curl -s -X DELETE http://localhost:8000/api/v1/user/<alice_id> \
  | python -m json.tool
```

**Expected:**

- HTTP 401.

**Covers:** F3.

---

### S4 — Forbidden: alice tries to delete bob's account

**Steps:**

1. Obtain `alice_token` (fresh — alice not yet deleted) and `bob_id`.
2. Send:

```bash
curl -s -X DELETE http://localhost:8000/api/v1/user/<bob_id> \
  -H "Authorization: Bearer <alice_token>" \
  | python -m json.tool
```

**Expected:**

- HTTP 403.
- Body: `{"error": {"code": "forbidden", "message": ""}}`.
- DB: bob's row is unchanged — `is_deleted` remains `false`.
- DB: `alice_token` does **not** appear in `token_blacklist` (blacklisting only
  happens after a successful use-case return).

**Covers:** F6, F8, F14.

---

### S5 — Not found: deleting a non-existent user_id

**Steps:**

1. Obtain `alice_token`.
2. Send a request with an ID that does not exist (e.g. `999999`):

```bash
curl -s -X DELETE http://localhost:8000/api/v1/user/999999 \
  -H "Authorization: Bearer <alice_token>" \
  | python -m json.tool
```

**Expected:**

- HTTP 404.
- Body: `{"error": {"code": "notfound", "message": "User not found"}}`.

**Covers:** F4, F5, F13.

---

### S6 — Unprocessable: non-integer path param

**Steps:**

1. Send a request with a string path param:

```bash
curl -s -X DELETE http://localhost:8000/api/v1/user/alice \
  -H "Authorization: Bearer <alice_token>" \
  | python -m json.tool
```

**Expected:**

- HTTP 422.
- Body contains Pydantic validation error indicating `user_id` must be an
  integer.

**Covers:** F2.

---

## Code review checklist

### Architecture

- [ ] The existing `delete_user` slice folder at
      `src/app/features/users/delete_user/` retains its `domain/`, `data/`,
      `presentation/` layout — no new folders added, none removed.
- [ ] `DeleteUserUseCase` is a class with a single `__call__()` method that
      accepts `DeleteUserCommand` and returns `DeleteUserResult`.
- [ ] `DeleteUserPort` lives in `domain/ports/delete_user_port.py`, carries
      `@runtime_checkable`, and inherits from `typing.Protocol`.
- [ ] `DeleteUserAdapter` signature is `class DeleteUserAdapter(DeleteUserPort):`
      — explicit inheritance from the port is mandatory.
- [ ] The adapter is the only place SQLAlchemy (`select`, `update`) is used.
- [ ] The router accepts `user_id: int` path param, converts to
      `DeleteUserCommand(target_user_id=user_id, requester_user_id=current_user["id"])`,
      awaits the use-case, then calls `blacklist_token`, and finally returns
      `DeleteUserResponse`.
- [ ] No cross-slice imports outside `users/_shared/`.
- [ ] All imports inside `src/app/` are **relative** (e.g.
      `from ..domain.commands import DeleteUserCommand`). No `from app...`
      or `from src.app...` inside source files.
- [ ] No `HTTPException` raised inside the use-case.
- [ ] `check_owner` in `users/_shared/policies.py` now accepts `(int, int)`
      — no string comparison remains.

### Error handling

- [ ] `DeleteUserAdapter.get_by_id` has **no `try/except`** — it is a
      read-only lookup with nothing business-meaningful to translate.
- [ ] `DeleteUserAdapter.soft_delete` has **no `try/except`** — an UPDATE by
      primary key has no unique-constraint path.
- [ ] No broad `except Exception` blocks in any modified file.
- [ ] The adapter does not log exceptions.
- [ ] No new `DomainError` subclass was introduced in the slice folder; only
      the existing `NotFoundDomainError` and `ForbiddenDomainError` from
      `app/domain/errors.py` are raised.

### Files and headers

- [ ] All modified FEATURE files retain their `# FEATURE: <slice> — <purpose>`
      header on line 1.
- [ ] No STABLE files were modified. `bootstrap/container.py` and
      `bootstrap/router.py` are **not** touched (providers and router
      registration already exist from slice 0007).
- [ ] `DeleteUserResponse` retains `model_config = ConfigDict(from_attributes=True)`
      if it is validated from an ORM-derived object; otherwise verify it
      matches the existing schema.

### DI

- [ ] `delete_user_adapter` and `delete_user_use_case` providers in
      `bootstrap/container.py` are unchanged (they already exist).
- [ ] `delete_user.presentation.router` module path remains in
      `Container.wiring_config.modules` (already present).
- [ ] Endpoint still uses
      `Annotated[DeleteUserUseCase, Depends(Provide[Container.delete_user_use_case])]`.

### Tests

- [ ] `tests/features/users/0007_delete_user/domain/test_use_case.py` updated
      to use `get_by_id` / `DeleteUserCommand(target_user_id=..., requester_user_id=...)`
      / `DeleteUserTarget(id=...)` and passes.
- [ ] `tests/features/users/0007_delete_user/data/test_adapter.py` updated to
      call `get_by_id(int)` and `soft_delete(int)` and passes.
- [ ] `tests/features/users/0007_delete_user/presentation/test_router.py`
      updated to use `/api/v1/user/{id}` paths and includes a 422 case for a
      non-integer `user_id`; passes.
- [ ] `tests/features/users/0007_delete_user/delete_user_outside_in_test.py`
      updated to use `seeded_alice["id"]` / `seeded_bob["id"]` in the URL and
      passes (GREEN).
- [ ] Test DB transaction rollback works — no test leaves rows in the DB.

### Quality gates

Run from the project root:

```bash
ruff format src/app tests
ruff check src/app tests
mypy src/app
pytest
```

All must pass. The smoke test (`tests/smoke/test_app_starts.py`) is included in
`pytest` and boots the app via a real `uvicorn` subprocess. If it fails the
slice is **not done**, even if every other test is green — it catches import
paths that work under pytest but break under uvicorn.
