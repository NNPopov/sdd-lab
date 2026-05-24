# 0040 · delete_tier_by_id — Validation

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md
- Requirements: ./requirements.md

## Prerequisites

- App running locally (`uvicorn app.main:app --reload` from `src/`).
- Test database reachable and migrations applied (`alembic upgrade head`).
- A superuser account exists; obtain a bearer token via
  `POST /api/v1/login` with superuser credentials.
- A non-superuser account exists; obtain a separate bearer token for 403 tests.
- Insert a tier to use as the delete target (capture `id` from the INSERT or
  from `GET /api/v1/tiers`).

## Manual scenarios

### S1 — Happy path: delete existing tier by id

**Steps:**

1. Seed a tier and note its `id` (e.g. `id = 7`).
2. ```
   curl -s -X DELETE http://localhost:8000/api/v1/tier/7 \
     -H "Authorization: Bearer <superuser_token>"
   ```

**Expected:**

- Status `200 OK`.
- Body: `{"message": "Tier deleted"}`.
- `SELECT * FROM tier WHERE id = 7` returns no rows.

**Covers:** F1, F5, F10.

---

### S2 — Not found: no tier with given id

**Steps:**

1. Choose an `id` that does not exist in the `tier` table (e.g. `999999`).
2. ```
   curl -s -X DELETE http://localhost:8000/api/v1/tier/999999 \
     -H "Authorization: Bearer <superuser_token>"
   ```

**Expected:**

- Status `404 Not Found`.
- Body: `{"error": {"code": "notfound", "message": "Tier not found"}}`.
- No rows affected in the database.

**Covers:** F4, F6.

---

### S3 — Invalid id: non-integer path segment

**Steps:**

1. ```
   curl -s -X DELETE http://localhost:8000/api/v1/tier/gold \
     -H "Authorization: Bearer <superuser_token>"
   ```

**Expected:**

- Status `422 Unprocessable Entity`.
- Body contains FastAPI validation error indicating `id` must be an integer.
- Use-case is never reached.

**Covers:** F2.

---

### S4 — Forbidden: authenticated non-superuser

**Steps:**

1. Seed a tier and note its `id`.
2. ```
   curl -s -X DELETE http://localhost:8000/api/v1/tier/<id> \
     -H "Authorization: Bearer <regular_user_token>"
   ```

**Expected:**

- Status `403 Forbidden`.
- Body: `{"error": {"code": "forbidden", "message": "Superuser required"}}` (or
  equivalent message from `get_current_superuser`).
- Tier still exists in the database.

**Covers:** F7.

---

### S5 — Unauthorized: no token

**Steps:**

1. ```
   curl -s -X DELETE http://localhost:8000/api/v1/tier/1
   ```

**Expected:**

- Status `401 Unauthorized`.
- Body contains an authentication error.

**Covers:** F8.

---

### S6 — Idempotency: double delete

**Steps:**

1. Seed a tier and note its `id`.
2. Call `DELETE /api/v1/tier/{id}` with superuser token → expect 200.
3. Call `DELETE /api/v1/tier/{id}` again with the same token.

**Expected:**

- Second call returns `404 Not Found` (tier is already gone; `port.get` returns
  `None` → `NotFoundDomainError`).

**Covers:** F4, F6.

---

## Code review checklist

This slice is a **modification** of existing FEATURE files. DI, router
registration, and import-linter entries were created in slice 0037 and are
**not touched here**. Checklist items for new-slice scaffolding (provider
creation, wiring) are replaced with modification-specific checks.

### Architecture

- [ ] `DeleteTierCommand` has field `id: int`; `name` field is absent (F12).
- [ ] `DeleteTierPort.get` and `DeleteTierPort.delete` both accept
      `tier_id: int`; no `name: str` parameter remains (F11).
- [ ] `DeleteTierUseCase.__call__` uses `command.id`, not `command.name`,
      in both `port.get(...)` and `port.delete(...)` calls (F4, F5).
- [ ] `DeleteTierAdapter.get` filters by `Tier.id == tier_id` (F9).
- [ ] `DeleteTierAdapter.delete` filters by `Tier.id == tier_id` (F10).
- [ ] Router path is `/tier/{id}` with `id: int` parameter; path `/tier/{name}`
      is gone (F1, F3).
- [ ] `presentation/schemas.py` (`DeleteTierResponse`) is unchanged.
- [ ] No cross-slice imports outside `tiers/_shared/` (N6).
- [ ] All imports inside `src/app/` are **relative**; no `from app...` or
      `from src.app...` inside source (N6, per `agent_docs/architecture.md`
      § Import conventions).
- [ ] No `HTTPException` raised inside `DeleteTierUseCase` (N5).

### Error handling

- [ ] `DeleteTierAdapter.get` has no `try/except` — read-only query,
      no business-meaningful exception to translate (N2).
- [ ] `DeleteTierAdapter.delete` has no `try/except` — DELETE cannot violate
      a unique constraint (N2).
- [ ] No new `DomainError` subclass added inside the slice folder (N2, per
      `agent_docs/error_handling.md`).
- [ ] Adapter does not log exceptions (N2).

### Files and headers

- [ ] Every modified `.py` file retains `# FEATURE: delete_tier — <purpose>`
      on line 1 (N4).
- [ ] No STABLE files were modified — `bootstrap/container.py`,
      `bootstrap/router.py`, `.importlinter` are unchanged from slice 0037
      (plan.md § 1, STABLE files touched: none).
- [ ] `DeleteTierResponse` retains `model_config = ConfigDict(from_attributes=True)`
      (N3).

### DI

- [ ] No new providers were added to `Container` — existing
      `delete_tier_adapter` and `delete_tier_use_case` providers resolve
      correctly with the new `id`-based signatures.
- [ ] `Container.wiring_config.modules` is unchanged from slice 0037.

### Tests

- [ ] `tests/features/tiers/0037_delete_tier/delete_tier_outside_in_test.py`
      seeds via `RETURNING id` and calls `DELETE /api/v1/tier/{id}` (F1).
- [ ] `tests/features/tiers/0037_delete_tier/conftest.py` (if shared `_seed_tier`
      fixture exists) returns the seeded tier `id`, not the name.
- [ ] `tests/features/tiers/0037_delete_tier/domain/test_use_case.py` uses
      `DeleteTierCommand(id=1)` and asserts port calls with integer argument (F12).
- [ ] `tests/features/tiers/0037_delete_tier/data/test_adapter.py` seeds via
      `RETURNING id` and calls `adapter.get(tier_id)` / `adapter.delete(tier_id)`
      with the integer (F9, F10).
- [ ] `tests/features/tiers/0037_delete_tier/presentation/test_router.py` seeds
      via `RETURNING id` and calls `DELETE /api/v1/tier/{id}` (F1–F8).
- [ ] Outside-in test was RED before implementation change and is GREEN after.
- [ ] No test file references the old `{name}` path or `name=` argument pattern.

### Quality gates

Run from the `api/` project root:

```
ruff format src/app tests
ruff check src/app tests
mypy src/app
pytest
```

All must pass. The smoke test inside `pytest` (`tests/smoke/test_app_starts.py`)
boots the app in a subprocess and pings `/health`. If it fails, the slice is
**not done** — it usually indicates a broken relative import introduced during
the modification.
