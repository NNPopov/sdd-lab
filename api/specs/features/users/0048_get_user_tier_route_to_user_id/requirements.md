# 0048 · get_user_tier_route_to_user_id — Requirements

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md

## Functional requirements

- **F1.** `GET /api/v1/user/{user_id}/tier` accepts `user_id: int` as a path
  parameter and, when the user exists and has a valid tier, returns HTTP 200
  with a `GetUserTierResponse` body carrying `tier_id`, `tier_name`, and
  `tier_created_at`.
- **F2.** The endpoint returns HTTP 200 with a `null` body when the user exists
  but has no tier assigned (`tier_id is None`) — the existing slice-0005
  behaviour, preserved unchanged.
- **F3.** The endpoint returns HTTP 422 when `user_id` is a non-integer value
  (e.g. `"abc"`), enforced by FastAPI's path parameter type coercion.
- **F4.** `GetUserTierQuery` carries `user_id: int` (replacing the former
  `username: str`); the router populates it from the `user_id` path param via
  `GetUserTierQuery(user_id=user_id)`.
- **F5.** The use-case calls `GetUserTierPort.get(query)` and raises
  `NotFoundDomainError("User not found")` when the port returns `UserNotFound`.
- **F6.** The use-case raises `NotFoundDomainError("Tier not found")` when the
  port returns `TierNotFound` (user has a `tier_id` but the tier row is absent).
- **F7.** The use-case returns `None` when the port returns `None` (user exists
  with no tier), and returns the `FoundUserTier` entity unchanged when the port
  returns one.
- **F8.** `GetUserTierAdapter.get(query)` queries `User` filtering by
  `User.id == query.user_id` and `User.is_deleted == False`; it returns
  `UserNotFound()` when no row matches, `None` when the row's `tier_id` is
  `None`, `TierNotFound()` when the referenced tier row is absent, and a
  `FoundUserTier` populated from the tier row otherwise.
- **F9.** `NotFoundDomainError` is translated to HTTP 404 by the global
  exception handler in `adapters/http/exception_handlers.py`.

## Non-functional requirements

- **N1.** The use-case (`GetUserTierUseCase`) is a class with a single
  `__call__()` method; it is invoked as `await use_case(query)`. Per
  `agent_docs/architecture.md` § Use-case shape.
- **N2.** The adapter catches only business-meaningful infrastructure exceptions;
  `get` is a read-only query with no such path, so no `try/except` is added.
  Unknown infrastructure exceptions propagate to the global handler. The adapter
  does not log. Per `agent_docs/error_handling.md` § read-only query, no catch.
- **N3.** `GetUserTierAdapter` explicitly inherits from `GetUserTierPort`
  (`class GetUserTierAdapter(GetUserTierPort):`). Per
  `agent_docs/architecture.md` § Adapter pattern.
- **N4.** `GetUserTierPort` carries the `@runtime_checkable` decorator and
  inherits from `typing.Protocol`. Per `agent_docs/architecture.md` § Port
  pattern.
- **N5.** No `HTTPException` is raised inside the use-case or adapter; domain
  failures use `DomainError` subclasses only. Per `agent_docs/error_handling.md`.
- **N6.** No cross-slice imports outside the feature's `_shared/`. Per
  `agent_docs/architecture.md` § Layer rules.
- **N7.** All database operations are `async def` + `await`; no synchronous DB
  calls. Per the locked technology stack in `CLAUDE.md`.
- **N8.** All modified FEATURE files retain `# FEATURE: <slice> — <purpose>` on
  line 1. Per `agent_docs/stable_vs_feature.md`.
- **N9.** All imports inside `src/app/` are relative; test imports are absolute
  through `app.*`. Per `agent_docs/architecture.md` § Import conventions.
- **N10.** `mypy src/app` (strict) passes with no new errors introduced by this
  slice.
- **N11.** `ruff format src/app` and `ruff check src/app` pass with no new
  violations.

## Out of scope

- Update-user-tier route (`update_user_tier`) — slice 0050.
- Other routes in the `{username}` → `{user_id}` migration series (0041–0050, 0042).
- Changing the "user has no tier" behaviour from `200`/`null` to `404` — the PRD
  defers to existing domain behaviour.
- Adding authentication/authorization to the route — the existing slice-0005
  route has none and none is added here.
- Updating shared test fixtures used by other slices — only files under
  `tests/features/users/0005_get_user_tier/` are changed.
- Caching and rate limiting — not applied.

## Traceability

| Requirement | Verified by |
|---|---|
| F1 | endpoint integration test; outside-in test |
| F2 | endpoint integration test (200/null case) |
| F3 | endpoint integration test (422 case) |
| F4 | use-case unit test (query construction checked via input to mock port) |
| F5 | use-case unit test (port returns UserNotFound → NotFoundDomainError) |
| F6 | use-case unit test (port returns TierNotFound → NotFoundDomainError) |
| F7 | use-case unit test (None pass-through; FoundUserTier pass-through) |
| F8 | adapter unit test (UserNotFound / None / TierNotFound / FoundUserTier cases) |
| F9 | endpoint integration test (404 case); outside-in test (unknown id) |
| N1–N11 | code review checklist in validation.md |
