# 0033 · create_tier — Validation

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md
- Requirements: ./requirements.md

## Prerequisites

- App running locally (`uvicorn src.app.main:app --reload` from the project root).
- Test Postgres running (`docker compose up test-db -d`).
- A superuser account seeded (`python -m scripts.create_first_superuser`).
- A regular (non-superuser) user account available for the 403 scenario.
- Two shell variables set before running the scenarios below:

```bash
SUPER_TOKEN=$(curl -s -X POST http://localhost:8000/api/v1/login \
  -d "username=<superuser_username>&password=<superuser_password>" \
  | jq -r '.access_token')

USER_TOKEN=$(curl -s -X POST http://localhost:8000/api/v1/login \
  -d "username=<regular_user>&password=<regular_password>" \
  | jq -r '.access_token')
```

## Manual scenarios

### S1 — Happy path: create a new tier

**Steps:**

```bash
curl -s -X POST http://localhost:8000/api/v1/tier \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $SUPER_TOKEN" \
  -d '{"name": "gold"}'
```

**Expected:**

- Status `201 Created`.
- Body is a JSON object with integer `id`, string `name` equal to `"gold"`, and
  string `created_at` (ISO-8601 timestamp with timezone).
- No `updated_at` field in the response (it is not part of `CreateTierResponse`).
- A `tier` row with `name = 'gold'` exists in the database.

**Covers:** F1, F8, F10.

---

### S2 — Duplicate name: second insert with the same name

**Steps:**

1. Run S1 to create tier `"gold"`.
2. Run the same request again:

```bash
curl -s -X POST http://localhost:8000/api/v1/tier \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $SUPER_TOKEN" \
  -d '{"name": "gold"}'
```

**Expected:**

- Status `409 Conflict`.
- Body: `{"message": "Tier name already exists"}`.
- Only one `tier` row with `name = 'gold'` exists in the database (the second
  insert did not succeed).

**Covers:** F5.

---

### S3 — Unauthenticated: no bearer token

**Steps:**

```bash
curl -s -X POST http://localhost:8000/api/v1/tier \
  -H "Content-Type: application/json" \
  -d '{"name": "silver"}'
```

**Expected:**

- Status `401 Unauthorized`.
- No tier row created.

**Covers:** F2.

---

### S4 — Forbidden: authenticated non-superuser

**Steps:**

```bash
curl -s -X POST http://localhost:8000/api/v1/tier \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $USER_TOKEN" \
  -d '{"name": "silver"}'
```

**Expected:**

- Status `403 Forbidden`.
- No tier row created.

**Covers:** F3.

---

### S5 — Validation failure: missing `name` field

**Steps:**

```bash
curl -s -X POST http://localhost:8000/api/v1/tier \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $SUPER_TOKEN" \
  -d '{}'
```

**Expected:**

- Status `422 Unprocessable Entity`.
- Body contains Pydantic validation errors referencing the `name` field.

**Covers:** F4.

---

### S6 — Validation failure: empty string name

**Steps:**

```bash
curl -s -X POST http://localhost:8000/api/v1/tier \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $SUPER_TOKEN" \
  -d '{"name": ""}'
```

**Expected:**

- Status `422 Unprocessable Entity`.
- Body references the `name` field violating `min_length=1`.

**Covers:** F4.

---

### S7 — Smoke: app starts and old handler is gone

**Steps:**

1. Start the app fresh and verify it boots without errors:

```bash
uvicorn src.app.main:app --port 8001 --log-level warning
# Should print "Application startup complete." with no import errors.
```

2. Confirm the old `write_tier` handler is absent (run `pytest tests/smoke/` separately
   to catch import-path issues).

3. Re-run S1 to confirm `POST /api/v1/tier` still responds correctly after the handler
   migration.

**Expected:**

- App starts cleanly.
- `POST /api/v1/tier` returns 201 (the new sub-router took over the route).

**Covers:** F8, F10 (DI wiring visible in app startup).

## Code review checklist

### Architecture

- [ ] Slice folder exists at `src/app/features/tiers/create_tier/` with
      `domain/`, `data/`, `presentation/` subfolders plus an `__init__.py` in
      each.
- [ ] `tiers/_shared/` folder exists with `__init__.py` and `entities.py`
      defining `TierItem` and `TierPage` as pure Pydantic models (no ORM, no
      framework imports).
- [ ] `CreateTierUseCase` is a class with `__call__(self, command: CreateTierCommand) -> TierItem`;
      called as `await use_case(command)`.
- [ ] `CreateTierPort` lives in `domain/ports/create_tier_port.py`, carries
      `@runtime_checkable`, and inherits from `typing.Protocol`.
- [ ] `CreateTierAdapter` class header is `class CreateTierAdapter(CreateTierPort):` —
      explicit inheritance from the port (mandatory for greppability).
- [ ] `CreateTierAdapter` is the only place `sqlalchemy.ext.asyncio` is used in
      this slice.
- [ ] Router accepts `CreateTierRequest`, converts to `CreateTierCommand`, awaits
      `use_case`, converts `TierItem` → `CreateTierResponse`.
- [ ] No cross-slice imports: nothing imported from another feature's `domain/`,
      `data/`, or `presentation/`. Only `tiers/_shared/` is imported from within
      the tiers feature.
- [ ] All imports inside `src/app/` are **relative** (`from ..domain...`,
      `from ...._shared...`). No `from app...` or `from src.app...` inside source.
- [ ] No `HTTPException` raised inside `CreateTierUseCase`.
- [ ] `CreateTierUseCase.__call__` has zero conditional branches — it calls
      `self._port.create(command)` and returns; no `if` statements (covers F6).

### Error handling

- [ ] `CreateTierAdapter.create()` has a narrow `try/except IntegrityError`
      around `session.commit()` only (not around the full method body).
- [ ] The `except IntegrityError` block raises `DuplicateValueDomainError("Tier name already exists") from exc`.
- [ ] No `except Exception` block in the adapter.
- [ ] No `try/except` in `CreateTierUseCase`.
- [ ] `raise DuplicateValueDomainError(...) from exc` preserves the original
      `IntegrityError` in the cause chain (the `from exc` part is present).
- [ ] Adapter does not call `logger.error` or any logging inside the `except` block.
- [ ] No new `DomainError` subclass was added inside the slice folder; only the
      existing `DuplicateValueDomainError` from `app/domain/errors.py` is used.

### INSERT-only (no SELECT EXISTS)

- [ ] `CreateTierAdapter.create()` contains only one database operation: the
      `session.add(tier)` + `session.commit()` sequence. There is no preceding
      `SELECT EXISTS` or `crud_tiers.exists()` call (covers F9).

### Files and headers

- [ ] `tiers/_shared/entities.py` starts with `# FEATURE: tiers._shared — domain entities.`
- [ ] Every new file in `create_tier/` starts with `# FEATURE: create_tier — <purpose>.`
- [ ] `bootstrap/container.py` is the only STABLE file modified; modifications are
      limited to: two new `providers.Factory` entries and one new
      `wiring_config.modules` entry.
- [ ] `TierItem`, `CreateTierRequest`, and `CreateTierResponse` all carry
      `model_config = ConfigDict(from_attributes=True)`.
- [ ] No `model.dict()` call anywhere in the slice; only `model.model_dump()`.

### Tiers router migration

- [ ] `features/tiers/router.py` includes the `create_tier` sub-router via
      `router.include_router(create_tier_router)`.
- [ ] The old `write_tier` function and its `@router.post("/tier", ...)` decorator
      are deleted from `features/tiers/router.py`.
- [ ] Remaining handlers (`read_tiers`, `read_tier`, `patch_tier`, `erase_tier`)
      are untouched.
- [ ] Any imports previously used only by `write_tier` (e.g. `TierCreate`,
      `TierCreateInternal`) are removed from `router.py` if no longer needed by
      the remaining handlers.

### DI wiring

- [ ] `create_tier_adapter = providers.Factory(CreateTierAdapter, session_factory=session_factory)`
      is present in `Container`.
- [ ] `create_tier_use_case = providers.Factory(CreateTierUseCase, port=create_tier_adapter)`
      is present in `Container`.
- [ ] `f"{_app_pkg}.features.tiers.create_tier.presentation.router"` is added to
      `Container.wiring_config.modules`.
- [ ] The endpoint uses `Annotated[CreateTierUseCase, Depends(Provide[Container.create_tier_use_case])]`
      with the `@inject` decorator.

### Import linter

- [ ] `.importlinter` has the line
      `app.features.tiers.create_tier.presentation.router -> app.bootstrap.container`
      in the `ignore_imports` section of the `VSA Feature Domains are Independent` contract.

### Tests

- [ ] Use-case unit test exists at
      `tests/features/tiers/0033_create_tier/domain/test_use_case.py` and passes.
- [ ] Adapter unit test exists at
      `tests/features/tiers/0033_create_tier/data/test_adapter.py`, covers the happy
      path, the duplicate-name `IntegrityError` → `DuplicateValueDomainError` mapping,
      and the propagation of an unexpected `OperationalError` (not caught by adapter).
- [ ] Endpoint integration test exists at
      `tests/features/tiers/0033_create_tier/presentation/test_router.py` and covers
      201, 409, 403, 401, and 422 status codes.
- [ ] Outside-in test exists at
      `tests/features/tiers/0033_create_tier/create_tier_outside_in_test.py` and is GREEN.
- [ ] No test calls `session.commit()` directly (rollback relies on the outer transaction).

### Quality gates

Run from the project root; all must pass before the slice is done:

```bash
ruff format src/app tests
ruff check src/app tests
mypy src/app
pytest                         # includes tests/smoke/test_app_starts.py
```

The smoke test boots the app in a subprocess. If it fails (import error, missing
wiring), the slice is **not done** even if every other test is green.
