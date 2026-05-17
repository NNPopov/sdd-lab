# 0015 · assign_moderator — Validation

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md
- Requirements: ./requirements.md

## Prerequisites

- App running locally (`uvicorn app.main:app --reload` from the project root,
  or `cd src && uvicorn app.main:app --reload`).
- Test Postgres started (`docker compose up test-db -d` or equivalent) with
  Alembic migrations applied (`alembic upgrade head`), including the 0013
  migration that added `is_moderator` and `moderator_granted_by_user_id` to
  the `user` table.
- A seeded **superuser** account. If not present, run
  `python -m scripts.create_first_superuser` (or insert directly:
  `UPDATE "user" SET is_superuser = TRUE WHERE username = 'admin';`).
- A valid superuser Bearer token — obtained from the login endpoint. Referred
  to below as `<SUPERUSER_TOKEN>`.
- A valid regular-user Bearer token for a non-superuser account. Referred to
  below as `<USER_TOKEN>`.

---

## Manual scenarios

### S1 — Happy path: superuser assigns moderator role

**Steps:**

1. Create a target user (skip if already exists):
   ```
   curl -s -X POST http://localhost:8000/api/v1/users \
     -H "Content-Type: application/json" \
     -d '{"username": "bob", "email": "bob@example.com", "password": "Pa$$w0rd1"}' \
     | python -m json.tool
   ```
2. Call the assign-moderator endpoint as a superuser:
   ```
   curl -s -X PATCH http://localhost:8000/api/v1/user/bob/assign-moderator \
     -H "Authorization: Bearer <SUPERUSER_TOKEN>" \
     | python -m json.tool
   ```

**Expected:**

- Status `200`.
- Response body contains all seven fields: `id`, `name`, `username`, `email`,
  `profile_image_url`, `tier_id` (may be `null`), `is_moderator`.
- `"is_moderator": true` in the response.
- `"username": "bob"` in the response.
- No other top-level keys beyond the seven defined in `AssignModeratorResponse`.

**Covers:** F1, F7, F12, F13, F14.

---

### S2 — Verify persistence through the read path

**Steps:**

1. Complete S1.
2. Call the get-by-username endpoint without authentication:
   ```
   curl -s http://localhost:8000/api/v1/user/bob | python -m json.tool
   ```

**Expected:**

- Status `200`.
- `"is_moderator": true` in the response — confirming the UPDATE committed and
  the read path returns the new state.

**Covers:** F10, F14 (persistence confirmation).

---

### S3 — Verify `moderator_granted_by_user_id` is written in the DB

**Steps:**

1. Complete S1. Note the `id` of the superuser account (visible in the DB or
   from a `GET /user/me/` call while authenticated as the superuser).
2. Query the database directly:
   ```sql
   SELECT username, is_moderator, moderator_granted_by_user_id
   FROM "user"
   WHERE username = 'bob';
   ```

**Expected:**

- `is_moderator = TRUE`.
- `moderator_granted_by_user_id` equals the superuser's `id`.
- The field is **not** present in the HTTP response body (it is an internal
  audit field).

**Covers:** F10, F11.

---

### S4 — Unauthenticated request: 401

**Steps:**

1. Call the endpoint with no Authorization header:
   ```
   curl -s -X PATCH http://localhost:8000/api/v1/user/bob/assign-moderator \
     | python -m json.tool
   ```

**Expected:**

- Status `401`.
- Response body contains a `"message"` or `"detail"` key (FastAPI / fastcrud
  exception shape).

**Covers:** F15.

---

### S5 — Regular-user forbidden: 403

**Steps:**

1. Ensure you have a Bearer token for a non-superuser account (`<USER_TOKEN>`).
2. Call the endpoint:
   ```
   curl -s -X PATCH http://localhost:8000/api/v1/user/bob/assign-moderator \
     -H "Authorization: Bearer <USER_TOKEN>" \
     | python -m json.tool
   ```

**Expected:**

- Status `403`.
- Body indicates insufficient privileges.
- `bob`'s `is_moderator` is unchanged in the DB.

**Covers:** F16, F17.

---

### S6 — Target user not found: 404

**Steps:**

1. Call the endpoint as a superuser with a username that does not exist:
   ```
   curl -s -X PATCH http://localhost:8000/api/v1/user/doesnotexist_xyz123/assign-moderator \
     -H "Authorization: Bearer <SUPERUSER_TOKEN>" \
     | python -m json.tool
   ```

**Expected:**

- Status `404`.
- Body `{"message": "User not found"}`.

**Covers:** F5, F8, F18.

---

### S7 — Already a moderator: 409

**Steps:**

1. Complete S1 so `bob` is already a moderator.
2. Call assign-moderator on `bob` again:
   ```
   curl -s -X PATCH http://localhost:8000/api/v1/user/bob/assign-moderator \
     -H "Authorization: Bearer <SUPERUSER_TOKEN>" \
     | python -m json.tool
   ```

**Expected:**

- Status `409`.
- Body `{"message": "User is already a moderator"}`.
- No change to the DB row (`is_moderator` remains `TRUE`,
  `moderator_granted_by_user_id` unchanged).

**Covers:** F6, F19.

---

### S8 — Soft-deleted user not assignable: 404

**Steps:**

1. Create a user and soft-delete them:
   ```sql
   UPDATE "user" SET is_deleted = TRUE WHERE username = 'charlie';
   ```
2. Call assign-moderator on `charlie`:
   ```
   curl -s -X PATCH http://localhost:8000/api/v1/user/charlie/assign-moderator \
     -H "Authorization: Bearer <SUPERUSER_TOKEN>" \
     | python -m json.tool
   ```

**Expected:**

- Status `404`.
- Body `{"message": "User not found"}` — soft-deleted users are invisible to
  `get_by_username`.

**Covers:** F8 (soft-delete filter in adapter).

---

### S9 — Response does not expose `moderator_granted_by_user_id`

**Steps:**

1. Complete S1 and inspect the full response body.

**Expected:**

- The key `moderator_granted_by_user_id` is **absent** from the JSON response.
- Only the seven documented fields appear.

**Covers:** PRD "Out of scope — Exposing `moderator_granted_by_user_id`".

---

## Code review checklist

### Architecture

- [ ] Slice folder exists at `src/app/features/users/assign_moderator/` with
      `domain/`, `data/`, and `presentation/` subfolders, each containing
      `__init__.py`.
- [ ] `AssignModeratorUseCase` is a class with `__call__(self, command:
      AssignModeratorCommand) -> AssignedUser`; it is not a free function.
      Per `agent_docs/architecture.md` § Use-case shape (N1).
- [ ] `AssignModeratorPort` in `domain/ports/assign_moderator_port.py` carries
      the `@runtime_checkable` decorator and inherits from `typing.Protocol`.
      Per `agent_docs/architecture.md` § Terminology (N10).
- [ ] Adapter class declaration is exactly
      `class AssignModeratorAdapter(AssignModeratorPort):` — explicit
      inheritance from the port, mandatory for greppability and reader intent.
      Per `agent_docs/architecture.md` § Adapter pattern (N11).
- [ ] Adapter is the only layer that imports SQLAlchemy (`select`, `update`,
      `AsyncSession`). Use-case and router have no ORM imports.
- [ ] Router builds `AssignModeratorCommand(target_username=username,
      requester_id=current_superuser["id"],
      requester_is_superuser=current_superuser["is_superuser"])` — all three
      fields populated from the path param and the `get_current_superuser`
      dependency (F3).
- [ ] No cross-slice imports: `AssignedUser` is defined in
      `assign_moderator/domain/entities.py` and is not imported from
      `get_user_by_username/`. Per `agent_docs/architecture.md` § Layer rules
      (N6).
- [ ] All imports inside `src/app/` are **relative** (`from ..domain...`,
      `from .....adapters...`). No `from app...` or `from src.app...` anywhere
      inside source files. Per `agent_docs/architecture.md` § Import
      conventions.
- [ ] No `HTTPException` is raised inside `AssignModeratorUseCase`. All
      failures are `ForbiddenDomainError`, `NotFoundDomainError`, or
      `DuplicateValueDomainError`. Per CLAUDE.md § Universal hard rules (N5).

### Error handling

- [ ] `AssignModeratorAdapter.get_by_username()` has **no `try/except`** —
      it is a read-only query; infrastructure failures propagate to the global
      handler. Per `agent_docs/error_handling.md` § Right shape: read-only
      query, no catch (N2).
- [ ] `AssignModeratorAdapter.assign()` has **no `try/except`** — an UPDATE
      on `is_moderator` (no unique constraint) has no business-meaningful
      infrastructure exception to translate. Per `agent_docs/error_handling.md`
      § Adapter: catch only when there is business meaning to translate (N2).
- [ ] No broad `except Exception` block anywhere in the adapter.
- [ ] No new `DomainError` subclass was added inside the slice folder; all
      domain errors used (`ForbiddenDomainError`, `NotFoundDomainError`,
      `DuplicateValueDomainError`) already exist in `app/domain/errors.py`.
      Per `agent_docs/error_handling.md` and `agent_docs/stable_vs_feature.md`.
- [ ] Adapter does **not** log exceptions. Per `agent_docs/error_handling.md`
      § Logging policy.

### Files and headers

- [ ] Every new `.py` file (9 in total: `__init__.py` files may be empty;
      non-empty ones need the header) starts with
      `# FEATURE: assign_moderator — <purpose>` on line 1. Per
      `agent_docs/stable_vs_feature.md` (N4).
- [ ] The only STABLE file modified is `bootstrap/container.py` (two new
      provider entries and two new imports). No other STABLE file was touched.
- [ ] `AssignModeratorResponse` uses
      `model_config = ConfigDict(from_attributes=True)`. Per
      `agent_docs/entry_points/fastapi.md` § Request and Response schemas (N3).
- [ ] No `model.dict()` used — only `model.model_dump()` if serialization is
      needed anywhere in the new code.

### DI wiring

- [ ] `assign_moderator_adapter = providers.Factory(AssignModeratorAdapter,
      session_factory=session_factory)` added to `Container`.
- [ ] `assign_moderator_use_case = providers.Factory(AssignModeratorUseCase,
      port=assign_moderator_adapter)` added to `Container`.
- [ ] Router uses the lazy-container-import pattern:
      `_get_assign_moderator_use_case()` imports and calls
      `container.assign_moderator_use_case()`.
- [ ] Endpoint parameter is
      `Annotated[AssignModeratorUseCase, Depends(_get_assign_moderator_use_case)]`.

### Router registration

- [ ] `from .assign_moderator.presentation.router import router as
      assign_moderator_router` added to `features/users/router.py`.
- [ ] `router.include_router(assign_moderator_router)` added to
      `features/users/router.py`.
- [ ] `bootstrap/router.py` is **not modified** — it already aggregates
      `users_router`.

### Tests

- [ ] Use-case unit test exists at
      `tests/features/users/0015_assign_moderator/domain/test_use_case.py`
      and covers all four branches: superuser-check, not-found, already-moderator,
      happy path.
- [ ] Adapter unit test exists at
      `tests/features/users/0015_assign_moderator/data/test_adapter.py`
      and covers: `get_by_username` not-found, `get_by_username` found,
      `assign` happy path (DB row assertions for both `is_moderator` and
      `moderator_granted_by_user_id`).
- [ ] Endpoint integration test exists at
      `tests/features/users/0015_assign_moderator/presentation/test_router.py`
      and covers all five status codes: 401, 403, 404, 409, 200.
- [ ] Outside-in test exists at
      `tests/features/users/0015_assign_moderator/assign_moderator_outside_in_test.py`
      and is **GREEN**. This is the acceptance gate; the slice is not done
      until it passes.
- [ ] All tests use `db_session` fixture for any DB interaction and do not
      call `session.commit()` directly (transaction rollback relies on the
      outer fixture transaction).

### Quality gates

Run from project root before approving:

```
ruff format src/app tests
ruff check src/app tests
mypy src/app
pytest
```

All must pass, including `tests/smoke/test_app_starts.py`, which boots the app
in a subprocess and pings `/api/v1/health`. A smoke failure at this stage
typically means a relative-import rule was violated in the new files (an
`from app...` inside `src/app/` instead of a relative import).
