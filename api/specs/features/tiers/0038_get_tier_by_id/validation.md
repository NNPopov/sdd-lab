# 0038 · get_tier_by_id — Validation

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md
- Requirements: ./requirements.md

## Prerequisites

- App running locally: `cd src && uvicorn app.main:app --reload`
- A superuser token is **not** required — the endpoint is public (F4).
- At least one tier row in the database. Create one if needed:
  ```
  curl -s -X POST http://localhost:8000/api/v1/tier \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer <superuser_token>" \
    -d '{"name": "validation-tier"}'
  ```
  Note the returned `id` — use it in scenarios S1 and S4.

## Manual scenarios

### S1 — Happy path: existing tier returns 200 with correct body

**Steps:**

1. Obtain the `id` of an existing tier (from the create step in Prerequisites,
   or by running `GET /api/v1/tier` to list tiers and picking one).
2. ```
   curl -s http://localhost:8000/api/v1/tier/<id>
   ```

**Expected:**

- Status `200 OK`.
- Body is a JSON object with exactly the fields `id` (integer matching the path
  parameter), `name` (string), and `created_at` (ISO 8601 datetime string).
- No extra fields (the response is `GetTierResponse`, not a raw ORM row).

**Covers:** F1, F7.

---

### S2 — Not found: non-existent id returns 404

**Steps:**

1. ```
   curl -s http://localhost:8000/api/v1/tier/999999
   ```
   (Assumes no tier with id 999999 exists. If it does, use a higher value.)

**Expected:**

- Status `404 Not Found`.
- Body:
  ```json
  {
    "error": {
      "code": "notfound",
      "message": "Tier not found"
    }
  }
  ```

**Covers:** F2, F6, F8.

---

### S3 — Non-integer path parameter returns 422

**Steps:**

1. ```
   curl -s http://localhost:8000/api/v1/tier/gold
   ```

**Expected:**

- Status `422 Unprocessable Entity`.
- Body is FastAPI's standard validation error payload; the `loc` array
  includes `["path", "tier_id"]`.
- The use-case is **not** invoked; no database query is made.

**Covers:** F3.

---

### S4 — Unauthenticated request returns 200 for existing tier

**Steps:**

1. Use the same `id` as in S1.
2. ```
   curl -s http://localhost:8000/api/v1/tier/<id>
   ```
   (No `Authorization` header.)

**Expected:**

- Status `200 OK`.
- Body identical to S1 — the endpoint is public; absence of a token does not
  cause 401 or 403.

**Covers:** F4.

---

### S5 — Old name-based path no longer resolves by name

**Steps:**

1. Pick the `name` of an existing tier (e.g. `"validation-tier"`).
2. ```
   curl -s http://localhost:8000/api/v1/tier/validation-tier
   ```

**Expected:**

- Status `404 Not Found` (the path parameter is now typed `int`; the string
  `"validation-tier"` triggers 422 if FastAPI validates it as int, or 404 if
  the string happens to be a valid integer-looking name that does not exist).
  Either 404 or 422 is acceptable — a `200` with the tier body would indicate
  the name-based route is still active, which is a regression.

**Note:** This scenario has no corresponding automated test because it is a
negative regression check on removed behavior. If it returns 200, the router
change did not take effect.

**Covers:** PRD § Solution (path changed from name to id).

---

## Code review checklist

For the reviewer to verify on the PR. This is a **modification** of the
existing `get_tier` slice — no new slice folder, no new DI providers, no new
router registration.

### Architecture

- [ ] Only three files under `src/app/features/tiers/get_tier/` are changed:
      `domain/commands.py`, `data/adapter.py`, `presentation/router.py`.
- [ ] `get_tier/domain/ports/get_tier_port.py` is **unchanged** — the port
      carries `GetTierQuery` and its method signature is unaffected.
- [ ] `get_tier/domain/use_case.py` is **unchanged**.
- [ ] `get_tier/presentation/schemas.py` is **unchanged** — `GetTierResponse`
      shape is identical.
- [ ] `GetTierQuery` now has `id: int` (not `name: str`) — one field, no
      constraints.
- [ ] Router path is `/tier/{tier_id}` where `tier_id: int`.
- [ ] `GetTierQuery(id=tier_id)` is constructed in the router, not
      `GetTierQuery(name=...)`.
- [ ] Adapter `WHERE` clause is `Tier.id == query.id` (not `Tier.name`).
- [ ] Use-case receives a domain `GetTierQuery`; it does not receive the raw
      `tier_id` integer.
- [ ] No `HTTPException` raised inside `GetTierUseCase`.
- [ ] All imports inside `src/app/` are **relative**. No `from app...` inside
      source files.
- [ ] No cross-slice imports outside `features/tiers/_shared/`.

### Error handling

- [ ] `GetTierAdapter.get` has **no `try/except`** — it is a read-only query;
      infrastructure exceptions propagate to the global handler.
- [ ] Adapter does not log exceptions.
- [ ] No new `DomainError` subclass was introduced in this slice.

### Files and headers

- [ ] Modified files retain the `# FEATURE: get_tier — <purpose>` header on
      line 1 (not changed to `# FEATURE: get_tier_by_id`).
- [ ] No STABLE files were modified (`bootstrap/container.py`,
      `bootstrap/router.py`, `features/tiers/router.py` are all untouched).
- [ ] `GetTierResponse` retains `model_config = ConfigDict(from_attributes=True)`.
- [ ] No `model.dict()` usage anywhere in changed files.

### DI

- [ ] **No new providers** added to `bootstrap/container.py` — `get_tier_adapter`
      and `get_tier_use_case` already exist and are reused unchanged.
- [ ] **No new wiring_config entry** — `get_tier.presentation.router` is already
      in the wiring list.
- [ ] **No new include_router** in `features/tiers/router.py` — `get_tier_router`
      is already registered.

### Port contract (N10, N11)

- [ ] `GetTierAdapter` still explicitly inherits from `GetTierPort`:
      `class GetTierAdapter(GetTierPort):`.
- [ ] `GetTierPort` retains the `@runtime_checkable` decorator.

### Tests

- [ ] `tests/features/tiers/0038_get_tier_by_id/conftest.py` and
      `get_tier_by_id_outside_in_test.py` exist and the outside-in test is GREEN.
- [ ] All four 0035 test files updated to use `GetTierQuery(id=...)` instead of
      `GetTierQuery(name=...)` and endpoint paths use `/{id}` instead of `/{name}`.
- [ ] No 0035 test is left using the old name-based query (grep for `name=` in
      the 0035 test directory to confirm).
- [ ] Test database transaction rollback works — no tier rows persist between tests.

### Quality gates

Run from the project root (or `src/` for uvicorn):

```
ruff format src/app tests
ruff check src/app tests
mypy src/app
pytest
```

All must pass, including `tests/smoke/test_app_starts.py`. A failing smoke
test — even with all other tests green — means the slice is not done. Typical
cause: an accidental `from app...` absolute import inside `src/app/` that
pytest resolves but uvicorn does not.
