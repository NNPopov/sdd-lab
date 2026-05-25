# 0049 · rate_limits_route_to_user_id — Validation

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md
- Requirements: ./requirements.md

## Prerequisites

- App running locally: `cd src && uvicorn app.main:app --reload`
- Postgres accessible; schema up-to-date (`alembic upgrade head`).
- This route is **superuser-only** (`Depends(get_current_superuser)`), so a
  superuser Bearer token is required for the happy-path and 404 scenarios.
- There is **no HTTP route that assigns a tier to a user** yet; the tier link and
  rate-limit rows must be seeded directly in the DB.

```bash
# Seed a superuser (project script) if one does not exist:
cd src && python -m scripts.create_first_superuser

# Obtain a superuser token (OAuth2 form login at POST /api/v1/login):
SU_TOKEN=$(curl -s -X POST http://localhost:8000/api/v1/login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admin&password=<admin-password>" \
  | python -c "import sys,json; print(json.load(sys.stdin)['access_token'])")

# Register a normal (non-superuser) user — used for the 403 scenario and as a target:
curl -s -X POST http://localhost:8000/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{"username":"rluser","email":"rl@example.com","password":"Pa$$w0rd1"}' \
  | python -m json.tool
# → { "id": 42, "username": "rluser", ... }   ← capture target user_id (e.g. 42)

# Register a second user with NO tier (for the empty-rate-limits scenario):
curl -s -X POST http://localhost:8000/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{"username":"notier","email":"notier@example.com","password":"Pa$$w0rd2"}' \
  | python -m json.tool
# → { "id": 43, ... }   ← capture no_tier_user_id (e.g. 43)

# A normal user's token (for the 403 scenario):
USER_TOKEN=$(curl -s -X POST http://localhost:8000/api/v1/login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=rluser&password=Pa\$\$w0rd1" \
  | python -c "import sys,json; print(json.load(sys.stdin)['access_token'])")

# Create a tier (capture its id):
curl -s -X POST http://localhost:8000/api/v1/tiers \
  -H "Content-Type: application/json" -d '{"name":"pro"}' | python -m json.tool
# → { "id": 7, "name": "pro", ... }   ← capture tier_id (e.g. 7)

# Seed a rate-limit row for that tier and link the tier to the target user:
psql "$DATABASE_URL" -c "INSERT INTO rate_limit (tier_id, name, path, limit, period) VALUES (7, 'pro_login', 'login', 10, 60);"
psql "$DATABASE_URL" -c "UPDATE \"user\" SET tier_id = 7 WHERE id = 42;"
```

---

## Manual scenarios

### S1 — Happy path: get a user's rate limits by user_id

**Steps:**

1. Use `user_id = 42` (linked to tier `pro`, which has a rate-limit row).
2. Send:

```bash
curl -s http://localhost:8000/api/v1/user/42/rate_limits \
  -H "Authorization: Bearer $SU_TOKEN" | python -m json.tool
```

**Expected:**

- HTTP 200.
- Body carries the user fields (`id`, `name`, `username`, `email`,
  `profile_image_url`, `tier_id`) plus a `tier_rate_limits` list containing the
  seeded rate-limit row.

**Covers:** F1, F3, F6, F7 (auth passes for superuser).

---

### S2 — User exists but has no tier assigned

**Steps:**

1. Use `no_tier_user_id = 43` (`tier_id IS NULL`).
2. Send:

```bash
curl -s http://localhost:8000/api/v1/user/43/rate_limits \
  -H "Authorization: Bearer $SU_TOKEN" | python -m json.tool
```

**Expected:**

- HTTP 200.
- Body has `tier_rate_limits` equal to `[]` (empty list).

**Covers:** F2.

---

### S3 — Unauthorized: no credentials

**Steps:**

```bash
curl -s -i http://localhost:8000/api/v1/user/42/rate_limits
```

**Expected:**

- HTTP 401.

**Covers:** F7.

---

### S4 — Forbidden: authenticated non-superuser

**Steps:**

```bash
curl -s -i http://localhost:8000/api/v1/user/42/rate_limits \
  -H "Authorization: Bearer $USER_TOKEN"
```

**Expected:**

- HTTP 403.

**Covers:** F8.

---

### S5 — Not found: unknown user_id

**Steps:**

```bash
curl -s http://localhost:8000/api/v1/user/999999/rate_limits \
  -H "Authorization: Bearer $SU_TOKEN" | python -m json.tool
```

**Expected:**

- HTTP 404.
- Body: `{"error": {"code": "notfound", "message": "User not found"}}`.

**Covers:** F4, F9.

---

### S6 — Not found: tier referenced but tier row absent

**Steps:**

```bash
psql "$DATABASE_URL" -c "UPDATE \"user\" SET tier_id = 999999 WHERE id = 42;"
curl -s http://localhost:8000/api/v1/user/42/rate_limits \
  -H "Authorization: Bearer $SU_TOKEN" | python -m json.tool
```

**Expected:**

- HTTP 404.
- Body: `{"error": {"code": "notfound", "message": "Tier not found"}}`.

**Covers:** F5, F9. (Restore with `UPDATE "user" SET tier_id = 7 WHERE id = 42;` afterward.)

---

### S7 — Unprocessable: non-integer path param

**Steps:**

```bash
curl -s -i http://localhost:8000/api/v1/user/abc/rate_limits \
  -H "Authorization: Bearer $SU_TOKEN"
```

**Expected:**

- HTTP 422.
- Body contains a Pydantic validation error indicating `user_id` must be an
  integer.

**Covers:** F10.

---

## Code review checklist

### Architecture

- [ ] `read_user_rate_limits` remains a free async function in
      `src/app/features/users/use_cases/user_rate_limits_get.py` — it is **not**
      refactored into a hexagonal slice (no port/adapter/use-case class added).
- [ ] The function parameter is `user_id: int` (replacing `username: str`); the
      `Request` and `db: Annotated[AsyncSession, Depends(async_get_db)]` params
      are unchanged.
- [ ] The user lookup is `crud_users.get(db=db, id=user_id, schema_to_select=UserRead)`
      (changed from `username=username`); the tier and rate-limit lookups are
      unchanged.
- [ ] The route is registered as
      `router.get("/user/{user_id}/rate_limits", dependencies=[Depends(get_current_superuser)])(read_user_rate_limits)`
      in `features/users/router.py` — only the path segment changed; the auth
      dependency is preserved.
- [ ] The route keeps the singular `/user/{user_id}/rate_limits` segment.
- [ ] Cross-slice imports are limited to `repository.py` cross-imports
      (`crud_tiers`, `crud_rate_limits`); no other slice's `schemas.py` or
      `router.py` is imported (the existing `TierRead` import is from
      `tiers/schemas.py` — see note below).
- [ ] All imports inside `src/app/` are **relative** (e.g.
      `from ..repository import crud_users`). No `from app...` or
      `from src.app...` inside source files.
- [ ] No `HTTPException` raised inside the function.

> Note: `user_rate_limits_get.py` already imports `TierRead` from
> `tiers/schemas.py`. That cross-schema import is pre-existing and out of scope
> for this slice; do not remove or "fix" it here.

### Error handling

- [ ] `read_user_rate_limits` has **no `try/except`** — the repository calls are
      read-only with nothing business-meaningful to translate.
- [ ] No broad `except Exception` blocks in any modified file.
- [ ] The function does not log exceptions.
- [ ] The "user has no tier" case returns `tier_rate_limits == []` (→ 200), and
      only the genuinely-missing cases raise `NotFoundDomainError`.
- [ ] No new `DomainError` subclass was introduced; only the existing
      `NotFoundDomainError` from `app/domain/errors.py` is raised.

### Files and headers

- [ ] Both modified FEATURE files retain their `# FEATURE: <purpose>` header on
      line 1 (`user_rate_limits_get.py`, `router.py`).
- [ ] No STABLE file was modified. The route lives in `features/users/router.py`
      (FEATURE); no `bootstrap/container.py` provider, `wiring_config` entry, or
      `.importlinter` entry is added (the function is `Depends`-wired, not
      container-wired).
- [ ] No `model.dict()` is introduced — only `model.model_dump()` if any
      serialization is added (none is expected; the function returns a `dict`).

### DI

- [ ] No DI provider is added — this endpoint is a free function wired via
      FastAPI `Depends(async_get_db)`, not via the `dependency_injector`
      container. (This differs from hexagonal slices; it is correct here.)

### Tests

- [ ] A new test folder `tests/features/users/0049_rate_limits_route_to_user_id/`
      exists.
- [ ] Function-level unit test asserts `crud_users.get` is called with
      `id=user_id`; covers user-`None`→404, tier-`None`→404, no-tier→`[]`, and
      the populated-tier path; passes.
- [ ] Endpoint integration test (`presentation/test_router.py`) uses
      `httpx.AsyncClient` and covers 200 (with tier), 200 (empty), 401, 403, 404,
      422; passes.
- [ ] Outside-in test (`rate_limits_route_to_user_id_outside_in_test.py`) exists,
      is the acceptance gate, and is GREEN.
- [ ] The slice `conftest.py` overrides **both** `container.session_factory` and
      `async_get_db` — this is a fat-handler endpoint that calls `async_get_db`
      directly and bypasses the DI container, so overriding only the container is
      insufficient. Per `agent_docs/testing.md` § Fat-handler migration slices.
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
