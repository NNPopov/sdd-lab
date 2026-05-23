# 0036 · update_tier — Validation

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md
- Requirements: ./requirements.md

## Prerequisites

- App running locally: `uvicorn src.app.main:app --reload`.
- Test database seeded: at least one tier row (e.g. `name="silver"`) and one second tier row
  (`name="gold"`) for the duplicate scenario.
- A valid superuser Bearer token (`SUPERUSER_TOKEN`).
- A valid non-superuser Bearer token (`USER_TOKEN`).

Obtain tokens:

```bash
# Superuser
curl -s -X POST http://localhost:8000/api/v1/login \
  -d "username=admin&password=<admin_password>" | jq -r '.access_token'

# Regular user
curl -s -X POST http://localhost:8000/api/v1/login \
  -d "username=regular&password=<user_password>" | jq -r '.access_token'
```

---

## Manual scenarios

### S1 — Happy path: successful rename

**Steps:**

```bash
curl -s -X PATCH http://localhost:8000/api/v1/tier/silver \
  -H "Authorization: Bearer $SUPERUSER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"new_name": "platinum"}' | jq .
```

**Expected:**

- Status `200 OK`.
- Body: `{"message": "Tier updated"}`.
- Running `GET /api/v1/tier/platinum` returns the tier; `GET /api/v1/tier/silver` returns 404.

**Covers:** F1, F5, F8, F9.

---

### S2 — Not found: tier does not exist

**Steps:**

```bash
curl -s -X PATCH http://localhost:8000/api/v1/tier/nonexistent \
  -H "Authorization: Bearer $SUPERUSER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"new_name": "platinum"}' | jq .
```

**Expected:**

- Status `404 Not Found`.
- Body contains `"code": "notfound"` and `"message": "Tier not found"`.

**Covers:** F6, F7.

---

### S3 — Conflict: new name already taken

**Prerequisites:** Tiers `"silver"` and `"gold"` both exist.

**Steps:**

```bash
curl -s -X PATCH http://localhost:8000/api/v1/tier/silver \
  -H "Authorization: Bearer $SUPERUSER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"new_name": "gold"}' | jq .
```

**Expected:**

- Status `409 Conflict`.
- Body contains `"code": "duplicatevalue"` and `"message": "Tier name already exists"`.

**Covers:** F10, F11, F15.

---

### S4 — Forbidden: authenticated but not superuser

**Steps:**

```bash
curl -s -X PATCH http://localhost:8000/api/v1/tier/silver \
  -H "Authorization: Bearer $USER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"new_name": "platinum"}' | jq .
```

**Expected:**

- Status `403 Forbidden`.

**Covers:** F4.

---

### S5 — Unauthorized: no token

**Steps:**

```bash
curl -s -X PATCH http://localhost:8000/api/v1/tier/silver \
  -H "Content-Type: application/json" \
  -d '{"new_name": "platinum"}' | jq .
```

**Expected:**

- Status `401 Unauthorized`.

**Covers:** F3.

---

### S6 — Validation: missing `new_name` field

**Steps:**

```bash
curl -s -X PATCH http://localhost:8000/api/v1/tier/silver \
  -H "Authorization: Bearer $SUPERUSER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{}' | jq .
```

**Expected:**

- Status `422 Unprocessable Entity`.
- Body lists `new_name` as a missing/required field.

**Covers:** F2.

---

### S7 — Validation: empty string for `new_name`

**Steps:**

```bash
curl -s -X PATCH http://localhost:8000/api/v1/tier/silver \
  -H "Authorization: Bearer $SUPERUSER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"new_name": ""}' | jq .
```

**Expected:**

- Status `422 Unprocessable Entity`.
- Body lists `new_name` as failing the `min_length=1` constraint.

**Covers:** F2.

---

### S8 — DB side-effect: `updated_at` is set after rename

**Steps:**

1. Run S1 (rename `"silver"` → `"platinum"`).
2. Inspect the DB row directly:

```sql
SELECT name, updated_at FROM tier WHERE name = 'platinum';
```

**Expected:**

- `name = 'platinum'`.
- `updated_at` is a non-null timestamp matching the time of the PATCH request.

**Covers:** F14.

---

## Code review checklist

### Architecture

- [ ] Slice folder exists at `src/app/features/tiers/update_tier/` with `domain/`, `data/`,
      `presentation/` subfolders, each containing an `__init__.py`.
- [ ] `UpdateTierUseCase` is a class with `__init__(self, port: UpdateTierPort)` and a single
      public method `async def __call__(self, command: UpdateTierCommand) -> None`.
- [ ] `UpdateTierPort` is in `domain/ports/update_tier_port.py`, uses `@runtime_checkable`, and
      inherits from `typing.Protocol`.
- [ ] `class UpdateTierAdapter(UpdateTierPort):` — explicit inheritance from the port is present
      on the adapter class declaration (greppable, required by `agent_docs/architecture.md`).
- [ ] `UpdateTierAdapter` is the only place SQLAlchemy is used in this slice.
- [ ] Router converts path param + request body into `UpdateTierCommand`, calls the use-case,
      constructs and returns `UpdateTierResponse()`. No business logic in the router.
- [ ] No imports from another slice's `domain/`, `data/`, or `presentation/`. The shared
      `TierItem` is imported from `tiers/_shared/entities.py`.
- [ ] All imports inside `src/app/` are **relative** (`from ..domain...`, `from ...._shared...`).
      No `from app...` or `from src.app...` anywhere inside `src/app/`.
- [ ] No `HTTPException` is raised inside `UpdateTierUseCase`.
- [ ] No `try/except` block anywhere in `UpdateTierUseCase`.

### Error handling

- [ ] `UpdateTierAdapter.update()` catches only `IntegrityError` in a narrow `try/except` around
      `session.commit()`. No broader `except Exception` block exists.
- [ ] `UpdateTierAdapter.get()` has **no `try/except`** — read-only query, failures propagate.
- [ ] The `except IntegrityError` clause does not also catch `Exception` or any other type.
- [ ] `raise DuplicateValueDomainError("Tier name already exists") from exc` — `from exc` is
      present, preserving the original stack trace.
- [ ] The adapter does not log exceptions anywhere.
- [ ] No new `DomainError` subclass was added inside the slice folder — all domain errors live in
      `app/domain/errors.py`.
- [ ] `UnknownDomainError` is not used to wrap unknown infrastructure failures.

### Files and headers

- [ ] Every new `.py` file starts with `# FEATURE: update_tier — <purpose>` on line 1.
- [ ] No STABLE file was modified beyond the permitted additions:
      `bootstrap/container.py` (two new providers + one wiring entry),
      `.importlinter` (one `ignore_imports` line).
- [ ] `UpdateTierRequest` and `UpdateTierResponse` carry `model_config = ConfigDict(from_attributes=True)`.
- [ ] No `model.dict()` calls — only `model.model_dump()` if needed.

### DI

- [ ] `update_tier_adapter` (`providers.Factory(UpdateTierAdapter, session_factory=session_factory)`)
      is present in `bootstrap/container.py`.
- [ ] `update_tier_use_case` (`providers.Factory(UpdateTierUseCase, port=update_tier_adapter)`)
      is present in `bootstrap/container.py`.
- [ ] `f"{_app_pkg}.features.tiers.update_tier.presentation.router"` is added to
      `Container.wiring_config.modules`.
- [ ] Endpoint uses `Annotated[UpdateTierUseCase, Depends(Provide[Container.update_tier_use_case])]`
      and the function is decorated with `@inject`.
- [ ] `app.features.tiers.update_tier.presentation.router -> app.bootstrap.container` is present
      in the `ignore_imports` section of `.importlinter`.

### `tiers/router.py` migration

- [ ] The `patch_tier` fat handler and its `@router.patch` decorator are deleted.
- [ ] `from .update_tier.presentation.router import router as update_tier_router` is added.
- [ ] `router.include_router(update_tier_router)` is called.
- [ ] Imports unused after deleting `patch_tier` have been removed; imports still used by
      `erase_tier` have been preserved.

### Tests

- [ ] Use-case unit test exists at
      `tests/features/tiers/0036_update_tier/domain/test_use_case.py` and covers the three
      branches: not-found (F6), happy path (F8, F9), and duplicate propagation (F10).
- [ ] Adapter unit test exists at `tests/features/tiers/0036_update_tier/data/test_adapter.py`
      and covers: `get` happy path (F12), `get` not-found (F13), `update` happy path + DB
      assertion on `updated_at` (F14), `update` duplicate → `DuplicateValueDomainError` (F15),
      unknown exception propagation (F16).
- [ ] Endpoint integration test exists at
      `tests/features/tiers/0036_update_tier/presentation/test_router.py` and covers all six HTTP
      scenarios (F1–F4, F7, F11 — statuses 200/401/403/404/409/422).
- [ ] Outside-in test at
      `tests/features/tiers/0036_update_tier/update_tier_outside_in_test.py` is GREEN.
- [ ] Tests use `async_client` / savepoint rollback pattern from `conftest.py`; no test leaves
      rows in the DB after teardown.

### Quality gates

Run from the project root — all must pass before the slice is considered done:

```
ruff format src/app tests
ruff check src/app tests
mypy src/app
pytest
```

`pytest` includes `tests/smoke/test_app_starts.py`, which boots the app in a subprocess and pings
`/api/v1/health`. If the smoke test fails, the slice is **not done** even if every other test is
green — it typically indicates an accidental absolute import (`from app...`) inside `src/app/`
that works under pytest's `pythonpath` but breaks under uvicorn.
