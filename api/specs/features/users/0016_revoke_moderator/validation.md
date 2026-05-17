# 0016 · revoke_moderator — Validation

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md
- Requirements: ./requirements.md

## Prerequisites

- App running locally (`uvicorn src.app.main:app --reload`).
- Test Postgres reachable and migrations applied (`alembic upgrade head`).
- A superuser account exists; export its Bearer token:
  ```
  export SUPER_TOKEN="<superuser bearer token>"
  ```
- A regular (non-superuser) account exists; export its token:
  ```
  export USER_TOKEN="<non-superuser bearer token>"
  ```
- Slice 0015 (`assign_moderator`) is deployed — S1 uses that endpoint to
  promote a user before revoking.
- `jq` installed for response inspection (optional but helpful).

## Manual scenarios

### S1 — Happy path: revoke moderator, confirm persistence

**Steps:**

```bash
# 1. Create a target user.
curl -s -X POST http://localhost:8000/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{"username": "target_user", "email": "target@example.com", "password": "Pa$$w0rd1"}' | jq .

# 2. Promote the user to moderator via slice 0015.
curl -s -X PATCH "http://localhost:8000/api/v1/user/target_user/assign-moderator" \
  -H "Authorization: Bearer $SUPER_TOKEN" | jq .

# 3. Revoke the moderator role.
curl -s -X PATCH "http://localhost:8000/api/v1/users/target_user/revoke-moderator" \
  -H "Authorization: Bearer $SUPER_TOKEN" | jq .

# 4. Verify persistence via the read path (unauthenticated).
curl -s http://localhost:8000/api/v1/users/user/target_user | jq .is_moderator
```

**Expected:**

- Step 3: HTTP 200.
- Step 3 body: `RevokeModeratorResponse` shape; `is_moderator` is `false`;
  `id`, `name`, `username`, `email`, `profile_image_url`, `tier_id` match the
  created user.
- Step 4: `false`.

**Covers:** F6, F7, F8, F12, F15.

---

### S2 — Unauthenticated request: 401

**Steps:**

```bash
curl -s -X PATCH "http://localhost:8000/api/v1/users/anyone/revoke-moderator" | jq .
```

**Expected:**

- HTTP 401.
- Body contains a `message` field.

**Covers:** F1.

---

### S3 — Non-superuser authenticated: 403

**Steps:**

```bash
curl -s -X PATCH "http://localhost:8000/api/v1/users/anyone/revoke-moderator" \
  -H "Authorization: Bearer $USER_TOKEN" | jq .
```

**Expected:**

- HTTP 403.
- Body: `{"message": "..."}` (message from `get_current_superuser`).

**Covers:** F2.

> **Note:** F3 (use-case second-layer `ForbiddenDomainError`) is not directly
> exercisable via curl because `get_current_superuser` enforces the same rule at
> the router level before the use-case is reached. F3 is verified exclusively by
> the use-case unit test.

---

### S4 — Username does not exist: 404

**Steps:**

```bash
curl -s -X PATCH "http://localhost:8000/api/v1/users/nonexistent_xyz/revoke-moderator" \
  -H "Authorization: Bearer $SUPER_TOKEN" | jq .
```

**Expected:**

- HTTP 404.
- Body: `{"message": "User not found"}`.

**Covers:** F4, F13.

---

### S5 — Target is not currently a moderator: 409

**Steps:**

```bash
# 1. Create a non-moderator user (skip the assign-moderator step).
curl -s -X POST http://localhost:8000/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{"username": "not_a_mod", "email": "notamod@example.com", "password": "Pa$$w0rd2"}' | jq .

# 2. Attempt to revoke moderator status.
curl -s -X PATCH "http://localhost:8000/api/v1/users/not_a_mod/revoke-moderator" \
  -H "Authorization: Bearer $SUPER_TOKEN" | jq .
```

**Expected:**

- HTTP 409.
- Body: `{"message": "User is not a moderator"}`.

**Covers:** F5, F14.

---

### S6 — Soft-deleted user treated as not found: 404

**Steps:**

1. Create a user and mark them as soft-deleted directly in the DB
   (`UPDATE "user" SET is_deleted = true WHERE username = 'deleted_user'`).
2. Attempt to revoke moderator status for that username.

```bash
curl -s -X PATCH "http://localhost:8000/api/v1/users/deleted_user/revoke-moderator" \
  -H "Authorization: Bearer $SUPER_TOKEN" | jq .
```

**Expected:**

- HTTP 404.
- Body: `{"message": "User not found"}`.

**Covers:** F11, F13.

---

### S7 — Response shape verification

**Steps:**

```bash
# After S1 step 3 (successful revocation):
curl -s -X PATCH "http://localhost:8000/api/v1/users/target_user/revoke-moderator" \
  -H "Authorization: Bearer $SUPER_TOKEN"
```

**Expected body shape:**

```json
{
  "id": <int>,
  "name": <str>,
  "username": "target_user",
  "email": <str>,
  "profile_image_url": <str>,
  "tier_id": <int|null>,
  "is_moderator": false
}
```

No extra fields; `is_moderator` is always `false` after successful revocation.

**Covers:** F12.

## Code review checklist

### Architecture

- [ ] Slice folder exists at `src/app/features/users/revoke_moderator/` with
      `domain/`, `data/`, `presentation/` subfolders, each with `__init__.py`.
- [ ] `RevokeModeratorUseCase` is a class with `__call__()`; takes a
      `RevokeModeratorCommand`, returns a `RevokedUser` entity.
- [ ] `RevokeModeratorPort` lives in `domain/ports/revoke_moderator_port.py`,
      uses `@runtime_checkable` decorator, and inherits from `typing.Protocol`.
- [ ] Adapter class signature is
      `class RevokeModeratorAdapter(RevokeModeratorPort):` — explicit
      inheritance from the port is mandatory (greppability + reader intent).
- [ ] `RevokeModeratorAdapter` is the only file that imports SQLAlchemy; no
      ORM in `domain/`, `presentation/`, or `bootstrap/`.
- [ ] Router accepts path param `username` and auth dependency, builds
      `RevokeModeratorCommand`, awaits use-case, returns `RevokeModeratorResponse`.
- [ ] `RevokedUser` is defined in `revoke_moderator/domain/entities.py`; it is
      **not** imported from `assign_moderator` or any other slice.
- [ ] No cross-slice imports outside `_shared/`.
- [ ] All imports inside `src/app/` are **relative**. No `from app...` or
      `from src.app...` anywhere in source files. Tests use absolute
      `from app...` only.
- [ ] No `HTTPException` raised inside `RevokeModeratorUseCase`.
- [ ] No `try/except` block in the use-case.
- [ ] `RevokeModeratorCommand` has exactly two fields: `target_username: str`
      and `requester_is_superuser: bool`; no `requester_id` field (revoke
      clears the grantor column, not populates it).

### Error handling

- [ ] `RevokeModeratorAdapter` has **no** `try/except` block — the revoke
      UPDATE does not produce a business-meaningful `IntegrityError`; unexpected
      failures propagate to the global handler.
- [ ] `get_by_username` has no `try/except` — it is a read-only query.
- [ ] `RevokeModeratorUseCase` raises `ForbiddenDomainError` when
      `requester_is_superuser` is `False`.
- [ ] `RevokeModeratorUseCase` raises `NotFoundDomainError("User not found")`
      when `port.get_by_username` returns `None`.
- [ ] `RevokeModeratorUseCase` raises
      `DuplicateValueDomainError("User is not a moderator")` when the target's
      `is_moderator` is `False`.
- [ ] No new `DomainError` subclass was added in the slice folder. All domain
      errors live in `app/domain/errors.py`.
- [ ] Adapter does **not** log exceptions.

### Files and headers

- [ ] Every new `.py` file starts with `# FEATURE: revoke_moderator — <purpose>`
      on line 1.
- [ ] No STABLE file was modified beyond `bootstrap/container.py` wiring
      entries (two providers + their imports).
- [ ] `RevokeModeratorResponse` uses `model_config = ConfigDict(from_attributes=True)`.
- [ ] No `model.dict()` — only `model.model_dump()`.

### DI

- [ ] `revoke_moderator_adapter` provider added to `Container` as
      `providers.Factory(RevokeModeratorAdapter, session_factory=session_factory)`.
- [ ] `revoke_moderator_use_case` provider added to `Container` as
      `providers.Factory(RevokeModeratorUseCase, port=revoke_moderator_adapter)`.
- [ ] Router module path
      `"app.features.users.revoke_moderator.presentation.router"` added to
      `Container.wiring_config.modules`.
- [ ] Endpoint uses the lazy-container-import pattern consistent with
      `assign_moderator`; uses `Annotated[X, Depends(...)]`.
- [ ] Router is registered in `src/app/features/users/router.py` via
      `include_router(revoke_moderator_router)`.

### Tests

- [ ] Use-case unit test exists at
      `tests/features/users/0016_revoke_moderator/domain/test_use_case.py`
      and covers all four branches (forbidden, not found, not a moderator, happy
      path).
- [ ] Adapter unit test exists at
      `tests/features/users/0016_revoke_moderator/data/test_adapter.py` and
      covers: `get_by_username` not found, `get_by_username` found, `revoke`
      happy path (DB row assertion for both `is_moderator=False` and
      `moderator_granted_by_user_id=None`), and soft-deleted user exclusion.
- [ ] Endpoint integration test exists at
      `tests/features/users/0016_revoke_moderator/presentation/test_router.py`
      and covers 401, 403, 404, 409, and 200 cases via `httpx.AsyncClient`.
- [ ] Outside-in test exists at
      `tests/features/users/0016_revoke_moderator/revoke_moderator_outside_in_test.py`
      and is GREEN.
- [ ] No test leaves rows in the DB (transaction rollback via `db_session`
      fixture).
- [ ] No `session.commit()` inside tests that use the `db_session` fixture.

### Quality gates

Run from project root before marking the slice done:

```
ruff format src/app tests
ruff check src/app tests
mypy src/app
pytest
```

All must pass. `pytest` includes `tests/smoke/test_app_starts.py`, which boots
the app in a subprocess and pings `/api/v1/health`. If the smoke test fails,
the slice is **not done** — it typically signals an accidental absolute import
(`from app...`) inside `src/app/` that works under pytest but breaks under
uvicorn.
