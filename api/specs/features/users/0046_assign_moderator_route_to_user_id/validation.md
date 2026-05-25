# 0046 · assign_moderator_route_to_user_id — Validation

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md
- Requirements: ./requirements.md

## Prerequisites

- App running locally: `cd src && uvicorn app.main:app --reload`
- Postgres accessible; schema up-to-date (`alembic upgrade head`).
- A superuser account exists (seed with `python -m scripts.create_first_superuser`)
  and a valid access token for it is at hand.
- A regular (non-moderator) target user registered; capture its `id`.
- A second regular user registered for the forbidden scenario; capture a token
  for it.

```bash
# Register the target user (note the returned id field):
curl -s -X POST http://localhost:8000/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{"username":"target","email":"target@example.com","password":"Pa$$w0rd1"}' \
  | python -m json.tool
# → { "id": 42, "username": "target", "is_moderator": false, ... }  ← capture target_id

# Register a plain (non-superuser) user for the 403 scenario:
curl -s -X POST http://localhost:8000/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{"username":"plain","email":"plain@example.com","password":"Pa$$w0rd2"}' \
  | python -m json.tool

# Login as the superuser:
curl -s -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=<superuser_name>&password=<superuser_password>" \
  | python -m json.tool
# → { "access_token": "<super_token>", ... }

# Login as the plain user:
curl -s -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=plain&password=Pa%24%24w0rd2" \
  | python -m json.tool
# → { "access_token": "<plain_token>", ... }
```

---

## Manual scenarios

### S1 — Happy path: superuser assigns moderator by user_id

**Steps:**

1. Obtain `target_id` and `super_token` from prerequisites.
2. Send:

```bash
curl -s -X PATCH http://localhost:8000/api/v1/user/<target_id>/assign-moderator \
  -H "Authorization: Bearer <super_token>" \
  | python -m json.tool
```

**Expected:**

- HTTP 200.
- Body matches `AssignModeratorResponse` with `id == target_id` and
  `is_moderator: true`.
- DB: target's row has `is_moderator = true` and
  `moderator_granted_by_user_id` set to the superuser's id.

**Covers:** F1, F5, F6, F7, F9, F10, F11.

---

### S2 — Conflict: assigning a user who is already a moderator

**Steps:**

1. Complete S1 (target is now a moderator).
2. Repeat the same request:

```bash
curl -s -X PATCH http://localhost:8000/api/v1/user/<target_id>/assign-moderator \
  -H "Authorization: Bearer <super_token>" \
  | python -m json.tool
```

**Expected:**

- HTTP 409.
- Body: `{"error": {"code": "duplicatevalue", "message": "User is already a moderator"}}`.

**Covers:** F8, F13.

---

### S3 — Not found: assigning a non-existent user_id

**Steps:**

1. Obtain `super_token`.
2. Send a request with an ID that does not exist (e.g. `999999`):

```bash
curl -s -X PATCH http://localhost:8000/api/v1/user/999999/assign-moderator \
  -H "Authorization: Bearer <super_token>" \
  | python -m json.tool
```

**Expected:**

- HTTP 404.
- Body: `{"error": {"code": "notfound", "message": "User not found"}}`.

**Covers:** F7, F12.

---

### S4 — Forbidden: a non-superuser attempts the assignment

**Steps:**

1. Obtain `plain_token` and `target_id`.
2. Send:

```bash
curl -s -X PATCH http://localhost:8000/api/v1/user/<target_id>/assign-moderator \
  -H "Authorization: Bearer <plain_token>" \
  | python -m json.tool
```

**Expected:**

- HTTP 403.
- DB: target's row is unchanged.

**Covers:** F4, F14.

---

### S5 — Unauthorized: missing authentication token

**Steps:**

1. Send the request without any `Authorization` header:

```bash
curl -s -X PATCH http://localhost:8000/api/v1/user/<target_id>/assign-moderator \
  | python -m json.tool
```

**Expected:**

- HTTP 401.

**Covers:** F3.

---

### S6 — Unprocessable: non-integer path param

**Steps:**

1. Send a request with a string path param:

```bash
curl -s -X PATCH http://localhost:8000/api/v1/user/target/assign-moderator \
  -H "Authorization: Bearer <super_token>" \
  | python -m json.tool
```

**Expected:**

- HTTP 422.
- Body contains a Pydantic validation error indicating `user_id` must be an
  integer.

**Covers:** F2.

---

## Code review checklist

### Architecture

- [ ] The existing `assign_moderator` slice folder at
      `src/app/features/users/assign_moderator/` retains its `domain/`, `data/`,
      `presentation/` layout — no new folders added, none removed.
- [ ] `AssignModeratorUseCase` is a class with a single `__call__()` method that
      accepts `AssignModeratorCommand` and returns `AssignedUser`.
- [ ] `AssignModeratorPort` lives in `domain/ports/assign_moderator_port.py`,
      carries `@runtime_checkable`, and inherits from `typing.Protocol`.
- [ ] `AssignModeratorAdapter` signature is
      `class AssignModeratorAdapter(AssignModeratorPort):` — explicit inheritance
      from the port is mandatory.
- [ ] The adapter is the only place SQLAlchemy (`select`, `update`) is used.
- [ ] The router accepts `user_id: int` path param, converts to
      `AssignModeratorCommand(target_user_id=user_id, requester_id=current_superuser["id"], requester_is_superuser=current_superuser["is_superuser"])`,
      awaits the use-case, and returns `AssignModeratorResponse`.
- [ ] No cross-slice imports outside `users/_shared/`.
- [ ] All imports inside `src/app/` are **relative** (e.g.
      `from ..domain.commands import AssignModeratorCommand`). No `from app...`
      or `from src.app...` inside source files.
- [ ] No `HTTPException` raised inside the use-case.
- [ ] The use-case preserves branch order: superuser check → not-found check →
      already-moderator check → `assign`.

### Error handling

- [ ] `AssignModeratorAdapter.get_by_id` has **no `try/except`** — it is a
      read-only lookup with nothing business-meaningful to translate.
- [ ] `AssignModeratorAdapter.assign` has **no `try/except`** — an UPDATE by
      primary key setting a role flag and an existing-FK column has no
      unique-constraint path.
- [ ] No broad `except Exception` blocks in any modified file.
- [ ] The adapter does not log exceptions.
- [ ] No new `DomainError` subclass was introduced in the slice folder; only the
      existing `ForbiddenDomainError`, `NotFoundDomainError`, and
      `DuplicateValueDomainError` from `app/domain/errors.py` are raised.

### Files and headers

- [ ] All modified FEATURE files retain their `# FEATURE: <slice> — <purpose>`
      header on line 1.
- [ ] No STABLE files were modified. `bootstrap/container.py` and
      `bootstrap/router.py` are **not** touched (providers and router
      registration already exist from slice 0015).
- [ ] `AssignModeratorResponse` retains
      `model_config = ConfigDict(from_attributes=True)` (unchanged schema).
- [ ] No `model.dict()` — only `model.model_dump()` if any serialization is added.

### DI

- [ ] `assign_moderator_adapter` and `assign_moderator_use_case` providers in
      `bootstrap/container.py` are unchanged (they already exist).
- [ ] `assign_moderator.presentation.router` module path remains in
      `Container.wiring_config.modules` (already present).
- [ ] Endpoint still uses
      `Annotated[AssignModeratorUseCase, Depends(Provide[Container.assign_moderator_use_case])]`.

### Tests

- [ ] `tests/features/users/0015_assign_moderator/domain/test_use_case.py`
      updated to use `get_by_id` / `assign(target_user_id, requester_id)` and
      `AssignModeratorCommand(target_user_id=..., ...)`; passes.
- [ ] `tests/features/users/0015_assign_moderator/data/test_adapter.py` updated
      to call `get_by_id(int)` and `assign(int, int)` and assert the UPDATE
      filters on `User.id`; passes.
- [ ] `tests/features/users/0015_assign_moderator/presentation/test_router.py`
      updated to use `/api/v1/user/{id}/assign-moderator` paths and includes a
      422 case for a non-integer `user_id`; passes.
- [ ] `tests/features/users/0015_assign_moderator/assign_moderator_outside_in_test.py`
      updated to capture the created user's `id` and build the URL with it;
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
