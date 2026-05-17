# 0005 · get_user_tier — Validation

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md
- Requirements: ./requirements.md

## Prerequisites

- App running locally: `uvicorn src.app.main:app --reload` from the project root.
- PostgreSQL test database running and migrated (`alembic upgrade head`).
- A `tier` row exists in the DB (use `python -m scripts.create_first_tier` or
  insert directly).
- At least one active `user` row with `is_deleted = False` exists. Either
  `python -m scripts.create_first_superuser` or insert directly.
- No Bearer token required — the endpoint is public.

---

## Manual scenarios

### S1 — Happy path: user has a tier

**Setup:**

Insert a tier and a user referencing it via `tier_id`:

```sql
INSERT INTO tier (name) VALUES ('free') RETURNING id;
-- note the returned id, e.g. 1

INSERT INTO "user" (name, username, email, hashed_password, tier_id)
VALUES ('Alice Tester', 'alicetester', 'alice@example.com', 'x', 1);
```

**Steps:**

```bash
curl -s http://localhost:8000/api/v1/user/alicetester/tier | python -m json.tool
```

**Expected:**

- HTTP `200`.
- JSON body with exactly three keys: `tier_id`, `tier_name`, `tier_created_at`.
- `tier_id` equals the inserted tier's id (e.g. `1`).
- `tier_name` equals `"free"`.
- `tier_created_at` is an ISO-8601 datetime string.
- No internal fields leaked (`id`, `updated_at`, `hashed_password`, etc. must
  not appear).

**Covers:** F1, F2, F17.

---

### S2 — User exists but has no tier assigned

**Setup:**

Insert a user with `tier_id = NULL`:

```sql
INSERT INTO "user" (name, username, email, hashed_password)
VALUES ('Bob Notier', 'bobnotier', 'bob@example.com', 'x');
```

(No tier_id column means it defaults to NULL.)

**Steps:**

```bash
curl -s -w "\nHTTP %{http_code}\n" http://localhost:8000/api/v1/user/bobnotier/tier
```

**Expected:**

- HTTP `200`.
- Body is literally `null` (not `{}`, not `[]`).

**Covers:** F3.

---

### S3 — Username does not exist

**Steps:**

```bash
curl -s -w "\nHTTP %{http_code}\n" http://localhost:8000/api/v1/user/ghost_user_xyz/tier
```

**Expected:**

- HTTP `404`.
- Body: `{"error": {"code": "notfound", "message": "User not found"}}`.

**Covers:** F4, F6.

---

### S4 — Soft-deleted user is treated as not found

**Setup:**

Insert a user and then soft-delete them:

```sql
INSERT INTO "user" (name, username, email, hashed_password)
VALUES ('Dave Deleted', 'davedeleted', 'dave@example.com', 'x');

UPDATE "user" SET is_deleted = TRUE WHERE username = 'davedeleted';
```

**Steps:**

```bash
curl -s -w "\nHTTP %{http_code}\n" http://localhost:8000/api/v1/user/davedeleted/tier
```

**Expected:**

- HTTP `404`.
- Body: `{"error": {"code": "notfound", "message": "User not found"}}`.
  The endpoint must not return tier data for a soft-deleted user.

**Covers:** F4, F10, F14.

---

### S5 — User has a tier_id that references a non-existent tier

This scenario represents a data-integrity anomaly (orphaned FK). It must be
set up via direct SQL because the application normally enforces FK constraints.

**Setup:**

Use a tier_id that references no existing tier row. If FK enforcement allows it
in your test DB (e.g. FK constraints disabled), insert directly:

```sql
INSERT INTO "user" (name, username, email, hashed_password, tier_id)
VALUES ('Eve Orphan', 'eveorphan', 'eve@example.com', 'x', 99999);
```

Alternatively, insert a valid tier, reference it in a user, then delete the
tier row after disabling FK checks.

**Steps:**

```bash
curl -s -w "\nHTTP %{http_code}\n" http://localhost:8000/api/v1/user/eveorphan/tier
```

**Expected:**

- HTTP `404`.
- Body: `{"error": {"code": "notfound", "message": "Tier not found"}}`.

**Covers:** F5, F7, F13.

---

## Code review checklist

### Architecture

- [ ] Slice folder exists at `src/app/features/users/get_user_tier/` with
      `domain/`, `data/`, `presentation/` subfolders, each containing
      `__init__.py`.
- [ ] `GetUserTierUseCase` is a class with `__call__(query)` — not a free
      function.
- [ ] `GetUserTierPort` lives in `domain/ports/`, uses `@runtime_checkable`,
      inherits from `typing.Protocol`.
- [ ] `GetUserTierAdapter` class signature is
      `class GetUserTierAdapter(GetUserTierPort):` — explicit inheritance is
      mandatory.
- [ ] `GetUserTierAdapter` is the only place `User` and `Tier` ORM models are
      queried; no SQLAlchemy in `domain/` or `presentation/`.
- [ ] Router converts path param to `GetUserTierQuery`, awaits the use case,
      converts the returned entity (or `None`) to `GetUserTierResponse | None`.
- [ ] No cross-slice imports: `get_user_tier/` imports only ORM models from
      `adapters/db/models/` and errors from `domain/errors.py`; nothing from
      other `features/` slices.
- [ ] All imports inside `src/app/` are **relative**. No `from app...` or
      `from src.app...` anywhere inside source files.
- [ ] `GetUserTierUseCase` never raises `HTTPException`; it raises only
      `NotFoundDomainError`.
- [ ] The `domain/entities.py` file contains `UserNotFound`, `TierNotFound`,
      and `FoundUserTier`; no framework imports in that file.

### Sentinel classes

- [ ] `UserNotFound` and `TierNotFound` are plain Python classes (no Pydantic,
      no dataclass) defined in `domain/entities.py`.
- [ ] Port return type annotation is
      `FoundUserTier | None | UserNotFound | TierNotFound` (or equivalent union
      with `Union[]` for Python < 3.10).
- [ ] Use case uses `isinstance(result, UserNotFound)` and
      `isinstance(result, TierNotFound)` checks before returning `result`.

### Error handling

- [ ] `GetUserTierAdapter.get()` has **no `try/except`** block — read-only
      queries have no business-meaningful infrastructure exceptions to translate.
- [ ] The adapter returns `UserNotFound()` (not raises) when the user row is
      absent — the use case is the layer that raises `NotFoundDomainError`.
- [ ] The adapter returns `TierNotFound()` (not raises) when the tier row is
      absent.
- [ ] No `except Exception` or `except BaseException` anywhere in the slice.
- [ ] No logging inside adapter or use case; the global handler logs
      unhandled exceptions.
- [ ] No new `DomainError` subclass added inside the `get_user_tier/` folder;
      `NotFoundDomainError` is imported from `app/domain/errors.py`.

### Files and headers

- [ ] Every new `.py` file starts with `# FEATURE: get_user_tier — <purpose>`
      on line 1.
- [ ] `STABLE` files modified are limited to `bootstrap/container.py` (two new
      providers).
- [ ] `features/users/router.py` — `read_user_tier` import removed, replaced
      with `include_router(get_user_tier_router)`.
- [ ] `use_cases/user_tier_get.py` has been deleted (no dead code remains).
- [ ] `FoundUserTier` and `GetUserTierResponse` use
      `model_config = ConfigDict(from_attributes=True)` where appropriate.
- [ ] No `model.dict()` — only `model.model_dump()` if used anywhere.

### DI wiring

- [ ] `get_user_tier_adapter` provider added to `Container` as
      `providers.Factory(GetUserTierAdapter, session_factory=session_factory)`.
- [ ] `get_user_tier_use_case` provider added to `Container` as
      `providers.Factory(GetUserTierUseCase, port=get_user_tier_adapter)`.
- [ ] Router uses a local helper function
      `_get_get_user_tier_use_case()` that does a lazy import of
      `container` and calls `container.get_user_tier_use_case()`.
- [ ] Use-case dependency in the endpoint is
      `Annotated[GetUserTierUseCase, Depends(_get_get_user_tier_use_case)]`.

### Behavioral invariants

- [ ] HTTP route is still `GET /user/{username}/tier` — not changed.
- [ ] Soft-delete filter `User.is_deleted == False` is applied in the first
      query.
- [ ] The adapter opens two separate `async with self._session_factory()` blocks
      (not a JOIN).
- [ ] Response fields are `tier_id`, `tier_name`, `tier_created_at` — no
      rename.
- [ ] `GET /user/{username}/tier` for a user with no tier returns HTTP `200`
      with `null` body (not `404`).

### Tests

- [ ] Use-case unit test exists at
      `tests/features/users/0005_get_user_tier/domain/test_use_case.py` and
      covers all four branches (F6, F7, F8, F9).
- [ ] Adapter unit test exists at
      `tests/features/users/0005_get_user_tier/data/test_adapter.py` and
      covers all four return states (F10, F11, F12, F13) plus the
      soft-delete filter (F14) and two-query structure (F15).
- [ ] Endpoint integration test exists at
      `tests/features/users/0005_get_user_tier/presentation/test_router.py`
      and covers all four HTTP outcomes (F1/F2, F3, F4, F5).
- [ ] Outside-in test exists at
      `tests/features/users/0005_get_user_tier/get_user_tier_outside_in_test.py`
      and is GREEN.
- [ ] All tests use `AsyncMock(spec=...)` when mocking async dependencies.
- [ ] No `session.commit()` called inside tests that use the `db_session`
      fixture.
- [ ] No test leaves rows in the DB (transaction rollback fixture used).

### Quality gates

Run from the project root. All must pass before the slice is considered done:

```
ruff format src/app tests
ruff check src/app tests
mypy src/app
pytest
```

The `pytest` run includes `tests/smoke/test_app_starts.py`, which boots the
app in a subprocess via uvicorn and pings `/api/v1/health`. If the smoke test
fails despite all other tests passing, the most likely cause is an absolute
import (`from app...`) accidentally introduced inside `src/app/`. Check every
new file's imports first.
