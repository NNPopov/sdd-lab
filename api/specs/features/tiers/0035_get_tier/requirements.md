# 0035 · get_tier — Requirements

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md

## Functional requirements

- **F1.** The endpoint `GET /api/v1/tier/{name}` accepts a path parameter `name: str` and returns
  `GetTierResponse` with HTTP 200 when a tier with that name exists in the database.
- **F2.** `GetTierResponse` contains exactly three fields: `id: int`, `name: str`, and
  `created_at: datetime`, sourced from the matched tier row.
- **F3.** The endpoint returns HTTP 404 with body `{"message": "Tier not found"}` when no tier
  with the given name exists.
- **F4.** The endpoint requires no authentication; unauthenticated requests are served without
  error (no 401 or 403 is raised by this slice).
- **F5.** `GetTierUseCase.__call__(query: GetTierQuery) -> TierItem` calls `port.get(query)` and
  returns the `TierItem` unchanged when the port returns a non-`None` value.
- **F6.** `GetTierUseCase` raises `NotFoundDomainError("Tier not found")` when `port.get(query)`
  returns `None`.
- **F7.** `GetTierAdapter.get(query: GetTierQuery)` executes a `SELECT` on the `Tier` table
  filtered by `Tier.name == query.name` and returns a `TierItem` mapped via
  `TierItem.model_validate(row)` when a matching row is found.
- **F8.** `GetTierAdapter.get(query: GetTierQuery)` returns `None` when no row with the given name
  exists in the database.
- **F9.** `TierItem` is imported from `features/tiers/_shared/entities.py`; this slice does not
  define a local copy.
- **F10.** The `read_tier` handler is removed from `features/tiers/router.py` and replaced by
  `router.include_router(get_tier_router)` so exactly one implementation of this endpoint exists
  at runtime.

## Non-functional requirements

- **N1.** `GetTierUseCase` is a class with `__call__()`; called as `await use_case(query)`. Per
  `agent_docs/architecture.md` § Use-case shape.
- **N2.** `GetTierAdapter` catches no exceptions — a read-only `SELECT` has no business-meaningful
  infrastructure exception to translate; infrastructure failures propagate to the global `_catch_all`
  handler. Per `agent_docs/error_handling.md` § Right shape: read-only query, no catch.
- **N3.** `GetTierResponse` uses `model_config = ConfigDict(from_attributes=True)`. Per CLAUDE.md
  (Validation: Pydantic v2).
- **N4.** Every new `.py` file in this slice starts with `# FEATURE: get_tier — <purpose>` on
  line 1. Per `agent_docs/stable_vs_feature.md`.
- **N5.** No `HTTPException` is raised inside `GetTierUseCase`. Per CLAUDE.md universal hard rules.
- **N6.** No cross-slice imports; `TierItem` is sourced from the feature's own `_shared/` folder,
  not from another slice's `domain/` or `data/`. Per CLAUDE.md universal hard rules.
- **N7.** All database I/O is `async def` + `await`; no synchronous DB calls. Per CLAUDE.md.
- **N8.** mypy strict passes for all new code in `src/app/`.
- **N9.** Ruff format and ruff lint pass for all new code in `src/app/`.
- **N10.** `GetTierAdapter` explicitly inherits from `GetTierPort` (`class GetTierAdapter(GetTierPort):`).
  Per `agent_docs/architecture.md` § Terminology: port and adapter.
- **N11.** `GetTierPort` carries the `@runtime_checkable` decorator. Per CLAUDE.md (Forbidden
  without explicit user approval: Port without `@runtime_checkable`) and `agent_docs/architecture.md`.
- **N12.** Inside `src/app/`, all imports are relative; inside `tests/`, all imports are absolute
  through `app.*`. Per `agent_docs/architecture.md` § Import conventions.

## Out of scope

- Migrating `patch_tier` or `erase_tier` (slices 0036, 0037).
- Lookup by `id` — only name-based lookup is implemented.
- Caching — not present on the current endpoint; not added here.
- Returning soft-deleted tiers — the `Tier` ORM model has no soft-delete field.
- Removing `tiers/schemas.py` or `tiers/repository.py` — still referenced by other features.
- URL normalisation from `/tier/{name}` (singular) to `/tiers/{name}` (plural).

## Traceability

| Requirement | Verified by |
|---|---|
| F1, F4 | endpoint integration test (happy path; unauthenticated 200) |
| F2 | endpoint integration test (response body field assertions) |
| F3 | endpoint integration test (not-found path → 404) |
| F5 | use-case unit test (happy path: port returns `TierItem`) |
| F6 | use-case unit test (not-found path: port returns `None` → `NotFoundDomainError`) |
| F7 | adapter unit test (happy path: seeded row → `TierItem` returned) |
| F8 | adapter unit test (not-found path: absent name → `None` returned) |
| F9 | code review |
| F10 | code review; smoke test (`tests/smoke/test_app_starts.py` catches import failures) |
| F1 (happy path) | outside-in test |
| N1–N12 | code review checklist in `validation.md` |
