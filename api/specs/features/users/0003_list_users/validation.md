# 0003 · list_users — Validation

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md
- Requirements: ./requirements.md

## Prerequisites

- App running locally (`uvicorn app.main:app --reload` from `src/`).
- Test database has at least a handful of active user rows (run the seed
  script or create them via `POST /api/v1/user` first).
- At least one soft-deleted user row in the database for S4.
- No authentication is required for `GET /api/v1/users`.

## Manual scenarios

### S1 — Happy path (default pagination)

**Steps:**

```bash
curl -s http://localhost:8000/api/v1/users | python -m json.tool
```

**Expected:**

- HTTP status **200**.
- Response body contains exactly the fields `items`, `total_count`, `page`,
  `items_per_page`.
- `page` is `1`, `items_per_page` is `10`.
- Each element of `items` contains exactly `id`, `name`, `username`, `email`,
  `profile_image_url`, `tier_id`.
- `total_count` matches the number of non-deleted users in the DB.
- No soft-deleted user appears in `items`.

**Covers:** F1, F2, F3, F4, F7, F8.

---

### S2 — Explicit page and items_per_page

**Steps:**

1. Ensure at least 6 non-deleted users exist.

```bash
curl -s "http://localhost:8000/api/v1/users?page=2&items_per_page=3" \
  | python -m json.tool
```

**Expected:**

- HTTP status **200**.
- `page` is `2`, `items_per_page` is `3`.
- `items` contains exactly 3 elements (the 4th, 5th, 6th users by insertion
  order, given 6 total).
- `total_count` equals the total non-deleted user count, not `3`.

**Covers:** F1, F2, F9, F10.

---

### S3 — Page beyond the last result (empty items)

**Steps:**

```bash
curl -s "http://localhost:8000/api/v1/users?page=9999&items_per_page=10" \
  | python -m json.tool
```

**Expected:**

- HTTP status **200**.
- `items` is an empty list `[]`.
- `total_count` still reflects the real total, not `0`.
- `page` is `9999`, `items_per_page` is `10`.

**Covers:** F1, F2, F10.

---

### S4 — Soft-deleted users excluded

**Steps:**

1. Confirm a soft-deleted user exists in the DB
   (`SELECT id, username FROM "user" WHERE is_deleted = true`).
2. Note the username of the deleted user.

```bash
curl -s "http://localhost:8000/api/v1/users?items_per_page=100" \
  | python -m json.tool
```

**Expected:**

- The soft-deleted username does not appear in any element of `items`.
- `total_count` does not include the deleted user.

**Covers:** F4.

---

### S5 — page=0 returns 422

**Steps:**

```bash
curl -s "http://localhost:8000/api/v1/users?page=0" | python -m json.tool
```

**Expected:**

- HTTP status **422 Unprocessable Entity**.
- Response contains a Pydantic validation error identifying the `page` field.

**Covers:** F5.

---

### S6 — items_per_page=101 returns 422

**Steps:**

```bash
curl -s "http://localhost:8000/api/v1/users?items_per_page=101" \
  | python -m json.tool
```

**Expected:**

- HTTP status **422 Unprocessable Entity**.
- Response contains a Pydantic validation error identifying `items_per_page`.

**Covers:** F6.

---

### S7 — Infrastructure failure returns 500

**Steps:**

1. Stop the PostgreSQL server (or temporarily revoke the DB connection).
2. Send a request:

```bash
curl -s http://localhost:8000/api/v1/users
```

**Expected:**

- HTTP status **500**.
- Response body `{"message": "Internal error"}` — the global handler's
  standard output.
- Application logs show the original SQLAlchemy `OperationalError` (or similar)
  with full traceback, **not** wrapped in any `DomainError` subclass.

**Covers:** F14; N2.

*Note: acceptable to skip if F14 is fully covered by the adapter unit test.*

---

## Code review checklist

### Architecture

- [ ] Slice folder exists at
      `src/app/features/users/list_users/` with `domain/`, `data/`,
      `presentation/` subfolders, each with an `__init__.py`.
- [ ] `ListUsersUseCase` is a class with `__call__(self, query: ListUsersQuery) -> UserPage`
      and no other public method. (N1; `agent_docs/architecture.md` § Use-case shape)
- [ ] `ListUsersPort` lives in `domain/ports/list_users_port.py`, is decorated
      with `@runtime_checkable`, and inherits from `typing.Protocol`. (F12, N10;
      `agent_docs/architecture.md` § Port pattern)
- [ ] `ListUsersAdapter` class declaration is `class ListUsersAdapter(ListUsersPort):`
      — explicit port inheritance is mandatory. (F13, N11;
      `agent_docs/architecture.md` § Adapter pattern)
- [ ] SQLAlchemy ORM code appears only inside `data/adapter.py`. (N2;
      `agent_docs/architecture.md` § Layer rules)
- [ ] Router converts query params to `ListUsersQuery`, awaits use case, converts
      `UserPage` to `ListUsersResponse`; no business logic in the endpoint function.
      (`agent_docs/entry_points/fastapi.md` § Endpoint shape)
- [ ] No file inside `list_users/` imports from another slice's `domain/`, `data/`,
      or `presentation/` layer. (N6; `agent_docs/architecture.md` § Layer rules)
- [ ] All imports inside `src/app/` are **relative** (`from ..domain...`,
      `from .....adapters...`). No `from app...` or `from src.app...` inside
      source files. (N12; `agent_docs/architecture.md` § Import conventions)
- [ ] No `HTTPException` is raised anywhere in `list_users/domain/`. (N5; `CLAUDE.md`)

### Error handling

- [ ] `ListUsersAdapter.list` contains **no `try/except` block** — it is a
      read-only operation with no business-meaningful exception path. (F14, N2;
      `agent_docs/error_handling.md` § Right shape: read-only query, no catch)
- [ ] No `except Exception` block anywhere in `data/adapter.py`.
      (`agent_docs/error_handling.md` § Forbidden patterns)
- [ ] No `logger` or structlog import in `data/adapter.py`. (N2;
      `agent_docs/error_handling.md` § Logging policy)
- [ ] No new `DomainError` subclass is defined inside `list_users/`. All domain
      errors live in `app/domain/errors.py`. (`agent_docs/error_handling.md`)

### Pagination correctness

- [ ] Offset is computed as `(query.page - 1) * query.items_per_page`. (F9)
- [ ] Both the COUNT query and the SELECT query carry the `is_deleted == False`
      predicate. (F4, F10)
- [ ] `total_count` comes from the COUNT query, not `len(items)`. (F10)

### DI wiring

- [ ] `Container` has a `list_users_adapter` provider: `Factory(ListUsersAdapter, session_factory=session_factory)`.
      (plan.md step 8)
- [ ] `Container` has a `list_users_use_case` provider: `Factory(ListUsersUseCase, port=list_users_adapter)`.
      (plan.md step 8)
- [ ] `"app.features.users.list_users.presentation.router"` is present in
      `Container.wiring_config.modules`. (`agent_docs/entry_points/fastapi.md`
      § Dependency injection at the endpoint)
- [ ] Endpoint uses `Annotated[ListUsersUseCase, Depends(Provide[Container.list_users_use_case])]`.
      (`agent_docs/entry_points/fastapi.md` § Dependency injection at the endpoint)

### Files and headers

- [ ] Every new `.py` file (non-empty) starts with `# FEATURE: list_users — <purpose>`
      on line 1. (N4; `agent_docs/stable_vs_feature.md`)
- [ ] The only STABLE file modified is `bootstrap/container.py` (approved in
      grill-me; see prd.md). No other STABLE file is touched. (N4;
      `agent_docs/stable_vs_feature.md`)
- [ ] Pydantic schemas that wrap ORM data carry
      `model_config = ConfigDict(from_attributes=True)`. (N3; `CLAUDE.md`)
- [ ] No `model.dict()` — only `model.model_dump()` if used. (`CLAUDE.md`)
- [ ] `src/app/features/users/use_cases/user_list.py` is deleted; no file
      anywhere still imports from it. (prd.md; plan.md step 10)

### Tests

- [ ] Use-case unit test exists at
      `tests/features/users/0003_list_users/domain/test_use_case.py` and
      passes. Verifies that `__call__` returns the value from `port.list`. (F11)
- [ ] Adapter unit test exists at
      `tests/features/users/0003_list_users/data/test_adapter.py` and passes.
      Covers: soft-delete filter (F4), pagination offset (F9), total_count
      accuracy (F10), infrastructure exception propagation (F14).
- [ ] Endpoint integration test exists at
      `tests/features/users/0003_list_users/presentation/test_router.py` and
      passes. Covers: 200 happy path (F1–F3), 422 for invalid params (F5, F6),
      soft-deleted user absent (F4), default params (F7, F8).
- [ ] Outside-in test exists at
      `tests/features/users/0003_list_users/list_users_outside_in_test.py` and
      is **GREEN**. (Acceptance gate; never skipped)

### Quality gates

Run from the project root before approving:

```
ruff format src/app tests
ruff check src/app tests
mypy src/app
pytest
```

All must pass. The `pytest` run includes `tests/smoke/test_app_starts.py`,
which boots the app in a subprocess and pings `/api/v1/health`. If the smoke
test fails, the slice is **not done** — it typically indicates an accidental
absolute import (`from app...`) inside `src/app/` that works under pytest's
`pythonpath = ["src"]` but fails under uvicorn.
