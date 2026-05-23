# 0036 · update_tier — Requirements

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md

## Functional requirements

- **F1.** The endpoint `PATCH /api/v1/tier/{name}` accepts an `UpdateTierRequest` body with a
  required `new_name: str` field and returns `UpdateTierResponse(message="Tier updated")` with
  HTTP 200 on a successful rename.
- **F2.** The endpoint returns HTTP 422 when the request body omits `new_name` or provides an
  empty string (`min_length=1` constraint).
- **F3.** The endpoint returns HTTP 401 when the request carries no valid bearer token (enforced
  by `get_current_superuser` before the use-case is reached).
- **F4.** The endpoint returns HTTP 403 when the caller is authenticated but is not a superuser
  (enforced by `get_current_superuser` before the use-case is reached).
- **F5.** The router builds `UpdateTierCommand(name=<path_param>, new_name=body.new_name)` and
  passes it to `UpdateTierUseCase`; it does not contain business logic.
- **F6.** The use-case calls `port.get(command.name)`; if the result is `None` it raises
  `NotFoundDomainError("Tier not found")` and does **not** call `port.update`.
- **F7.** The endpoint returns HTTP 404 when `NotFoundDomainError` is raised by the use-case.
- **F8.** The use-case calls `port.update(command.name, command.new_name)` when `port.get`
  returns a `TierItem`.
- **F9.** The use-case returns `None`; the router constructs `UpdateTierResponse()` independently
  and returns it with HTTP 200.
- **F10.** The use-case does not catch `DuplicateValueDomainError`; it propagates from
  `port.update` to the global exception handler unchanged.
- **F11.** The endpoint returns HTTP 409 when `DuplicateValueDomainError` is raised.
- **F12.** The adapter's `get(name)` method executes a `SELECT` on the `Tier` table filtered by
  `name` and returns a `TierItem` when a matching row is found.
- **F13.** The adapter's `get(name)` method returns `None` when no row with that name exists.
- **F14.** The adapter's `update(name, new_name)` method executes an `UPDATE` on the `Tier` table
  setting `name = new_name` and `updated_at = now()` where `name = name`, then commits.
- **F15.** The adapter's `update` method catches `IntegrityError` raised by `session.commit()` and
  re-raises it as `DuplicateValueDomainError("Tier name already exists")` preserving the original
  cause with `from exc`.
- **F16.** The adapter's `update` method does not catch any exception other than `IntegrityError`;
  all other infrastructure exceptions propagate unchanged to the global handler.
- **F17.** The adapter's `get` method has no `try/except`; infrastructure failures during the
  read propagate unchanged.

## Non-functional requirements

- **N1.** `UpdateTierUseCase` is a class with `__init__(self, port: UpdateTierPort)` and a single
  public method `async def __call__(self, command: UpdateTierCommand) -> None`, called as
  `await use_case(command)`. Per `agent_docs/architecture.md` § Use-case shape.
- **N2.** `UpdateTierAdapter` catches only `IntegrityError` from `session.commit()` in `update()`;
  it does not wrap reads, does not catch `Exception`, and does not log. The global handler in
  `adapters/http/exception_handlers.py` handles all other failures. Per
  `agent_docs/error_handling.md`.
- **N3.** `UpdateTierRequest` and `UpdateTierResponse` carry
  `model_config = ConfigDict(from_attributes=True)`. Per `agent_docs/entry_points/fastapi.md`.
- **N4.** Every new `.py` file in the slice starts with `# FEATURE: update_tier — <purpose>` on
  line 1. Per `agent_docs/stable_vs_feature.md`.
- **N5.** No `HTTPException` is raised inside `UpdateTierUseCase`. Domain failures are expressed as
  `DomainError` subclasses. Per CLAUDE.md § Universal hard rules, rule 1.
- **N6.** No imports cross into another slice's `domain/`, `data/`, or `presentation/` folders.
  Shared types come from `tiers/_shared/entities.py`. Per CLAUDE.md rule 7.
- **N7.** All database operations in `UpdateTierAdapter` are `async def` with `await`; no
  synchronous SQLAlchemy calls. Per CLAUDE.md § Locked technology stack.
- **N8.** `mypy src/app` in strict mode passes with no new errors introduced by this slice.
- **N9.** `ruff format src/app` and `ruff check src/app` pass with no new violations.
- **N10.** `UpdateTierPort` carries the `@runtime_checkable` decorator and inherits from
  `typing.Protocol`. Per CLAUDE.md § Forbidden without explicit user approval.
- **N11.** `class UpdateTierAdapter(UpdateTierPort):` — explicit inheritance from the port is
  mandatory on the adapter class declaration. Per `agent_docs/architecture.md` § Terminology:
  port and adapter.
- **N12.** All imports inside `src/app/` are relative; absolute `app.*` imports are used only in
  `tests/`. Per `agent_docs/architecture.md` § Import conventions.
- **N13.** The new router module path
  `app.features.tiers.update_tier.presentation.router -> app.bootstrap.container` is added to
  the `ignore_imports` section of `.importlinter`. Per `agent_docs/entry_points/fastapi.md`.

## Out of scope

- Migrating `erase_tier` (`DELETE /tier/{name}`) — separate slice 0037.
- Partial updates beyond renaming — the only mutable field is `name`.
- Returning the updated `TierItem` in the response body — current API contract is a confirmation
  message only.
- URL normalisation from `/tier/{name}` (singular) to `/tiers/{name}` (plural).
- Removing `tiers/schemas.py` or `tiers/repository.py` — still referenced by `rate_limits/` and
  `users/` features.
- Converting `get_current_superuser` 403/401 exceptions to `DomainError` subclasses — pre-existing
  pattern, out of scope.
- Cache invalidation — no caching is applied to tier read endpoints.

## Traceability

| Requirement | Verified by |
|---|---|
| F1 | endpoint integration test (200 happy path); outside-in test |
| F2 | endpoint integration test (422 — missing / empty `new_name`) |
| F3 | endpoint integration test (401 — unauthenticated) |
| F4 | endpoint integration test (403 — non-superuser) |
| F5 | code review (router body) |
| F6 | use-case unit test (not-found branch: `port.get` returns `None`, `port.update` not called) |
| F7 | endpoint integration test (404 — unknown name) |
| F8 | use-case unit test (happy path: `port.update` is called) |
| F9 | use-case unit test (happy path: return value is `None`); code review (router constructs `UpdateTierResponse`) |
| F10 | use-case unit test (duplicate branch: `DuplicateValueDomainError` propagates) |
| F11 | endpoint integration test (409 — duplicate `new_name`) |
| F12 | adapter unit test (`get` happy path — returns `TierItem`) |
| F13 | adapter unit test (`get` not-found — returns `None`) |
| F14 | adapter unit test (`update` happy path — row has `name=new_name` and non-null `updated_at`) |
| F15 | adapter unit test (`update` duplicate — `DuplicateValueDomainError` raised) |
| F16 | adapter unit test (unknown exception propagates unchanged) |
| F17 | code review (no `try/except` in `get`) |
| N1–N13 | code review checklist in validation.md |
