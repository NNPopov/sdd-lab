# 0045 · delete_db_user_route_to_user_id — Validation

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md
- Requirements: ./requirements.md

## Prerequisites

- App running locally: `cd src && uvicorn app.main:app --reload`
- Postgres accessible; schema up-to-date (`alembic upgrade head`).
- A superuser account exists (seed with `python -m scripts.create_first_superuser`).
- A regular (non-superuser) user registered with a known ID. Capture
  `target_id` from its registration response.
- A valid access token for the superuser, and a separate token for the regular
  user.

```bash
# Register a regular target user (note the returned id field):
curl -s -X POST http://localhost:8000/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{"username":"victim","email":"victim@example.com","password":"Pa$$w0rd1"}' \
  | python -m json.tool
# → { "id": 42, "username": "victim", ... }  ← capture target_id

# Login as the superuser:
curl -s -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=<superuser_name>&password=<superuser_password>" \
  | python -m json.tool
# → { "access_token": "<super_token>", ... }

# Login as the regular user:
curl -s -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=victim&password=Pa%24%24w0rd1" \
  | python -m json.tool
# → { "access_token": "<victim_token>", ... }
```

---

## Manual scenarios

### S1 — Happy path: superuser hard-deletes a user by id

**Steps:**

1. Obtain `target_id` and `super_token` from prerequisites.
2. Send:

```bash
curl -s -X DELETE http://localhost:8000/api/v1/db_user/<target_id> \
  -H "Authorization: Bearer <super_token>" \
  | python -m json.tool
```

**Expected:**

- HTTP 200.
- Body: `{"message": "User deleted from the database"}`.
- DB: the target row is **gone** from the `users` table (hard delete, not a flag).

**Covers:** F1, F5, F6, F7, F8, F9, F10.

---

### S2 — Not found: deleting a non-existent user_id

**Steps:**

1. Obtain `super_token`.
2. Send a request with an ID that does not exist (e.g. `999999`):

```bash
curl -s -X DELETE http://localhost:8000/api/v1/db_user/999999 \
  -H "Authorization: Bearer <super_token>" \
  | python -m json.tool
```

**Expected:**

- HTTP 404.
- Body: `{"error": {"code": "notfound", "message": "User not found"}}`.

**Covers:** F6, F12.

---

### S3 — Forbidden: regular user attempts the hard delete

**Steps:**

1. Obtain `victim_token` (a valid non-superuser token) and a `target_id`.
2. Send:

```bash
curl -s -X DELETE http://localhost:8000/api/v1/db_user/<target_id> \
  -H "Authorization: Bearer <victim_token>" \
  | python -m json.tool
```

**Expected:**

- HTTP 403.
- DB: the target row is unchanged — still present.

**Covers:** F4.

---

### S4 — Missing authentication token

**Steps:**

1. Send the delete request without any `Authorization` header:

```bash
curl -s -X DELETE http://localhost:8000/api/v1/db_user/<target_id> \
  | python -m json.tool
```

**Expected:**

- HTTP 401.

**Covers:** F3.

---

### S5 — Unprocessable: non-integer path param

**Steps:**

1. Send a request with a string path param:

```bash
curl -s -X DELETE http://localhost:8000/api/v1/db_user/victim \
  -H "Authorization: Bearer <super_token>" \
  | python -m json.tool
```

**Expected:**

- HTTP 422.
- Body contains a Pydantic validation error indicating `user_id` must be an
  integer.

**Covers:** F2.

---

### S6 — Conflict: target row has dependent records

**Steps:**

1. Create a user and give it a dependent record that has a foreign key to the
   user (e.g. a post authored by that user), so the row cannot be removed
   without violating a constraint.
2. As the superuser, attempt the delete:

```bash
curl -s -X DELETE http://localhost:8000/api/v1/db_user/<target_id> \
  -H "Authorization: Bearer <super_token>" \
  | python -m json.tool
```

**Expected:**

- HTTP 409.
- Body: `{"error": {"code": "duplicate", "message": "User has dependent records"}}`.
- DB: the target row is unchanged — still present.

**Covers:** F11, F13.

> Note: this scenario depends on the existence of a dependent table with a
> restrictive foreign key to `users`. If the current schema cascades or nulls
> the relationship, the `IntegrityError` path is not reachable from HTTP and is
> only verifiable by the adapter unit test (F11). Document which applies when
> running this scenario.

---

## Code review checklist

### Architecture

- [ ] The existing `delete_db_user` slice folder at
      `src/app/features/users/delete_db_user/` retains its `domain/`, `data/`,
      `presentation/` layout — no new folders added, none removed.
- [ ] `DeleteDbUserUseCase` is a class with a single `__call__()` method that
      accepts `DeleteDbUserCommand` and returns `DeleteDbUserResult`.
- [ ] `DeleteDbUserPort` lives in `domain/ports/delete_db_user_port.py`, carries
      `@runtime_checkable`, and inherits from `typing.Protocol`.
- [ ] `DeleteDbUserAdapter` signature is
      `class DeleteDbUserAdapter(DeleteDbUserPort):` — explicit inheritance from
      the port is mandatory.
- [ ] The adapter is the only place SQLAlchemy (`select`, `delete`) is used.
- [ ] The router accepts `user_id: int` path param, converts to
      `DeleteDbUserCommand(target_user_id=user_id)`, awaits the use-case, and
      returns `DeleteDbUserResponse(message=result.message)`.
- [ ] The `get_current_superuser` dependency is retained on the endpoint.
- [ ] No cross-slice imports outside `users/_shared/`.
- [ ] All imports inside `src/app/` are **relative** (e.g.
      `from ..domain.commands import DeleteDbUserCommand`). No `from app...`
      or `from src.app...` inside source files.
- [ ] No `HTTPException` raised inside the use-case.

### Error handling

- [ ] `DeleteDbUserAdapter.get_by_id` has **no `try/except`** — it is a
      read-only lookup with nothing business-meaningful to translate.
- [ ] `DeleteDbUserAdapter.db_delete` catches **only** `IntegrityError` and
      translates it to `DuplicateValueDomainError("User has dependent records")`
      with `from exc` preserving the cause.
- [ ] No broad `except Exception` blocks in any modified file.
- [ ] The adapter does not log exceptions.
- [ ] No new `DomainError` subclass was introduced in the slice folder; only the
      existing `NotFoundDomainError` and `DuplicateValueDomainError` from
      `app/domain/errors.py` are raised.

### Files and headers

- [ ] All modified FEATURE files retain their `# FEATURE: <slice> — <purpose>`
      header on line 1.
- [ ] No STABLE files were modified. `bootstrap/container.py` and
      `bootstrap/router.py` are **not** touched (providers and router
      registration already exist from slice 0008).
- [ ] No `model.dict()` anywhere — only `model.model_dump()` if used.

### DI

- [ ] `delete_db_user_adapter` and `delete_db_user_use_case` providers in
      `bootstrap/container.py` are unchanged (they already exist).
- [ ] `delete_db_user.presentation.router` module path remains in
      `Container.wiring_config.modules` (already present).
- [ ] Endpoint still uses
      `Annotated[DeleteDbUserUseCase, Depends(Provide[Container.delete_db_user_use_case])]`.

### Tests

- [ ] `tests/features/users/0008_delete_db_user/domain/test_use_case.py` updated
      to use `get_by_id` / `DeleteDbUserCommand(target_user_id=...)` /
      `DbDeleteUserTarget(id=...)` and passes.
- [ ] `tests/features/users/0008_delete_db_user/data/test_adapter.py` updated to
      call `get_by_id(int)` and `db_delete(int)`, retains the
      `IntegrityError → DuplicateValueDomainError` case, and passes.
- [ ] `tests/features/users/0008_delete_db_user/presentation/test_router.py`
      updated to use `/api/v1/db_user/{id}` paths and includes a 422 case for a
      non-integer `user_id`; passes.
- [ ] `tests/features/users/0008_delete_db_user/delete_db_user_outside_in_test.py`
      updated to capture the created user's `id` and use it in the URL; passes
      (GREEN).
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
