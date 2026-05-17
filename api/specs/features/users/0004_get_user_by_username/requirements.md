# 0004 · get_user_by_username — Requirements

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md

## Functional requirements

- **F1.** The endpoint `GET /api/v1/user/{username}` accepts a `username` path
  parameter and returns a `GetUserByUsernameResponse` with status `200` when an
  active (non-deleted) user with that username exists.
- **F2.** `GetUserByUsernameResponse` contains exactly six fields: `id` (`int`),
  `name` (`str`), `username` (`str`), `email` (`str`), `profile_image_url`
  (`str`), `tier_id` (`int | None`).
- **F3.** The use case raises `NotFoundDomainError("User not found")` when the
  adapter returns `None` for the given username.
- **F4.** The endpoint returns HTTP `404` with body `{"message": "User not found"}`
  when `NotFoundDomainError` is raised.
- **F5.** The adapter queries the `User` ORM model filtering on both
  `username = <value>` and `is_deleted = false`; it returns `None` when no
  matching row exists.
- **F6.** The adapter returns `None` (not raises) when no row is found; the
  use case is responsible for converting `None` to `NotFoundDomainError`.
- **F7.** A soft-deleted user (one with `is_deleted = true`) is treated
  identically to a non-existent user — the adapter returns `None` and the
  endpoint responds HTTP `404`.
- **F8.** The endpoint is public: it requires no authentication or
  authorization token.
- **F9.** The router converts the `username` path parameter into a
  `GetUserByUsernameQuery(username=username)` before passing it to the use
  case.
- **F10.** The router converts the returned `FoundUser` entity into a
  `GetUserByUsernameResponse` before returning it to the caller; internal
  domain entities are never returned directly.

## Non-functional requirements

- **N1.** The use case is a class (`GetUserByUsernameUseCase`) with a single
  public method `__call__()`; called as `await use_case(query)`. Per
  `agent_docs/architecture.md` § Use-case shape.
- **N2.** The adapter (`GetUserByUsernameAdapter`) catches no exceptions; this
  slice's read-only query has no business-meaningful infrastructure exception to
  translate. All infrastructure failures propagate to the global handler. Per
  `agent_docs/error_handling.md` § Right shape: read-only query, no catch.
- **N3.** `GetUserByUsernameResponse` uses
  `model_config = ConfigDict(from_attributes=True)`. Per `agent_docs/architecture.md`
  § Command vs Request, Entity vs Response.
- **N4.** Every new `.py` file starts with `# FEATURE: get_user_by_username — <purpose>`
  on line 1. Per `agent_docs/stable_vs_feature.md`.
- **N5.** No `HTTPException` is raised inside `GetUserByUsernameUseCase`. Per
  CLAUDE.md universal hard rule 1.
- **N6.** No cross-slice imports; the new slice imports only from its own
  subdirectories and from `features/users/_shared/` if needed. Per CLAUDE.md
  universal hard rule 7.
- **N7.** All database access is `async def` with `await`; no synchronous
  SQLAlchemy calls. Per CLAUDE.md locked technology stack.
- **N8.** `mypy src/app` passes in strict mode for all new files. Per CLAUDE.md
  § Verifying changes.
- **N9.** `ruff format src/app` and `ruff check src/app` produce no errors or
  warnings for all new files. Per CLAUDE.md § Verifying changes.
- **N10.** `GetUserByUsernameAdapter` explicitly inherits from
  `GetUserByUsernamePort` (i.e., `class GetUserByUsernameAdapter(GetUserByUsernamePort):`).
  Per CLAUDE.md forbidden list and `agent_docs/architecture.md` § Terminology:
  port and adapter.
- **N11.** `GetUserByUsernamePort` carries the `@runtime_checkable` decorator.
  Per CLAUDE.md forbidden list.
- **N12.** All imports inside `src/app/` use relative paths; no absolute
  `from app...` or `from src.app...` imports. Per `agent_docs/architecture.md`
  § Import conventions.

## Out of scope

- Authentication or authorization on `GET /user/{username}`.
- Exposing soft-deleted users via a query flag or separate endpoint.
- Caching with the `@cache` decorator.
- Refactoring any other flat use-case files in `use_cases/`.
- A `get_user_by_id` or alternative lookup-key variant.

## Traceability

| Requirement | Verified by |
|---|---|
| F1 | endpoint integration test; outside-in test |
| F2 | endpoint integration test; outside-in test |
| F3 | use-case unit test |
| F4 | endpoint integration test |
| F5 | adapter unit test |
| F6 | adapter unit test; use-case unit test |
| F7 | endpoint integration test |
| F8 | endpoint integration test (no auth header required) |
| F9 | endpoint integration test; code review |
| F10 | endpoint integration test; code review |
| N1–N12 | code review checklist in validation.md |
