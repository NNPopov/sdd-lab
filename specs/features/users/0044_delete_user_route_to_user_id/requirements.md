# 0044 · delete_user_route_to_user_id — Requirements

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md

## Functional requirements

- **F1.** `DELETE /api/v1/user/{user_id}` accepts `user_id: int` as a path
  parameter and, on success, returns HTTP 200 with body
  `{"message": "User deleted"}`.
- **F2.** The endpoint returns HTTP 422 when `user_id` is a non-integer value
  (e.g. `"abc"`), enforced by FastAPI's path parameter type coercion.
- **F3.** The endpoint returns HTTP 401 when the Bearer JWT is absent, invalid,
  or already blacklisted, raised by the `get_current_user` dependency.
- **F4.** `DeleteUserCommand` carries `target_user_id: int` and
  `requester_user_id: int`; the router populates them from the `user_id` path
  param and `current_user["id"]` respectively.
- **F5.** The use-case calls `DeleteUserPort.get_by_id(command.target_user_id)`
  and raises `NotFoundDomainError("User not found")` when the result is `None`.
- **F6.** The use-case raises `ForbiddenDomainError` when
  `command.requester_user_id` does not equal `target.id`, via
  `check_owner(command.requester_user_id, target.id)` in
  `users/_shared/policies.py`.
- **F7.** The use-case calls `DeleteUserPort.soft_delete(command.target_user_id)`
  only after the existence check (F5) and ownership check (F6) both pass.
- **F8.** `check_owner(requester_id: int, owner_id: int)` in
  `users/_shared/policies.py` raises `ForbiddenDomainError` when
  `requester_id != owner_id` and returns normally otherwise.
- **F9.** `DeleteUserTarget` carries a single field `id: int`; the adapter
  populates it from `User.id`.
- **F10.** `DeleteUserAdapter.get_by_id(user_id: int)` queries `User` filtering
  by `User.id == user_id` and `User.is_deleted == False`; it returns
  `DeleteUserTarget(id=row.id)` when a row is found, or `None` when no row
  matches.
- **F11.** `DeleteUserAdapter.soft_delete(target_user_id: int)` executes
  `UPDATE User SET is_deleted=True, deleted_at=now(UTC) WHERE User.id ==
  target_user_id` and commits the transaction.
- **F12.** The router calls `blacklist_token(token, blacklist)` after the
  use-case returns successfully, invalidating the requester's access JWT before
  the response is sent.
- **F13.** `NotFoundDomainError` is translated to HTTP 404 by the global
  exception handler in `adapters/http/exception_handlers.py`.
- **F14.** `ForbiddenDomainError` is translated to HTTP 403 by the global
  exception handler.

## Non-functional requirements

- **N1.** The use-case (`DeleteUserUseCase`) is a class with a single
  `__call__()` method; it is invoked as `await use_case(command)`. Per
  `agent_docs/architecture.md` § Use-case shape.
- **N2.** The adapter catches only business-meaningful infrastructure exceptions;
  `soft_delete` has no unique-constraint path, so no `try/except` is added.
  Unknown infrastructure exceptions propagate to the global handler. The adapter
  does not log. Per `agent_docs/error_handling.md` § Adapter: catch only when
  there is business meaning to translate.
- **N3.** `DeleteUserAdapter` explicitly inherits from `DeleteUserPort`
  (`class DeleteUserAdapter(DeleteUserPort):`). Per `agent_docs/architecture.md`
  § Adapter pattern.
- **N4.** `DeleteUserPort` carries the `@runtime_checkable` decorator and
  inherits from `typing.Protocol`. Per `agent_docs/architecture.md` § Port
  pattern.
- **N5.** No `HTTPException` is raised inside the use-case or adapter; domain
  failures use `DomainError` subclasses only. Per `agent_docs/error_handling.md`.
- **N6.** No cross-slice imports outside the feature's `_shared/`; `check_owner`
  is imported from `users/_shared/policies.py`. Per `agent_docs/architecture.md`
  § Layer rules.
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

- Hard delete (`DELETE /db_user/{user_id}`) — slice 0045.
- Other routes in the `{username}` → `{user_id}` migration series (slices 0043,
  0045–0050).
- Updating shared test fixtures used by other slices — only files under
  `tests/features/users/0007_delete_user/` are changed.
- Cache invalidation — not applicable to this authenticated write endpoint.
- Rate limiting — not applied; the endpoint is behind auth.

## Traceability

| Requirement | Verified by |
|---|---|
| F1 | endpoint integration test; outside-in test |
| F2 | endpoint integration test (422 case) |
| F3 | endpoint integration test (401 case) |
| F4 | use-case unit test (command construction checked via input to mock port) |
| F5 | use-case unit test (get_by_id returns None → NotFoundDomainError) |
| F6 | use-case unit test (mismatched IDs → ForbiddenDomainError) |
| F7 | use-case unit test (happy path → soft_delete called with target_user_id) |
| F8 | use-case unit test (check_owner with equal IDs → no raise) |
| F9 | adapter unit test (get_by_id returns DeleteUserTarget(id=...)) |
| F10 | adapter unit test (row found vs. not found / is_deleted cases) |
| F11 | adapter unit test (soft_delete UPDATE assertions) |
| F12 | outside-in test (token appears in token_blacklist after 200) |
| F13 | endpoint integration test (404 case) |
| F14 | endpoint integration test (403 case) |
| N1–N11 | code review checklist in validation.md |
