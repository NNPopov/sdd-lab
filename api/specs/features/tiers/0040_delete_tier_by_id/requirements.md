# 0040 · delete_tier_by_id — Requirements

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md

## Functional requirements

- **F1.** `DELETE /api/v1/tier/{id}` accepts an integer path parameter `id` and returns
  `{"message": "Tier deleted"}` with HTTP 200 on success.
- **F2.** FastAPI returns HTTP 422 automatically when `{id}` is not a valid integer; the
  use-case is never invoked in that case.
- **F3.** The router constructs `DeleteTierCommand(id=id)` from the validated integer path
  parameter and passes it to `DeleteTierUseCase`.
- **F4.** The use-case calls `port.get(command.id)`; when the result is `None` it raises
  `NotFoundDomainError("Tier not found")` without calling `port.delete`.
- **F5.** The use-case calls `port.delete(command.id)` when `port.get(command.id)` returns
  a `TierItem`.
- **F6.** The endpoint returns HTTP 404 when `NotFoundDomainError` is raised by the use-case.
- **F7.** The endpoint returns HTTP 403 when the caller is authenticated but is not a
  superuser (`get_current_superuser` dependency raises `ForbiddenDomainError`).
- **F8.** The endpoint returns HTTP 401 when no valid bearer token is present.
- **F9.** `DeleteTierAdapter.get(tier_id: int)` executes
  `SELECT … WHERE Tier.id == tier_id` and returns a `TierItem` when a row is found, or
  `None` when no row matches.
- **F10.** `DeleteTierAdapter.delete(tier_id: int)` executes
  `DELETE … WHERE Tier.id == tier_id` and commits the transaction.
- **F11.** `DeleteTierPort` declares `get(self, tier_id: int) -> TierItem | None` and
  `delete(self, tier_id: int) -> None` as its two methods.
- **F12.** `DeleteTierCommand` has a single field `id: int`; no `name` field is present.

## Non-functional requirements

- **N1.** `DeleteTierUseCase` is a class with `__call__()`; invoked as
  `await use_case(command)`. Per `agent_docs/architecture.md` § Use-case shape.
- **N2.** `DeleteTierAdapter` contains no `try/except` — a DELETE statement cannot violate
  a unique constraint, so there is no business-meaningful infrastructure exception to
  translate. Unknown infrastructure exceptions propagate to the global handler.
  Per `agent_docs/error_handling.md` § Right shape: read-only query, no catch.
- **N3.** `DeleteTierResponse` uses `model_config = ConfigDict(from_attributes=True)`.
  Per `agent_docs/architecture.md` § Command vs Request, Entity vs Response.
- **N4.** All modified `.py` files retain a `# FEATURE: delete_tier — <purpose>` header
  on line 1. Per `agent_docs/stable_vs_feature.md`.
- **N5.** `DeleteTierUseCase` never raises `HTTPException`; it raises only
  `NotFoundDomainError`. Per CLAUDE.md § Universal hard rules, rule 1.
- **N6.** No imports cross slice boundaries outside `tiers/_shared/`.
  Per CLAUDE.md § Universal hard rules, rule 7.
- **N7.** All DB calls are `async def` + `await`; no synchronous SQLAlchemy calls.
  Per CLAUDE.md § Locked technology stack.
- **N8.** `mypy src/app` strict passes for all modified files.
  Per CLAUDE.md § Verifying changes.
- **N9.** `ruff format src/app` and `ruff check src/app` pass for all modified files.
  Per CLAUDE.md § Verifying changes.

## Out of scope

- Soft-deleting tiers.
- Cascading deletes to users assigned to the deleted tier.
- Changing the response body shape.
- Allowing non-superusers to delete tiers.
- URL normalisation from `/tier/{id}` (singular) to `/tiers/{id}` (plural).
- `IntegrityError` handling in the adapter.

## Traceability

| Requirement | Verified by |
|---|---|
| F1 | endpoint integration test; outside-in test |
| F2 | endpoint integration test (422 case) |
| F3 | endpoint integration test; use-case unit test (command shape) |
| F4 | use-case unit test (not-found branch) |
| F5 | use-case unit test (happy path) |
| F6 | endpoint integration test (404 case) |
| F7 | endpoint integration test (403 case) |
| F8 | endpoint integration test (401 case) |
| F9 | adapter unit test (get happy path; get not-found) |
| F10 | adapter unit test (delete happy path) |
| F11 | code review checklist in validation.md |
| F12 | use-case unit test (command construction); code review |
| N1–N9 | code review checklist in validation.md |
