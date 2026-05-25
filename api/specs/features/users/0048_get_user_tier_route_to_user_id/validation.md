# 0048 · get_user_tier_route_to_user_id — Validation

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md
- Requirements: ./requirements.md

## Prerequisites

- App running locally: `cd src && uvicorn app.main:app --reload`
- Postgres accessible; schema up-to-date (`alembic upgrade head`).
- The route is **unauthenticated** (the existing slice-0005 route has no auth
  dependency), so no Bearer token is required.
- There is **no HTTP route that assigns a tier to a user** yet (only
  `get_user_tier` exists in this feature). The tier link must be seeded directly:
  create a tier via the tiers endpoint, then set the user's `tier_id` in the DB.

```bash
# Register a user (capture the returned id — this is the user_id under test):
curl -s -X POST http://localhost:8000/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{"username":"tieruser","email":"tier@example.com","password":"Pa$$w0rd1"}' \
  | python -m json.tool
# → { "id": 42, "username": "tieruser", ... }   ← capture user_id (e.g. 42)

# Register a second user with NO tier (for the 200/null scenario):
curl -s -X POST http://localhost:8000/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{"username":"notier","email":"notier@example.com","password":"Pa$$w0rd2"}' \
  | python -m json.tool
# → { "id": 43, "username": "notier", ... }   ← capture no_tier_user_id (e.g. 43)

# Create a tier (capture its id):
curl -s -X POST http://localhost:8000/api/v1/tiers \
  -H "Content-Type: application/json" \
  -d '{"name":"pro"}' \
  | python -m json.tool
# → { "id": 7, "name": "pro", ... }   ← capture tier_id (e.g. 7)

# Link the tier to the first user directly in Postgres (no HTTP route exists):
psql "$DATABASE_URL" -c "UPDATE \"user\" SET tier_id = 7 WHERE id = 42;"
```

---

## Manual scenarios

### S1 — Happy path: get a user's tier by user_id

**Steps:**

1. Use `user_id = 42` (the user linked to tier `pro`).
2. Send:

```bash
curl -s http://localhost:8000/api/v1/user/42/tier | python -m json.tool
```

**Expected:**

- HTTP 200.
- Body matches `GetUserTierResponse`: `{"tier_id": 7, "tier_name": "pro", "tier_created_at": "..."}`.
- Response keys are exactly `tier_id`, `tier_name`, `tier_created_at`.

**Covers:** F1, F4, F8.

---

### S2 — User exists but has no tier assigned

**Steps:**

1. Use `no_tier_user_id = 43` (the user with `tier_id IS NULL`).
2. Send:

```bash
curl -s -i http://localhost:8000/api/v1/user/43/tier
```

**Expected:**

- HTTP 200.
- Body is `null` (existing slice-0005 behaviour, unchanged — **not** a 404).

**Covers:** F2, F7, F8.

---

### S3 — Not found: unknown user_id

**Steps:**

1. Send a request with an ID that does not exist (e.g. `999999`):

```bash
curl -s http://localhost:8000/api/v1/user/999999/tier | python -m json.tool
```

**Expected:**

- HTTP 404.
- Body: `{"error": {"code": "notfound", "message": "User not found"}}`.

**Covers:** F5, F8, F9.

---

### S4 — Tier referenced but tier row absent

**Steps:**

1. Point a user at a non-existent tier id, then query (this state is only
   reachable by direct DB manipulation since no route deletes a tier in use):

```bash
psql "$DATABASE_URL" -c "UPDATE \"user\" SET tier_id = 999999 WHERE id = 42;"
curl -s http://localhost:8000/api/v1/user/42/tier | python -m json.tool
```

**Expected:**

- HTTP 404.
- Body: `{"error": {"code": "notfound", "message": "Tier not found"}}`.

**Covers:** F6, F8, F9. (Restore with `UPDATE "user" SET tier_id = 7 WHERE id = 42;` afterward.)

---

### S5 — Unprocessable: non-integer path param

**Steps:**

1. Send a request with a string path param:

```bash
curl -s -i http://localhost:8000/api/v1/user/abc/tier
```

**Expected:**

- HTTP 422.
- Body contains a Pydantic validation error indicating `user_id` must be an
  integer.

**Covers:** F3.

---

## Code review checklist

### Architecture

- [ ] The existing `get_user_tier` slice folder at
      `src/app/features/users/get_user_tier/` retains its `domain/`, `data/`,
      `presentation/` layout — no new folders added, none removed.
- [ ] `GetUserTierUseCase` is a class with a single `__call__()` method that
      accepts `GetUserTierQuery` and returns `FoundUserTier | None`.
- [ ] `GetUserTierPort` lives in `domain/ports/get_user_tier_port.py`, carries
      `@runtime_checkable`, and inherits from `typing.Protocol`.
- [ ] `GetUserTierAdapter` signature is
      `class GetUserTierAdapter(GetUserTierPort):` — explicit inheritance from
      the port is mandatory.
- [ ] The adapter is the only place SQLAlchemy (`select`) is used.
- [ ] The router accepts `user_id: int` path param, converts to
      `GetUserTierQuery(user_id=user_id)`, awaits the use-case, and returns
      `GetUserTierResponse | None`.
- [ ] The route path keeps the singular `/user/{user_id}/tier` segment
      (only `{username}` → `{user_id}` changed).
- [ ] No cross-slice imports outside `users/_shared/`.
- [ ] All imports inside `src/app/` are **relative** (e.g.
      `from ..domain.commands import GetUserTierQuery`). No `from app...` or
      `from src.app...` inside source files.
- [ ] No `HTTPException` raised inside the use-case.

### Error handling

- [ ] `GetUserTierAdapter.get` has **no `try/except`** — it is a read-only
      lookup with nothing business-meaningful to translate.
- [ ] No broad `except Exception` blocks in any modified file.
- [ ] The adapter does not log exceptions.
- [ ] The "user has no tier" case returns `None` (→ 200/null), and only the
      genuinely-missing cases (`UserNotFound`, `TierNotFound`) raise
      `NotFoundDomainError`.
- [ ] No new `DomainError` subclass was introduced in the slice folder; only the
      existing `NotFoundDomainError` from `app/domain/errors.py` is raised.

### Files and headers

- [ ] All modified FEATURE files retain their `# FEATURE: <slice> — <purpose>`
      header on line 1.
- [ ] No STABLE files were modified. `bootstrap/container.py`,
      `bootstrap/router.py`, and `.importlinter` are **not** touched (providers,
      router registration, and the import-linter ignore entry already exist from
      slice 0005).
- [ ] `GetUserTierResponse` retains
      `model_config = ConfigDict(from_attributes=True)` (unchanged schema).
- [ ] No `model.dict()` — only `model.model_dump()` if any serialization is added.

### DI

- [ ] `get_user_tier_adapter` and `get_user_tier_use_case` providers in
      `bootstrap/container.py` are unchanged (they already exist).
- [ ] `get_user_tier.presentation.router` module path remains in
      `Container.wiring_config.modules` (already present).
- [ ] Endpoint still uses
      `Annotated[GetUserTierUseCase, Depends(Provide[Container.get_user_tier_use_case])]`.

### Tests

- [ ] `tests/features/users/0005_get_user_tier/domain/test_use_case.py` updated
      to build `GetUserTierQuery(user_id=...)`; covers UserNotFound→404,
      TierNotFound→404, None pass-through, FoundUserTier pass-through; passes.
- [ ] `tests/features/users/0005_get_user_tier/data/test_adapter.py` updated to
      assert the lookup filters on `User.id == query.user_id`; passes.
- [ ] `tests/features/users/0005_get_user_tier/presentation/test_router.py`
      updated to use `/api/v1/user/{id}/tier` paths and includes a 422 case for a
      non-integer `user_id`; passes.
- [ ] `tests/features/users/0005_get_user_tier/get_user_tier_outside_in_test.py`
      updated to capture the seeded user's `id` and build the URL with it;
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
