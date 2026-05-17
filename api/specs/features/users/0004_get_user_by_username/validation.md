# 0004 · get_user_by_username — Validation

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md
- Requirements: ./requirements.md

## Prerequisites

- App running locally (`uvicorn app.main:app --reload` from `src/`).
- Test database has at least one active (non-deleted) user row. Create one via
  `POST /api/v1/user` if needed.
- At least one soft-deleted user row for S3 (set `is_deleted = true` directly
  in the DB or trigger deletion via the delete endpoint).
- No authentication token required — `GET /api/v1/user/{username}` is public.

## Manual scenarios

### S1 — Happy path (existing user)

**Steps:**

1. Note the `username` of a non-deleted user in the database.

```bash
curl -s http://localhost:8000/api/v1/user/<username> | python -m json.tool
```

**Expected:**

- HTTP status **200**.
- Response body contains exactly the six fields: `id`, `name`, `username`,
  `email`, `profile_image_url`, `tier_id`.
- All field values match the corresponding row in the `user` table.
- `tier_id` is `null` if the user has no tier, or an integer if they do.

**Covers:** F1, F2, F8, F9, F10.

---

### S2 — Unknown username returns 404

**Steps:**

```bash
curl -s http://localhost:8000/api/v1/user/does_not_exist_xyz | python -m json.tool
```

**Expected:**

- HTTP status **404**.
- Response body `{"message": "User not found"}`.

**Covers:** F3, F4, F5, F6.

---

### S3 — Soft-deleted user returns 404

**Steps:**

1. Confirm a soft-deleted user exists:

```sql
SELECT username FROM "user" WHERE is_deleted = true LIMIT 1;
```

2. Note the username and query it:

```bash
curl -s http://localhost:8000/api/v1/user/<deleted_username> | python -m json.tool
```

**Expected:**

- HTTP status **404**.
- Response body `{"message": "User not found"}`.
- Indistinguishable from the "unknown username" case (F7).

**Covers:** F5, F6, F7.

---

### S4 — Infrastructure failure returns 500

**Steps:**

1. Stop the PostgreSQL server (or temporarily revoke the DB connection).

```bash
curl -s http://localhost:8000/api/v1/user/anyusername | python -m json.tool
```

**Expected:**

- HTTP status **500**.
- Response body `{"message": "Internal error"}` — the global handler's
  standard output.
- Application logs contain the original SQLAlchemy `OperationalError` (or
  similar) with full traceback. The error is **not** wrapped in a `DomainError`
  subclass.

**Covers:** N2.

*Note: acceptable to skip manually if adapter unit test covers the propagation
path.*

---

## Code review checklist

### Architecture

- [ ] Slice folder exists at `src/app/features/users/get_user_by_username/`
      with `domain/`, `data/`, `presentation/` subfolders, each containing
      an `__init__.py`.
- [ ] `GetUserByUsernameUseCase` is a class with
      `__call__(self, query: GetUserByUsernameQuery) -> FoundUser` as its only
      public method. (N1; `agent_docs/architecture.md` § Use-case shape)
- [ ] `GetUserByUsernamePort` lives in
      `domain/ports/get_user_by_username_port.py`, is decorated with
      `@runtime_checkable`, and inherits from `typing.Protocol`. (N11;
      `agent_docs/architecture.md` § Port pattern)
- [ ] `GetUserByUsernameAdapter` class declaration is
      `class GetUserByUsernameAdapter(GetUserByUsernamePort):` — explicit port
      inheritance is mandatory. (N10; `agent_docs/architecture.md` § Adapter
      pattern)
- [ ] SQLAlchemy ORM code appears only inside `data/adapter.py`. (N2;
      `agent_docs/architecture.md` § Layer rules)
- [ ] Router converts `username` path parameter to `GetUserByUsernameQuery`,
      awaits use case, converts `FoundUser` to `GetUserByUsernameResponse`;
      no business logic in the endpoint function. (F9, F10;
      `agent_docs/entry_points/fastapi.md` § Endpoint shape)
- [ ] No file inside `get_user_by_username/` imports from another slice's
      `domain/`, `data/`, or `presentation/` layer. (N6;
      `agent_docs/architecture.md` § Layer rules)
- [ ] All imports inside `src/app/` are **relative** (`from ..domain...`,
      `from .....adapters...`). No `from app...` or `from src.app...` inside
      source files. (N12; `agent_docs/architecture.md` § Import conventions)
- [ ] No `HTTPException` is raised anywhere in `get_user_by_username/domain/`.
      (N5; `CLAUDE.md`)

### Error handling

- [ ] `GetUserByUsernameAdapter.get` contains **no `try/except` block** — it
      is a read-only operation with no business-meaningful exception path. (N2;
      `agent_docs/error_handling.md` § Right shape: read-only query, no catch)
- [ ] The adapter returns `None` (not raises) when no row is found; the use
      case converts `None` to `NotFoundDomainError`. (F6)
- [ ] `GetUserByUsernameUseCase.__call__` raises
      `NotFoundDomainError("User not found")` when the adapter returns `None`.
      (F3)
- [ ] No `except Exception` block anywhere in `data/adapter.py`.
      (`agent_docs/error_handling.md` § Forbidden patterns)
- [ ] No `logger` or structlog import in `data/adapter.py`. (N2;
      `agent_docs/error_handling.md` § Logging policy)
- [ ] No new `DomainError` subclass defined inside `get_user_by_username/`.
      All domain errors live in `app/domain/errors.py`.
      (`agent_docs/error_handling.md`)

### Query correctness

- [ ] Adapter SELECT predicate includes both `User.username == query.username`
      and `User.is_deleted == False`. (F5, F7)
- [ ] `scalar_one_or_none()` is used (not `scalar_one()`, which raises on
      missing rows). (F5, F6)
- [ ] Returned `FoundUser` is constructed from the ORM row's fields, not from
      the query object. (F2)

### DI wiring

- [ ] `Container` has a `get_user_by_username_adapter` provider:
      `Factory(GetUserByUsernameAdapter, session_factory=session_factory)`.
      (plan.md step 8)
- [ ] `Container` has a `get_user_by_username_use_case` provider:
      `Factory(GetUserByUsernameUseCase, port=get_user_by_username_adapter)`.
      (plan.md step 8)
- [ ] Presentation router defines a local helper
      `_get_get_user_by_username_use_case()` that lazily imports
      `container` and calls `container.get_user_by_username_use_case()`.
      (plan.md step 7; consistent with `create_user` and `list_users` routers)
- [ ] Endpoint injects the use case via
      `Annotated[GetUserByUsernameUseCase, Depends(_get_get_user_by_username_use_case)]`.

### Files and headers

- [ ] Every new non-empty `.py` file starts with
      `# FEATURE: get_user_by_username — <purpose>` on line 1. (N4;
      `agent_docs/stable_vs_feature.md`)
- [ ] The only STABLE file modified is `bootstrap/container.py` (two new
      providers). No other STABLE file is touched. (N4;
      `agent_docs/stable_vs_feature.md`)
- [ ] `GetUserByUsernameResponse` carries
      `model_config = ConfigDict(from_attributes=True)`. (N3; `CLAUDE.md`)
- [ ] No `model.dict()` — only `model.model_dump()` if used. (`CLAUDE.md`)
- [ ] `features/users/router.py` uses `router.include_router(get_user_by_username_router)`
      and no longer directly registers `read_user`. (plan.md step 9)
- [ ] `src/app/features/users/use_cases/user_get_by_username.py` is deleted;
      no file anywhere still imports from it. (plan.md step 10)

### Tests

- [ ] Use-case unit test exists at
      `tests/features/users/0004_get_user_by_username/domain/test_use_case.py`
      and passes. Covers: entity returned on success (F1), `NotFoundDomainError`
      raised on `None` (F3).
- [ ] Adapter unit test exists at
      `tests/features/users/0004_get_user_by_username/data/test_adapter.py`
      and passes. Covers: correct `FoundUser` returned for a matching row (F2),
      `None` returned when no row found (F5, F6), soft-delete filter applied
      (F7).
- [ ] Endpoint integration test exists at
      `tests/features/users/0004_get_user_by_username/presentation/test_router.py`
      and passes. Covers: 200 + all six fields for existing user (F1, F2, F8),
      404 for unknown username (F4), 404 for soft-deleted user (F7).
- [ ] Outside-in test exists at
      `tests/features/users/0004_get_user_by_username/get_user_by_username_outside_in_test.py`
      and is **GREEN**. (Acceptance gate; never skipped)

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
