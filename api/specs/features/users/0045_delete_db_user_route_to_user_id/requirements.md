# 0045 · delete_db_user_route_to_user_id — Requirements

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md

## Functional requirements

- **F1.** `DELETE /api/v1/db_user/{user_id}` accepts `user_id: int` as a path
  parameter and, on success, returns HTTP 200 with body
  `{"message": "User deleted from the database"}`.
- **F2.** The endpoint returns HTTP 422 when `user_id` is a non-integer value
  (e.g. `"abc"`), enforced by FastAPI's path parameter type coercion.
- **F3.** The endpoint returns HTTP 401 when the Bearer JWT is absent or
  invalid, raised by the `get_current_superuser` dependency.
- **F4.** The endpoint returns HTTP 403 when the requester is authenticated but
  is not a superuser, raised by the `get_current_superuser` dependency (not by
  the use-case).
- **F5.** `DeleteDbUserCommand` carries a single field `target_user_id: int`;
  the router populates it from the `user_id` path parameter.
- **F6.** The use-case calls `DeleteDbUserPort.get_by_id(command.target_user_id)`
  and raises `NotFoundDomainError("User not found")` when the result is `None`,
  without calling `db_delete`.
- **F7.** The use-case calls `DeleteDbUserPort.db_delete(command.target_user_id)`
  only after the existence check (F6) passes, and returns
  `DeleteDbUserResult(message="User deleted from the database")`.
- **F8.** `DbDeleteUserTarget` carries a single field `id: int`; the adapter
  populates it from `User.id`.
- **F9.** `DeleteDbUserAdapter.get_by_id(user_id: int)` queries `User` filtering
  by `User.id == user_id`; it returns `DbDeleteUserTarget(id=row.id)` when a row
  is found, or `None` when no row matches.
- **F10.** `DeleteDbUserAdapter.db_delete(target_user_id: int)` executes
  `DELETE FROM User WHERE User.id == target_user_id` and commits the
  transaction.
- **F11.** `DeleteDbUserAdapter.db_delete` maps `IntegrityError` raised by the
  delete/commit to `DuplicateValueDomainError("User has dependent records")`.
- **F12.** `NotFoundDomainError` is translated to HTTP 404 by the global
  exception handler in `adapters/http/exception_handlers.py`.
- **F13.** `DuplicateValueDomainError` is translated to HTTP 409 by the global
  exception handler.

## Non-functional requirements

- **N1.** The use-case (`DeleteDbUserUseCase`) is a class with a single
  `__call__()` method; it is invoked as `await use_case(command)`. Per
  `agent_docs/architecture.md` § Use-case shape.
- **N2.** The adapter catches only the business-meaningful `IntegrityError`
  (dependent records) and translates it to `DuplicateValueDomainError`; it does
  not wrap operations in `try/except Exception`. Unknown infrastructure
  exceptions propagate to the global handler. The adapter does not log. Per
  `agent_docs/error_handling.md` § Adapter: catch only when there is business
  meaning to translate.
- **N3.** `DeleteDbUserAdapter` explicitly inherits from `DeleteDbUserPort`
  (`class DeleteDbUserAdapter(DeleteDbUserPort):`). Per
  `agent_docs/architecture.md` § Adapter pattern.
- **N4.** `DeleteDbUserPort` carries the `@runtime_checkable` decorator and
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

- Soft delete (`DELETE /user/{user_id}`) — slice 0044.
- Other routes in the `{username}` → `{user_id}` migration series (slices
  0041–0043, 0046–0050).
- Updating shared test fixtures used by other slices — only files under
  `tests/features/users/0008_delete_db_user/` are changed.
- Cache invalidation — not applicable to this authenticated write endpoint.
- Rate limiting — not applied; the endpoint is behind superuser auth.
- Any change to `users/_shared/policies.py` — this endpoint performs no
  ownership check.

## Traceability

| Requirement | Verified by |
|---|---|
| F1 | endpoint integration test; outside-in test |
| F2 | endpoint integration test (422 case) |
| F3 | endpoint integration test (401 case) |
| F4 | endpoint integration test (403 case) |
| F5 | use-case unit test (command construction checked via input to mock port) |
| F6 | use-case unit test (get_by_id returns None → NotFoundDomainError, db_delete not called) |
| F7 | use-case unit test (happy path → db_delete called with target_user_id) |
| F8 | adapter unit test (get_by_id returns DbDeleteUserTarget(id=...)) |
| F9 | adapter unit test (row found vs. not found cases) |
| F10 | adapter unit test (db_delete DELETE assertions) |
| F11 | adapter unit test (IntegrityError → DuplicateValueDomainError) |
| F12 | endpoint integration test (404 case) |
| F13 | endpoint integration test (409 case, if exercised) |
| N1–N11 | code review checklist in validation.md |
