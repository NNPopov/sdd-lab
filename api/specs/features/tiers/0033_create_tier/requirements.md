# 0033 · create_tier — Requirements

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md

## Functional requirements

- **F1.** `POST /api/v1/tier` accepts `CreateTierRequest` with field `name: str` (min_length=1) and returns `CreateTierResponse` (fields: `id: int`, `name: str`, `created_at: datetime`) with HTTP 201 on success.
- **F2.** The endpoint rejects unauthenticated requests with HTTP 401, enforced by `get_current_superuser` (via its inner call to `get_current_user`) from `shared_dependencies.py`.
- **F3.** The endpoint rejects authenticated non-superuser callers with HTTP 403, enforced by `get_current_superuser` from `shared_dependencies.py`.
- **F4.** The endpoint rejects a request body missing the `name` field or violating `min_length=1` with HTTP 422 (Pydantic field validation).
- **F5.** The adapter maps `sqlalchemy.exc.IntegrityError` caused by the unique constraint on `name` to `DuplicateValueDomainError("Tier name already exists")`; the global exception handler returns this as HTTP 409.
- **F6.** The use-case `CreateTierUseCase.__call__` contains no conditional logic; it calls `self._port.create(command)` exactly once and returns the result, delegating all duplicate-detection to the adapter.
- **F7.** `features/tiers/_shared/entities.py` defines `TierItem(id: int, name: str, created_at: datetime)` and `TierPage(items: list[TierItem], total_count: int, page: int, items_per_page: int)` as pure Pydantic models with no ORM or framework imports.
- **F8.** After the slice is wired, `POST /api/v1/tier` remains accessible at the same URL; the old `write_tier` handler is deleted from `features/tiers/router.py` and the `create_tier` sub-router is included in its place.
- **F9.** The adapter issues a direct `INSERT` with no preceding `SELECT EXISTS`; the database unique constraint on `name` is the sole mechanism for detecting duplicates, eliminating the TOCTOU race in the previous implementation.
- **F10.** `CreateTierUseCase` is resolved from the DI container via `Provide[Container.create_tier_use_case]` at the endpoint; the router module `app.features.tiers.create_tier.presentation.router` is listed in `Container.wiring_config.modules`.

## Non-functional requirements

- **N1.** `CreateTierUseCase` is a class with a single public method `__call__(self, command: CreateTierCommand) -> TierItem`; called as `await use_case(command)`. Per `agent_docs/architecture.md`.
- **N2.** `CreateTierAdapter` catches only `IntegrityError` (business-meaningful); all other infrastructure exceptions propagate unchanged to the global exception handler. The adapter does not log. Per `agent_docs/error_handling.md`.
- **N3.** `TierItem`, `CreateTierRequest`, and `CreateTierResponse` carry `model_config = ConfigDict(from_attributes=True)` to support `.model_validate(orm_instance)`. Per `agent_docs/entry_points/fastapi.md`.
- **N4.** Every new `.py` file starts with `# FEATURE: create_tier — <purpose>` on line 1 (or `# FEATURE: tiers._shared — <purpose>` for `_shared/entities.py`). Per `agent_docs/stable_vs_feature.md`.
- **N5.** No `HTTPException` is raised inside `CreateTierUseCase` or `CreateTierAdapter`. Per CLAUDE.md hard rule 1.
- **N6.** No cross-slice imports; the only `_shared/` import allowed is from `features/tiers/_shared/`. Per CLAUDE.md hard rule 7.
- **N7.** All database operations use `async def` + `await`; no synchronous DB calls. Per CLAUDE.md locked stack.
- **N8.** `mypy src/app` (strict) passes for all new code. Per CLAUDE.md verifying-changes procedure.
- **N9.** `ruff format src/app` and `ruff check src/app` pass for all new code. Per CLAUDE.md verifying-changes procedure.
- **N10.** `CreateTierAdapter` explicitly inherits from `CreateTierPort` in its class header (`class CreateTierAdapter(CreateTierPort):`). Per CLAUDE.md forbidden list and `agent_docs/architecture.md`.
- **N11.** `CreateTierPort` carries the `@runtime_checkable` decorator. Per CLAUDE.md forbidden list and `agent_docs/architecture.md`.

## Out of scope

- Migrating `read_tiers`, `read_tier`, `patch_tier`, or `erase_tier` to the vertical slice pattern (slices 0034–0037).
- URL normalisation from `/tier` (singular) to `/tiers` (plural).
- Removing `tiers/schemas.py` or `tiers/repository.py` (still referenced by `rate_limits/` and `users/`).
- Converting `get_current_superuser` 403/401 responses from FastCRUD exceptions to `DomainError` subclasses (pre-existing pattern).
- Cache invalidation (tier creation has no associated cached read).
- Changes to the `Tier` ORM model or Alembic migrations.

## Traceability

| Requirement | Verified by |
|---|---|
| F1 (happy path, response shape) | endpoint integration test; outside-in test |
| F2 (HTTP 401) | endpoint integration test |
| F3 (HTTP 403) | endpoint integration test |
| F4 (HTTP 422) | endpoint integration test |
| F5 (HTTP 409, duplicate) | adapter unit test; endpoint integration test |
| F6 (use-case delegates only) | use-case unit test |
| F7 (shared entities importable, correct fields) | adapter unit test (uses `TierItem`); any test importing `_shared.entities` |
| F8 (old handler gone, URL still works) | endpoint integration test; smoke test |
| F9 (no SELECT EXISTS, INSERT-only) | adapter unit test (verify single DB round-trip via concurrent insert test) |
| F10 (DI wiring) | smoke test (`test_app_starts.py`); endpoint integration test |
| N1–N11 | code review checklist in `validation.md` |
