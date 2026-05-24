# 0039 · update_tier_by_id — Requirements

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md

## Functional requirements

### Endpoint

- **F1.** `PATCH /api/v1/tier/{id}` accepts `UpdateTierRequest` with field `name` (non-empty string) and integer path parameter `id`, and returns `UpdateTierResponse(message="Tier updated")` with HTTP 200 on success.
- **F2.** FastAPI returns HTTP 422 when the `name` field is absent from the request body.
- **F3.** FastAPI returns HTTP 422 when `name` is an empty string (violates `min_length=1`).
- **F4.** FastAPI returns HTTP 422 when the path parameter `{id}` cannot be parsed as an integer.
- **F5.** The endpoint returns HTTP 401 when the request carries no valid bearer token.
- **F6.** The endpoint returns HTTP 403 when the authenticated user is not a superuser.

### Use-case

- **F7.** The use-case raises `NotFoundDomainError("Tier not found")` when `port.get(command.id)` returns `None`.
- **F8.** When `NotFoundDomainError` is raised, `port.update` is never called.
- **F9.** On the happy path the use-case calls `port.get(command.id)`, then `port.update(command.id, command.name)`.
- **F10.** The use-case returns `None` on the happy path; the router constructs the `UpdateTierResponse`.
- **F11.** `DuplicateValueDomainError` raised by `port.update` propagates unchanged through the use-case to the global exception handler, producing HTTP 409.

### Adapter

- **F12.** `adapter.get(tier_id: int)` returns a `TierItem` with the correct `id`, `name`, and `created_at` when a tier with that primary key exists.
- **F13.** `adapter.get(tier_id: int)` returns `None` when no tier with the given primary key exists.
- **F14.** `adapter.update(tier_id: int, name: str)` renames the matching tier row to `name` and sets `updated_at` to the current timestamp.
- **F15.** `adapter.update` raises `DuplicateValueDomainError("Tier name already exists")` — wrapping the original `IntegrityError` with `from exc` — when the `name` value is already taken by another tier.
- **F16.** `adapter.update` does not catch exceptions other than `IntegrityError`; unknown infrastructure exceptions propagate unchanged to the global handler.

## Non-functional requirements

- **N1.** The use-case is a class with `__call__()`; invoked as `await use_case(command)`. Per `agent_docs/architecture.md` § Use-case shape.
- **N2.** The adapter catches only business-meaningful infrastructure exceptions (`IntegrityError` → `DuplicateValueDomainError`); all other exceptions propagate to the global handler without logging. Per `agent_docs/error_handling.md` § Adapter: catch only when there is business meaning to translate.
- **N3.** All Pydantic schemas that are populated from ORM objects use `model_config = ConfigDict(from_attributes=True)`. Per `agent_docs/entry_points/fastapi.md` § Request and Response schemas.
- **N4.** Every modified `.py` file retains its existing `# FEATURE: update_tier — <purpose>` header on line 1. Per `agent_docs/stable_vs_feature.md`.
- **N5.** No `HTTPException` is raised inside the use-case; only `DomainError` subclasses are raised. Per CLAUDE.md universal hard rules.
- **N6.** No cross-slice imports beyond the feature's own `_shared/`. Per CLAUDE.md universal hard rules.
- **N7.** All database I/O is `async def` + `await`; no synchronous SQLAlchemy calls. Per CLAUDE.md locked technology stack.
- **N8.** `mypy src/app` (strict) passes for all modified files.
- **N9.** `ruff format src/app` and `ruff check src/app` pass with no violations.

## Out of scope

- Changing the response body (remains `{"message": "Tier updated"}`).
- Migrating `delete_tier` to id-based lookup — separate slice 0040.
- Renaming the `name` column in the database.
- Returning the updated `TierItem` in the response.
- URL normalisation to plural `/tiers/{id}`.
- Converting `get_current_superuser` auth errors to `DomainError` subclasses.
- Cache invalidation — no caching applied to tier endpoints.

## Traceability

| Requirement | Verified by |
|---|---|
| F1 | endpoint integration test; outside-in test |
| F2, F3, F4 | endpoint integration test |
| F5, F6 | endpoint integration test |
| F7, F8 | use-case unit test |
| F9, F10 | use-case unit test |
| F11 | use-case unit test |
| F12, F13 | adapter unit test |
| F14, F15, F16 | adapter unit test |
| N1–N9 | code review checklist in `validation.md` |
