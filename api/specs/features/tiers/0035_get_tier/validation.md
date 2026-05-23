# 0035 · get_tier — Validation

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md
- Requirements: ./requirements.md

## Prerequisites

- App running locally (`uvicorn src.app.main:app --reload` from the project root).
- Test Postgres running (`docker compose up test-db -d`).
- At least one tier row seeded in the database (e.g. via `POST /api/v1/tier` if slice 0033 is
  implemented, or directly with `INSERT INTO tier (name) VALUES ('gold');`).

No bearer token required — this endpoint is public.

## Manual scenarios

### S1 — Happy path: existing tier returns 200 with all fields

**Steps:**

1. Ensure a tier named `gold` exists in the database.
2. ```
   curl -s http://localhost:8000/api/v1/tier/gold | python -m json.tool
   ```

**Expected:**

- HTTP 200.
- Response body contains exactly `id` (integer), `name` (`"gold"`), and `created_at` (ISO 8601
  datetime string). No extra fields.

**Covers:** F1, F2, F3.

---

### S2 — Not found: unknown name returns 404

**Steps:**

1. ```
   curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/api/v1/tier/nonexistent_tier_xyz
   ```

**Expected:**

- HTTP 404.
- Response body: `{"message": "Tier not found"}`.

**Covers:** F3.

---

### S3 — No authentication required

**Steps:**

1. Ensure a tier named `gold` exists.
2. Call without any `Authorization` header:
   ```
   curl -s http://localhost:8000/api/v1/tier/gold
   ```

**Expected:**

- HTTP 200 (not 401 or 403).
- Same response body as S1.

**Covers:** F4.

---

### S4 — Old `read_tier` handler is gone (no duplicate)

**Steps:**

1. Inspect `src/app/features/tiers/router.py` to confirm the `read_tier` function has been
   deleted.
2. Confirm `router.include_router(get_tier_router)` is present in that file.
3. Restart the app and call `GET /api/v1/tier/gold`; confirm only one handler responds (no
   duplicate route warning in the startup log).

**Expected:**

- No `read_tier` function or its decorator exists in `tiers/router.py`.
- App starts cleanly (no route conflict warnings).
- The endpoint still responds correctly (HTTP 200 for an existing tier).

**Covers:** F10.

---

### S5 — TierItem sourced from `_shared/entities.py`

**Steps:**

1. Search the `get_tier` slice for any local definition of a `TierItem` class:
   ```
   grep -r "class TierItem" src/app/features/tiers/get_tier/
   ```
2. Confirm zero results.
3. Confirm `TierItem` is imported from `..._shared.entities` (or equivalent relative path) in
   `data/adapter.py` and `domain/ports/get_tier_port.py`.

**Expected:**

- No local `TierItem` definition in the `get_tier` slice.
- The import points to `tiers/_shared/entities.py`.

**Covers:** F9.

---

### S6 — Infrastructure failure returns 500, not a domain error

*(Manual only — requires deliberate DB disruption; document rather than reproduce in every review.)*

**Steps:**

1. Stop the test-db container while the app is running.
2. Call `GET /api/v1/tier/gold`.

**Expected:**

- HTTP 500 with `{"message": "Internal error"}`.
- Error is logged once by the global `_catch_all` handler.
- No custom domain-error wrapping (no "Tier not found" on a DB outage).

**Covers:** N2 (adapter does not catch infrastructure failures).

---

## Code review checklist

### Architecture

- [ ] Slice folder exists at `src/app/features/tiers/get_tier/` with `domain/`, `data/`,
      `presentation/` subfolders.
- [ ] `GetTierUseCase` is a class with `__call__(query: GetTierQuery) -> TierItem`; no other
      public methods.
- [ ] `GetTierPort` lives in `domain/ports/get_tier_port.py`, decorated with
      `@runtime_checkable`, inherits from `typing.Protocol`, declares exactly one method
      (`get`).
- [ ] `GetTierAdapter` class signature is `class GetTierAdapter(GetTierPort):` — explicit
      inheritance from the port is mandatory (greppability + reader intent). Per
      `agent_docs/architecture.md` § Terminology: port and adapter.
- [ ] `GetTierAdapter` is the only place SQLAlchemy is used in this slice.
- [ ] Router accepts the `name: str` path parameter, converts it to `GetTierQuery`, awaits the
      use-case, converts the returned `TierItem` to `GetTierResponse`.
- [ ] No cross-slice imports — `TierItem` is sourced from `tiers/_shared/entities.py`, not
      from another slice's `domain/` or `presentation/`.
- [ ] All imports inside `src/app/` are **relative** (`from ..domain...`, `from ..._shared...`,
      etc.). No `from app...` or `from src.app...` anywhere inside source files.
- [ ] No `HTTPException` raised inside `GetTierUseCase`.
- [ ] No `try/except` inside `GetTierUseCase`.

### Error handling

- [ ] `GetTierAdapter.get()` has **no `try/except` block** — read-only query, no
      business-meaningful infrastructure exception to translate. Per
      `agent_docs/error_handling.md` § Right shape: read-only query, no catch.
- [ ] `GetTierUseCase` raises `NotFoundDomainError("Tier not found")` when `port.get()` returns
      `None`. This is the only error path.
- [ ] No new `DomainError` subclass was introduced inside the slice folder. `NotFoundDomainError`
      is already defined in `app/domain/errors.py` (STABLE).
- [ ] No `UnknownDomainError` or similar catch-all domain error is introduced.
- [ ] `GetTierAdapter` does not log exceptions.

### Files and headers

- [ ] Every new `.py` file in the `get_tier/` slice starts with
      `# FEATURE: get_tier — <purpose>` on line 1.
- [ ] No STABLE file was modified beyond `bootstrap/container.py` (two new providers, one wiring
      entry) and `features/tiers/router.py` (FEATURE file — deletion of `read_tier`, inclusion of
      `get_tier_router`).
- [ ] `GetTierResponse` uses `model_config = ConfigDict(from_attributes=True)`.
- [ ] No `model.dict()` — only `model.model_dump()` if used anywhere.

### DI

- [ ] `get_tier_adapter` provider added to `Container` as `providers.Factory(GetTierAdapter,
      session_factory=session_factory)`.
- [ ] `get_tier_use_case` provider added to `Container` as `providers.Factory(GetTierUseCase,
      port=get_tier_adapter)`.
- [ ] Router module path `...features.tiers.get_tier.presentation.router` added to
      `Container.wiring_config.modules`.
- [ ] Endpoint uses `Annotated[GetTierUseCase, Depends(Provide[Container.get_tier_use_case])]`.
- [ ] Endpoint function is decorated with `@inject`.

### Tests

- [ ] Use-case unit test exists at
      `tests/features/tiers/0035_get_tier/domain/test_use_case.py` and covers both branches
      (port returns `TierItem` → returned unchanged; port returns `None` → `NotFoundDomainError`).
- [ ] Adapter unit test exists at `tests/features/tiers/0035_get_tier/data/test_adapter.py`
      and covers both paths (seeded row → `TierItem` returned; absent name → `None` returned).
- [ ] Endpoint integration test exists at
      `tests/features/tiers/0035_get_tier/presentation/test_router.py` and covers: 200 happy
      path, 404 not-found, unauthenticated request succeeds.
- [ ] Outside-in test exists at
      `tests/features/tiers/0035_get_tier/get_tier_outside_in_test.py` and is **GREEN**.
- [ ] No test calls `session.commit()` when using the `db_session` fixture.
- [ ] No test constructs `AsyncClient` without the `app` fixture.

### Quality gates

Run from project root before approving the PR:

```
ruff format src/app tests
ruff check src/app tests
mypy src/app
pytest
```

All must pass, including `tests/smoke/test_app_starts.py` (boots the app in a subprocess and
pings `/api/v1/health`). If the smoke test fails, the slice is **not done** — usually indicates
an accidental absolute `from app...` import inside `src/app/` that works under pytest but breaks
under uvicorn.
