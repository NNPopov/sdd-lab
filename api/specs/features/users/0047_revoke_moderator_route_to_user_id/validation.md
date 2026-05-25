# 0047 · revoke_moderator_route_to_user_id — Validation

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md
- Requirements: ./requirements.md

## Prerequisites

- App running locally: `cd src && uvicorn app.main:app --reload`
- Postgres accessible; schema up-to-date (`alembic upgrade head`).
- A superuser account exists (seed with `python -m scripts.create_first_superuser`)
  and a valid access token for it is at hand.
- A regular target user registered and **promoted to moderator** via the slice
  0046 endpoint; capture its `id`.
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

# Promote the target user to moderator (slice 0046 endpoint) so it can be revoked:
curl -s -X PATCH http://localhost:8000/api/v1/user/<target_id>/assign-moderator \
  -H "Authorization: Bearer <super_token>" \
  | python -m json.tool
# → { "id": 42, "is_moderator": true, ... }

# Login as the plain user:
curl -s -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=plain&password=Pa%24%24w0rd2" \
  | python -m json.tool
# → { "access_token": "<plain_token>", ... }
```

---

## Manual scenarios

### S1 — Happy path: superuser revokes moderator by user_id

**Steps:**

1. Obtain a moderator `target_id` and `super_token` from prerequisites.
2. Send:

```bash
curl -s -X PATCH http://localhost:8000/api/v1/users/<target_id>/revoke-moderator \
  -H "Authorization: Bearer <super_token>" \
  | python -m json.tool
```

**Expected:**

- HTTP 200.
- Body matches `RevokeModeratorResponse` with `id == target_id` and
  `is_moderator: false`.
- DB: target's row has `is_moderator = false` and
  `moderator_granted_by_user_id = NULL`.

**Covers:** F1, F5, F6, F7, F9, F10, F11.

---

### S2 — Conflict: revoking a user who is not a moderator

**Steps:**

1. Complete S1 (target is now a regular user again).
2. Repeat the same request:

```bash
curl -s -X PATCH http://localhost:8000/api/v1/users/<target_id>/revoke-moderator \
  -H "Authorization: Bearer <super_token>" \
  | python -m json.tool
```

**Expected:**

- HTTP 409.
- Body: `{"error": {"code": "duplicatevalue", "message": "User is not a moderator"}}`.

**Covers:** F8, F13.

---

### S3 — Not found: revoking a non-existent user_id

**Steps:**

1. Obtain `super_token`.
2. Send a request with an ID that does not exist (e.g. `999999`):

```bash
curl -s -X PATCH http://localhost:8000/api/v1/users/999999/revoke-moderator \
  -H "Authorization: Bearer <super_token>" \
  | python -m json.tool
```

**Expected:**

- HTTP 404.
- Body: `{"error": {"code": "notfound", "message": "User not found"}}`.

**Covers:** F7, F12.

---

### S4 — Forbidden: a non-superuser attempts the revocation

**Steps:**

1. Obtain `plain_token` and a moderator `target_id`.
2. Send:

```bash
curl -s -X PATCH http://localhost:8000/api/v1/users/<target_id>/revoke-moderator \
  -H "Authorization: Bearer <plain_token>" \
  | python -m json.tool
```

**Expected:**

- HTTP 403.
- DB: target's row is unchanged (still a moderator).

**Covers:** F4, F14.

---

### S5 — Unauthorized: missing authentication token

**Steps:**

1. Send the request without any `Authorization` header:

```bash
curl -s -X PATCH http://localhost:8000/api/v1/users/<target_id>/revoke-moderator \
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
curl -s -X PATCH http://localhost:8000/api/v1/users/target/revoke-moderator \
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

- [ ] The existing `revoke_moderator` slice folder at
      `src/app/features/users/revoke_moderator/` retains its `domain/`, `data/`,
      `presentation/` layout — no new folders added, none removed.
- [ ] `RevokeModeratorUseCase` is a class with a single `__call__()` method that
      accepts `RevokeModeratorCommand` and returns `RevokedUser`.
- [ ] `RevokeModeratorPort` lives in `domain/ports/revoke_moderator_port.py`,
      carries `@runtime_checkable`, and inherits from `typing.Protocol`.
- [ ] `RevokeModeratorAdapter` signature is
      `class RevokeModeratorAdapter(RevokeModeratorPort):` — explicit inheritance
      from the port is mandatory.
- [ ] The adapter is the only place SQLAlchemy (`select`, `update`) is used.
- [ ] The router accepts `user_id: int` path param, converts to
      `RevokeModeratorCommand(target_user_id=user_id, requester_is_superuser=current_superuser["is_superuser"])`,
      awaits the use-case, and returns `RevokeModeratorResponse`.
- [ ] The route path keeps the plural `/users/{user_id}/revoke-moderator` segment
      (unchanged from the existing route).
- [ ] No cross-slice imports outside `users/_shared/`.
- [ ] All imports inside `src/app/` are **relative** (e.g.
      `from ..domain.commands import RevokeModeratorCommand`). No `from app...`
      or `from src.app...` inside source files.
- [ ] No `HTTPException` raised inside the use-case.
- [ ] The use-case preserves branch order: superuser check → not-found check →
      not-a-moderator check → `revoke`.

### Error handling

- [ ] `RevokeModeratorAdapter.get_by_id` has **no `try/except`** — it is a
      read-only lookup with nothing business-meaningful to translate.
- [ ] `RevokeModeratorAdapter.revoke` has **no `try/except`** — an UPDATE by
      primary key clearing a role flag and an FK column has no unique-constraint
      path.
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
      registration already exist from slice 0016).
- [ ] `RevokeModeratorResponse` retains
      `model_config = ConfigDict(from_attributes=True)` (unchanged schema).
- [ ] No `model.dict()` — only `model.model_dump()` if any serialization is added.

### DI

- [ ] `revoke_moderator_adapter` and `revoke_moderator_use_case` providers in
      `bootstrap/container.py` are unchanged (they already exist).
- [ ] `revoke_moderator.presentation.router` module path remains in
      `Container.wiring_config.modules` (already present).
- [ ] Endpoint still uses
      `Annotated[RevokeModeratorUseCase, Depends(Provide[Container.revoke_moderator_use_case])]`.

### Tests

- [ ] `tests/features/users/0016_revoke_moderator/domain/test_use_case.py`
      updated to use `get_by_id` / `revoke(target_user_id)` and
      `RevokeModeratorCommand(target_user_id=..., ...)`; passes.
- [ ] `tests/features/users/0016_revoke_moderator/data/test_adapter.py` updated
      to call `get_by_id(int)` and `revoke(int)` and assert the lookup and UPDATE
      filter on `User.id`; passes.
- [ ] `tests/features/users/0016_revoke_moderator/presentation/test_router.py`
      updated to use `/api/v1/users/{id}/revoke-moderator` paths and includes a
      422 case for a non-integer `user_id`; passes.
- [ ] `tests/features/users/0016_revoke_moderator/revoke_moderator_outside_in_test.py`
      updated to capture the created (moderator) user's `id` and build the URL
      with it; passes (GREEN).
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
