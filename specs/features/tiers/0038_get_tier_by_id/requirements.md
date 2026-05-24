# 0038 · get_tier_by_id — Requirements

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md

## Functional requirements

- **F1.** `GET /api/v1/tier/{tier_id}` returns HTTP 200 with a JSON body containing `id`
  (integer), `name` (string), and `created_at` (datetime) when a tier with the given integer
  id exists in the database.
- **F2.** `GET /api/v1/tier/{tier_id}` returns HTTP 404 with body
  `{"error": {"code": "notfound", "message": "Tier not found"}}` when no tier with the given
  id exists.
- **F3.** `GET /api/v1/tier/{tier_id}` returns HTTP 422 when `tier_id` is not a valid
  integer; FastAPI validates the path parameter automatically before the use-case is invoked.
- **F4.** The endpoint is publicly accessible without authentication; an unauthenticated
  request to an existing tier returns HTTP 200.
- **F5.** `GetTierUseCase.__call__` returns the `TierItem` from the port unchanged when
  `GetTierPort.get` returns a non-`None` result.
- **F6.** `GetTierUseCase.__call__` raises `NotFoundDomainError("Tier not found")` when
  `GetTierPort.get` returns `None`.
- **F7.** `GetTierAdapter.get` returns a `TierItem` mapped from the ORM row via
  `TierItem.model_validate(row)` when a row with `Tier.id == query.id` exists.
- **F8.** `GetTierAdapter.get` returns `None` when no row with `Tier.id == query.id` exists.

## Non-functional requirements

- **N1.** `GetTierUseCase` is a class with `__call__(query: GetTierQuery) -> TierItem`;
  called as `await use_case(query)`. Per `agent_docs/architecture.md` § Use-case shape.
- **N2.** `GetTierAdapter.get` has no `try/except`; infrastructure exceptions propagate
  unchanged to the global handler. Per `agent_docs/error_handling.md` § Right shape:
  read-only query, no catch.
- **N3.** `GetTierResponse` declares `model_config = ConfigDict(from_attributes=True)` to
  support `model_validate` from a `TierItem`. Per `agent_docs/entry_points/fastapi.md`.
- **N4.** Modified files retain the `# FEATURE: get_tier — <purpose>` header on line 1.
  Per `agent_docs/stable_vs_feature.md`.
- **N5.** No `HTTPException` is raised inside `GetTierUseCase`. Per CLAUDE.md rule 1.
- **N6.** No cross-slice imports outside `features/tiers/_shared/`. Per CLAUDE.md rule 7.
- **N7.** No synchronous DB calls; `GetTierAdapter.get` is `async def` using
  `await session.execute(...)`. Per CLAUDE.md locked technology stack.
- **N8.** `mypy src/app` (strict) passes for all modified files.
- **N9.** `ruff format` and `ruff check` pass for all modified files.
- **N10.** `GetTierAdapter` explicitly inherits from `GetTierPort` (`class GetTierAdapter(GetTierPort):`).
  Per `agent_docs/architecture.md` § Terminology: port and adapter.
- **N11.** `GetTierPort` retains the `@runtime_checkable` decorator. Per `agent_docs/architecture.md`
  § Port pattern (canonical).

## Out of scope

- Adding authentication to the endpoint.
- Changing the `GetTierResponse` schema.
- Caching.
- URL normalisation from `/tier/{id}` (singular) to `/tiers/{id}` (plural).
- Any change to `update_tier` (0036) or `delete_tier` (0037).
- Lookup by name — the name-based endpoint is replaced by this slice.

## Traceability

| Requirement | Verified by |
|---|---|
| F1 | endpoint integration test (`test_router.py`), outside-in test |
| F2 | endpoint integration test (`test_router.py`), outside-in test |
| F3 | endpoint integration test (`test_router.py`) |
| F4 | endpoint integration test (`test_router.py`) |
| F5 | use-case unit test (`test_use_case.py`) |
| F6 | use-case unit test (`test_use_case.py`) |
| F7 | adapter unit test (`test_adapter.py`) |
| F8 | adapter unit test (`test_adapter.py`) |
| N1 | code review checklist in `validation.md` |
| N2 | adapter unit test (infrastructure exception propagates unchanged), code review |
| N3 | code review checklist in `validation.md` |
| N4 | code review checklist in `validation.md` |
| N5 | code review checklist in `validation.md` |
| N6 | code review checklist in `validation.md` |
| N7 | code review checklist in `validation.md` |
| N8 | `mypy src/app` step in verification |
| N9 | `ruff format` / `ruff check` step in verification |
| N10 | adapter unit test (`isinstance(adapter, GetTierPort)` assertion), code review |
| N11 | code review checklist in `validation.md` |
