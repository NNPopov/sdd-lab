# 0037 · delete_tier — Validation

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md
- Requirements: ./requirements.md

## Prerequisites

- App running locally (`uvicorn src.app.main:app --reload` from project root).
- Test Postgres running (`docker compose up test-db -d`).
- A superuser account exists (run `python -m scripts.create_first_superuser`).
- A regular (non-superuser) account exists for the 403 scenario.
- Shell variable `$TOKEN` holds a valid superuser bearer token obtained via:
  ```
  curl -s -X POST http://localhost:8000/api/v1/auth/login \
    -d "username=<superuser>&password=<password>" | jq -r .access_token
  ```
- Shell variable `$USER_TOKEN` holds a valid non-superuser bearer token obtained the same way.

## Manual scenarios

### S1 — Happy path: existing tier is permanently deleted

**Steps:**

1. Seed a tier named `"silver"`:
   ```
   curl -s -X POST http://localhost:8000/api/v1/tier \
     -H "Authorization: Bearer $TOKEN" \
     -H "Content-Type: application/json" \
     -d '{"name": "silver"}'
   ```
2. Delete the tier:
   ```
   curl -s -X DELETE http://localhost:8000/api/v1/tier/silver \
     -H "Authorization: Bearer $TOKEN"
   ```

**Expected:**

- Status `200 OK`.
- Body: `{"message": "Tier deleted"}`.
- A follow-up `GET /api/v1/tier/silver` returns `404`.

**Covers:** F1, F3, F7, F8.

---

### S2 — Not-found: tier name does not exist

**Steps:**

1. Attempt to delete a tier that has never been created:
   ```
   curl -s -X DELETE http://localhost:8000/api/v1/tier/nonexistent \
     -H "Authorization: Bearer $TOKEN"
   ```

**Expected:**

- Status `404 Not Found`.
- Body:
  ```json
  {"error": {"code": "notfound", "message": "Tier not found"}}
  ```

**Covers:** F2, F4.

---

### S3 — Forbidden: authenticated but not a superuser

**Steps:**

1. Seed a tier `"bronze"` as superuser (S1 step 1 with name `"bronze"`).
2. Attempt to delete as a regular user:
   ```
   curl -s -X DELETE http://localhost:8000/api/v1/tier/bronze \
     -H "Authorization: Bearer $USER_TOKEN"
   ```

**Expected:**

- Status `403 Forbidden`.
- Tier `"bronze"` still exists (verify with `GET /api/v1/tier/bronze` → 200).

**Covers:** F5.

---

### S4 — Unauthorized: no bearer token

**Steps:**

1. Call the endpoint without any `Authorization` header:
   ```
   curl -s -X DELETE http://localhost:8000/api/v1/tier/silver
   ```

**Expected:**

- Status `401 Unauthorized`.

**Covers:** F6.

---

### S5 — Idempotent at SQL level: delete non-existent row via adapter

> This scenario verifies adapter behaviour at the SQL level only; it cannot be
> exercised through the HTTP API because the use-case blocks the adapter call
> when the tier is not found. It is documented for completeness and verified
> by the adapter unit test.

**Not a curl scenario.** Covered by the adapter unit test (`delete` no-op case, requirement F8).

---

### S6 — Regression: `tiers/router.py` is a pure aggregator after the slice lands

**Steps:**

1. After deploying the slice, inspect `src/app/features/tiers/router.py`.

**Expected:**

- File contains only `include_router` calls (five total, one per tiers slice).
- No `async def erase_tier` function.
- No FastCRUD imports (`crud_tiers`, `TierCreate`, etc.).
- No `AsyncSession` or `async_get_db` imports.

**Covers:** F11, F12.

---

## Code review checklist

### Architecture

- [ ] Slice folder exists at `src/app/features/tiers/delete_tier/` with
      `domain/`, `data/`, `presentation/` subfolders, each with an `__init__.py`.
- [ ] `DeleteTierUseCase` is a class with `async def __call__(self, command: DeleteTierCommand) -> None`.
- [ ] `DeleteTierPort` lives in `domain/ports/delete_tier_port.py`, is decorated
      with `@runtime_checkable`, and inherits from `typing.Protocol`.
- [ ] `DeleteTierAdapter` class signature is `class DeleteTierAdapter(DeleteTierPort):` —
      explicit port inheritance is mandatory (per `agent_docs/architecture.md` § Adapter pattern).
- [ ] `DeleteTierAdapter` is the only file in this slice that imports SQLAlchemy.
- [ ] Router accepts `name: str` path param, builds `DeleteTierCommand(name=name)`,
      awaits the use-case, returns `DeleteTierResponse()`.
- [ ] No cross-slice imports outside `tiers/_shared/`; `TierItem` is imported from
      `tiers/_shared/entities.py`, not redefined.
- [ ] All imports inside `src/app/features/tiers/delete_tier/` are **relative**
      (no `from app...` or `from src.app...` anywhere in source).
- [ ] `DeleteTierUseCase.__call__` never raises `HTTPException`.

### Error handling

- [ ] `DeleteTierUseCase` raises `NotFoundDomainError("Tier not found")` when
      `port.get(name)` returns `None` and does not call `port.delete` in that path.
- [ ] `DeleteTierAdapter.get` has **no `try/except`** — read-only query, nothing
      business-meaningful to translate (per `agent_docs/error_handling.md` § Right shape:
      read-only query, no catch).
- [ ] `DeleteTierAdapter.delete` has **no `try/except`** — a DELETE statement cannot
      violate a unique constraint; unknown exceptions propagate to the global handler
      (per PRD § No IntegrityError handling and `agent_docs/error_handling.md`).
- [ ] No new `DomainError` subclass was introduced in any file under the slice folder.
      All domain errors live in `app/domain/errors.py`.
- [ ] Adapter does not log exceptions.

### Files and headers

- [ ] Every new `.py` file in the slice starts with `# FEATURE: delete_tier — <purpose>`
      on line 1 (per `agent_docs/stable_vs_feature.md`).
- [ ] No STABLE file was modified beyond:
      - `bootstrap/container.py` (two new providers + wiring entry).
      - `.importlinter` (one `ignore_imports` line).
      - `features/tiers/router.py` (remove `erase_tier`, add `include_router`).
- [ ] `DeleteTierResponse` uses `model_config = ConfigDict(from_attributes=True)`.
- [ ] No `model.dict()` usage — only `model.model_dump()`.

### DI

- [ ] `delete_tier_adapter` provider (Factory) added to `bootstrap/container.py`,
      receives `session_factory`.
- [ ] `delete_tier_use_case` provider (Factory) added, receives `delete_tier_adapter`.
- [ ] `f"{_app_pkg}.features.tiers.delete_tier.presentation.router"` added to
      `Container.wiring_config.modules`.
- [ ] Endpoint uses `Annotated[DeleteTierUseCase, Depends(Provide[Container.delete_tier_use_case])]`
      and is decorated with `@inject`.
- [ ] `app.features.tiers.delete_tier.presentation.router -> app.bootstrap.container`
      added to `.importlinter` `ignore_imports`.

### Router cleanup

- [ ] `erase_tier` handler is fully removed from `features/tiers/router.py`.
- [ ] All imports that were only used by `erase_tier` are removed.
- [ ] `features/tiers/router.py` now contains only five `include_router` calls.

### Tests

- [ ] Use-case unit test exists at
      `tests/features/tiers/0037_delete_tier/domain/test_use_case.py` and covers
      both the not-found path and the happy path.
- [ ] Adapter unit test exists at
      `tests/features/tiers/0037_delete_tier/data/test_adapter.py` and covers
      `get` happy path, `get` not-found, `delete` happy path, and `delete` no-op.
- [ ] Endpoint integration test exists at
      `tests/features/tiers/0037_delete_tier/presentation/test_router.py` and covers
      200, 404, 403, and 401 status codes.
- [ ] Outside-in test exists at
      `tests/features/tiers/0037_delete_tier/delete_tier_outside_in_test.py`,
      seeds a tier, deletes it, and asserts the row is gone from the DB.
- [ ] Outside-in test is GREEN.
- [ ] `conftest.py` uses the savepoint rollback pattern from `agent_docs/testing.md`
      and includes both `container.session_factory.override(...)` and
      `app.dependency_overrides[async_get_db] = _test_get_db` (migration slice).

### Quality gates

Run from project root — all must pass:

```
ruff format src/app tests
ruff check src/app tests
mypy src/app
pytest
```

The `pytest` run includes `tests/smoke/test_app_starts.py`. If the smoke test
fails, the slice is **not done** — even if every other test is green. A failing
smoke test almost always means an `from app...` absolute import slipped into
`src/app/` source code, which works under pytest but breaks under uvicorn.
