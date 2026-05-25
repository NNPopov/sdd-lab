# 0050 · update_user_tier_route_to_user_id — Validation

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md
- Requirements: ./requirements.md

## Prerequisites

- App running locally: `cd src && uvicorn app.main:app --reload`
- Postgres accessible; schema up-to-date (`alembic upgrade head`).
- This route is **superuser-only** (`Depends(get_current_superuser)`), so a
  superuser Bearer token is required for the happy-path and 404 scenarios.

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
  -d '{"username":"tieruser","email":"tier@example.com","password":"Pa$$w0rd1"}' \
  | python -m json.tool
# → { "id": 42, "username": "tieruser", ... }   ← capture target user_id (e.g. 42)

# A normal user's token (for the 403 scenario):
USER_TOKEN=$(curl -s -X POST http://localhost:8000/api/v1/login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=tieruser&password=Pa\$\$w0rd1" \
  | python -c "import sys,json; print(json.load(sys.stdin)['access_token'])")

# Create a tier (capture its id):
curl -s -X POST http://localhost:8000/api/v1/tiers \
  -H "Content-Type: application/json" -d '{"name":"pro"}' | python -m json.tool
# → { "id": 7, "name": "pro", ... }   ← capture tier_id (e.g. 7)
```

---

## Manual scenarios

### S1 — Happy path: update a user's tier by user_id

**Steps:**

1. Use `user_id = 42` and `tier_id = 7`.
2. Send:

```bash
curl -s -X PATCH http://localhost:8000/api/v1/user/42/tier \
  -H "Authorization: Bearer $SU_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"tier_id": 7}' | python -m json.tool
```

**Expected:**

- HTTP 200.
- Body: `{"message": "User <name> Tier updated"}` (where `<name>` is the user's
  `name`).
- Verify the change via slice 0048:
  `curl -s http://localhost:8000/api/v1/user/42/tier -H "Authorization: Bearer $SU_TOKEN"`
  reflects `tier_id = 7`.

**Covers:** F1, F2, F3, F6, F7 (auth passes for superuser).

---

### S2 — Not found: unknown user_id

**Steps:**

```bash
curl -s -X PATCH http://localhost:8000/api/v1/user/999999/tier \
  -H "Authorization: Bearer $SU_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"tier_id": 7}' | python -m json.tool
```

**Expected:**

- HTTP 404.
- Body: `{"error": {"code": "notfound", "message": "User not found"}}`.

**Covers:** F4, F9.

---

### S3 — Not found: unknown tier_id

**Steps:**

```bash
curl -s -X PATCH http://localhost:8000/api/v1/user/42/tier \
  -H "Authorization: Bearer $SU_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"tier_id": 999999}' | python -m json.tool
```

**Expected:**

- HTTP 404.
- Body: `{"error": {"code": "notfound", "message": "Tier not found"}}`.

**Covers:** F5, F9.

---

### S4 — Unauthorized: no credentials

**Steps:**

```bash
curl -s -i -X PATCH http://localhost:8000/api/v1/user/42/tier \
  -H "Content-Type: application/json" -d '{"tier_id": 7}'
```

**Expected:**

- HTTP 401.

**Covers:** F7.

---

### S5 — Forbidden: authenticated non-superuser

**Steps:**

```bash
curl -s -i -X PATCH http://localhost:8000/api/v1/user/42/tier \
  -H "Authorization: Bearer $USER_TOKEN" \
  -H "Content-Type: application/json" -d '{"tier_id": 7}'
```

**Expected:**

- HTTP 403.

**Covers:** F8.

---

### S6 — Unprocessable: non-integer path param

**Steps:**

```bash
curl -s -i -X PATCH http://localhost:8000/api/v1/user/abc/tier \
  -H "Authorization: Bearer $SU_TOKEN" \
  -H "Content-Type: application/json" -d '{"tier_id": 7}'
```

**Expected:**

- HTTP 422.
- Body contains a Pydantic validation error indicating `user_id` must be an
  integer.

**Covers:** F10.

---

## Code review checklist

### Architecture

- [ ] `patch_user_tier` remains a free async function in
      `src/app/features/users/use_cases/user_tier_patch.py` — it is **not**
      refactored into a hexagonal slice (no port/adapter/use-case class added).
- [ ] The function parameter is `user_id: int` (replacing `username: str`); the
      `Request`, `values: UserTierUpdate`, and
      `db: Annotated[AsyncSession, Depends(async_get_db)]` params are unchanged.
- [ ] The user lookup is `crud_users.get(db=db, id=user_id, schema_to_select=UserRead)`
      (changed from `username=username`).
- [ ] The update call is `crud_users.update(db=db, object=values.model_dump(), id=user_id)`
      (changed from `username=username`) — the UPDATE WHERE clause targets the id.
- [ ] The tier lookup (`crud_tiers.get(db=db, id=values.tier_id, ...)`) and the
      success-message return are unchanged.
- [ ] The route is registered as
      `router.patch("/user/{user_id}/tier", dependencies=[Depends(get_current_superuser)])(patch_user_tier)`
      in `features/users/router.py` — only the path segment changed; the method
      and auth dependency are preserved.
- [ ] Cross-slice imports are limited to `repository.py` cross-imports
      (`crud_tiers`); no other slice's `router.py` is imported (the existing
      `TierRead` import is from `tiers/schemas.py` — see note below).
- [ ] All imports inside `src/app/` are **relative** (e.g.
      `from ..repository import crud_users`). No `from app...` or
      `from src.app...` inside source files.
- [ ] No `HTTPException` raised inside the function.

> Note: `user_tier_patch.py` already imports `TierRead` from `tiers/schemas.py`.
> That cross-schema import is pre-existing and out of scope for this slice; do
> not remove or "fix" it here.

### Error handling

- [ ] `patch_user_tier` has **no `try/except`** — nothing business-meaningful to
      translate.
- [ ] No broad `except Exception` blocks in any modified file.
- [ ] The function does not log exceptions.
- [ ] `crud_users.update` is only reached after both the user and the tier are
      confirmed present; the two missing cases raise `NotFoundDomainError`.
- [ ] No new `DomainError` subclass was introduced; only the existing
      `NotFoundDomainError` from `app/domain/errors.py` is raised.

### Files and headers

- [ ] Both modified FEATURE files retain their `# FEATURE: <purpose>` header on
      line 1 (`user_tier_patch.py`, `router.py`).
- [ ] No STABLE file was modified. The route lives in `features/users/router.py`
      (FEATURE); no `bootstrap/container.py` provider, `wiring_config` entry, or
      `.importlinter` entry is added (the function is `Depends`-wired, not
      container-wired).
- [ ] `model.model_dump()` is used (not `model.dict()`) for the update payload.

### DI

- [ ] No DI provider is added — this endpoint is a free function wired via
      FastAPI `Depends(async_get_db)`, not via the `dependency_injector`
      container. (This differs from hexagonal slices; it is correct here.)

### Tests

- [ ] A new test folder
      `tests/features/users/0050_update_user_tier_route_to_user_id/` exists.
- [ ] Function-level unit test asserts `crud_users.get` is called with
      `id=user_id` and `crud_users.update` is called with `id=user_id`; covers
      user-`None`→404 (no update), tier-`None`→404 (no update), and the happy
      path; passes.
- [ ] Endpoint integration test (`presentation/test_router.py`) uses
      `httpx.AsyncClient` and covers 200, 404 (unknown user), 404 (unknown tier),
      401, 403, 422; passes.
- [ ] Outside-in test (`update_user_tier_route_to_user_id_outside_in_test.py`)
      exists, is the acceptance gate, and is GREEN.
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
