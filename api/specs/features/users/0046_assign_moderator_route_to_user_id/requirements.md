# 0046 · assign_moderator_route_to_user_id — Requirements

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md

## Functional requirements

- **F1.** `PATCH /api/v1/user/{user_id}/assign-moderator` accepts `user_id: int`
  as a path parameter and, on success, returns HTTP 200 with an
  `AssignModeratorResponse` body carrying `id`, `name`, `username`, `email`,
  `profile_image_url`, `tier_id`, and `is_moderator: true`.
- **F2.** The endpoint returns HTTP 422 when `user_id` is a non-integer value
  (e.g. `"abc"`), enforced by FastAPI's path parameter type coercion.
- **F3.** The endpoint returns HTTP 401 when the Bearer JWT is absent or invalid,
  raised by the `get_current_superuser` dependency chain.
- **F4.** The endpoint returns HTTP 403 when the authenticated caller is not a
  superuser, raised by the `get_current_superuser` dependency.
- **F5.** `AssignModeratorCommand` carries `target_user_id: int`,
  `requester_id: int`, and `requester_is_superuser: bool`; the router populates
  them from the `user_id` path param, `current_superuser["id"]`, and
  `current_superuser["is_superuser"]` respectively.
- **F6.** The use-case raises `ForbiddenDomainError("Superuser privilege
  required")` when `command.requester_is_superuser` is `False`, before any port
  call is made.
- **F7.** The use-case calls `AssignModeratorPort.get_by_id(command.target_user_id)`
  and raises `NotFoundDomainError("User not found")` when the result is `None`.
- **F8.** The use-case raises `DuplicateValueDomainError("User is already a
  moderator")` when the entity returned by `get_by_id` has `is_moderator == True`.
- **F9.** The use-case calls
  `AssignModeratorPort.assign(command.target_user_id, command.requester_id)` only
  after the superuser check (F6), existence check (F7), and already-moderator
  check (F8) all pass, and returns the resulting `AssignedUser`.
- **F10.** `AssignModeratorAdapter.get_by_id(user_id: int)` queries `User`
  filtering by `User.id == user_id` and `User.is_deleted == False`; it returns an
  `AssignedUser` populated from the row when one is found, or `None` when no row
  matches.
- **F11.** `AssignModeratorAdapter.assign(target_user_id: int,
  granted_by_user_id: int)` executes
  `UPDATE User SET is_moderator=True, moderator_granted_by_user_id=granted_by_user_id
  WHERE User.id == target_user_id`, commits, re-reads the row by `User.id`, and
  returns the refreshed `AssignedUser`.
- **F12.** `NotFoundDomainError` is translated to HTTP 404 by the global
  exception handler in `adapters/http/exception_handlers.py`.
- **F13.** `DuplicateValueDomainError` is translated to HTTP 409 by the global
  exception handler.
- **F14.** `ForbiddenDomainError` is translated to HTTP 403 by the global
  exception handler.

## Non-functional requirements

- **N1.** The use-case (`AssignModeratorUseCase`) is a class with a single
  `__call__()` method; it is invoked as `await use_case(command)`. Per
  `agent_docs/architecture.md` § Use-case shape.
- **N2.** The adapter catches only business-meaningful infrastructure exceptions;
  `assign` has no unique-constraint or business-meaningful FK path, so no
  `try/except` is added. Unknown infrastructure exceptions propagate to the
  global handler. The adapter does not log. Per `agent_docs/error_handling.md`
  § Adapter: catch only when there is business meaning to translate.
- **N3.** `AssignModeratorAdapter` explicitly inherits from `AssignModeratorPort`
  (`class AssignModeratorAdapter(AssignModeratorPort):`). Per
  `agent_docs/architecture.md` § Adapter pattern.
- **N4.** `AssignModeratorPort` carries the `@runtime_checkable` decorator and
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

- Revoke moderator (`remove_moderator`) — slice 0047.
- Other routes in the `{username}` → `{user_id}` migration series.
- Updating shared test fixtures used by other slices — only files under
  `tests/features/users/0015_assign_moderator/` are changed.
- Cache invalidation — not applicable to this authenticated write endpoint.
- Rate limiting — not applied; the endpoint is behind superuser auth.

## Traceability

| Requirement | Verified by |
|---|---|
| F1 | endpoint integration test; outside-in test |
| F2 | endpoint integration test (422 case) |
| F3 | endpoint integration test (401 case) |
| F4 | endpoint integration test (403 case) |
| F5 | use-case unit test (command construction checked via input to mock port) |
| F6 | use-case unit test (requester_is_superuser=False → ForbiddenDomainError) |
| F7 | use-case unit test (get_by_id returns None → NotFoundDomainError) |
| F8 | use-case unit test (target.is_moderator=True → DuplicateValueDomainError) |
| F9 | use-case unit test (happy path → assign called with target_user_id, requester_id) |
| F10 | adapter unit test (row found vs. not found / is_deleted cases) |
| F11 | adapter unit test (assign UPDATE assertions + refreshed entity) |
| F12 | endpoint integration test (404 case) |
| F13 | endpoint integration test (409 case); outside-in test (second call) |
| F14 | endpoint integration test (403 case) |
| N1–N11 | code review checklist in validation.md |
