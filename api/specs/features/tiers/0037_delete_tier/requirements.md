# 0037 · delete_tier — Requirements

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md

## Functional requirements

- **F1.** The endpoint `DELETE /api/v1/tier/{name}` accepts no request body,
  requires a valid superuser bearer token, and returns `{"message": "Tier deleted"}`
  with HTTP 200 when the tier exists.
- **F2.** The use-case raises `NotFoundDomainError("Tier not found")` when
  `port.get(name)` returns `None`, and `port.delete` is never called in that case.
- **F3.** The use-case calls `port.delete(name)` and returns `None` when
  `port.get(name)` returns a `TierItem`.
- **F4.** The endpoint returns HTTP 404 with error body
  `{"error": {"code": "notfound", "message": "Tier not found"}}` when the tier
  does not exist.
- **F5.** The endpoint returns HTTP 403 when the caller is authenticated but is
  not a superuser.
- **F6.** The endpoint returns HTTP 401 when no valid bearer token is supplied.
- **F7.** The adapter `get(name)` executes a `SELECT` on the `tier` table filtered
  by `name` and returns a `TierItem` if the row exists, or `None` if it does not.
- **F8.** The adapter `delete(name)` executes a `DELETE FROM tier WHERE name = :name`
  and commits; it does not raise on zero rows matched.
- **F9.** The adapter wraps no infrastructure exceptions in `delete` — a DELETE
  statement cannot violate a unique constraint, so no `IntegrityError` catch is
  present.
- **F10.** The router builds `DeleteTierCommand(name=name)` from the path parameter,
  awaits the use-case, and returns `DeleteTierResponse()` without any conditional
  logic.
- **F11.** The old `erase_tier` handler is removed from `features/tiers/router.py`
  and replaced by `include_router(delete_tier_router)`.
- **F12.** After this slice, `features/tiers/router.py` contains only
  `include_router` calls and their sub-router imports — no direct DB access, no
  FastCRUD usage, no session injection.

## Non-functional requirements

- **N1.** `DeleteTierUseCase` is a class with `__call__(command: DeleteTierCommand) -> None`;
  called as `await use_case(command)`. Per `agent_docs/architecture.md` § Use-case shape.
- **N2.** `DeleteTierAdapter` catches no infrastructure exceptions — a DELETE cannot violate
  a unique constraint, so there is no business-meaningful exception to translate. All other
  infrastructure exceptions propagate unchanged to the global handler. Per
  `agent_docs/error_handling.md` § Adapter: catch only when there is business meaning to
  translate.
- **N3.** `DeleteTierResponse` uses `model_config = ConfigDict(from_attributes=True)`.
  Per `agent_docs/entry_points/fastapi.md` § Request and Response schemas.
- **N4.** All new `.py` files start with `# FEATURE: delete_tier — <purpose>`.
  Per `agent_docs/stable_vs_feature.md`.
- **N5.** `DeleteTierUseCase.__call__` never raises `HTTPException`; it raises only
  `NotFoundDomainError`. Per CLAUDE.md hard rule 1.
- **N6.** No cross-slice imports outside `tiers/_shared/`; `DeleteTierPort` and
  `DeleteTierAdapter` are not imported by any other slice's domain, data, or
  presentation layer. Per `agent_docs/architecture.md` § `_shared/` rules.
- **N7.** All DB calls in `DeleteTierAdapter` use `async def` + `await`; no
  synchronous SQLAlchemy calls. Per CLAUDE.md locked technology stack.
- **N8.** `mypy --strict src/app` passes for all new files introduced by this slice.
  Per CLAUDE.md § Verifying changes.
- **N9.** `ruff format src/app` and `ruff check src/app` pass with no errors.
  Per CLAUDE.md § Verifying changes.
- **N10.** `class DeleteTierAdapter(DeleteTierPort):` explicitly inherits from the port;
  the inheritance line is mandatory. Per `agent_docs/architecture.md` § Adapter pattern.
- **N11.** `DeleteTierPort` carries `@runtime_checkable`; every port in the project
  requires it. Per CLAUDE.md § Forbidden without explicit user approval.
- **N12.** The router module path
  `app.features.tiers.delete_tier.presentation.router` is added to
  `Container.wiring_config.modules`; omitting it causes `Provide[...]` to silently
  resolve to the provider sentinel. Per `agent_docs/entry_points/fastapi.md` §
  Dependency injection at the endpoint.
- **N13.** One `ignore_imports` line for the new router is added to `.importlinter`.
  Per `agent_docs/entry_points/fastapi.md` § Dependency injection at the endpoint.

## Out of scope

- Migrating `create_tier`, `list_tiers`, `get_tier`, or `update_tier` — separate slices 0033–0036.
- Soft delete — the `Tier` ORM model has no deleted flag; this is a hard delete.
- Cascade deletion of users assigned to the deleted tier — no enforced FK constraint blocks deletion.
- Removing `tiers/schemas.py` or `tiers/repository.py` — still referenced by `rate_limits/` and
  `users/` features; cleanup is a separate task.
- URL normalisation from `/tier/{name}` (singular) to `/tiers/{name}` (plural).

## Traceability

| Requirement | Verified by |
|---|---|
| F1 | endpoint integration test; outside-in test |
| F2 | use-case unit test (not-found path) |
| F3 | use-case unit test (happy path) |
| F4 | endpoint integration test (404 case) |
| F5 | endpoint integration test (403 case) |
| F6 | endpoint integration test (401 case) |
| F7 | adapter unit test (`get` happy path; `get` not-found) |
| F8 | adapter unit test (`delete` happy path; `delete` no-op) |
| F9 | code review checklist in validation.md |
| F10 | code review checklist in validation.md |
| F11 | code review checklist in validation.md |
| F12 | code review checklist in validation.md |
| N1–N13 | code review checklist in validation.md |
