# 0003 · list_users — Requirements

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md

## Functional requirements

- **F1.** `GET /api/v1/users` returns `ListUsersResponse` with HTTP status `200`
  on success.
- **F2.** The response body includes exactly the fields `items`, `total_count`,
  `page`, and `items_per_page`.
- **F3.** Each element of `items` contains exactly the fields `id`, `name`,
  `username`, `email`, `profile_image_url`, and `tier_id`.
- **F4.** Users where `is_deleted=True` are excluded from both `items` and
  `total_count`; they never appear in any response to this endpoint.
- **F5.** When `page` is less than `1`, FastAPI returns `422 Unprocessable Entity`
  before the use case is invoked.
- **F6.** When `items_per_page` is less than `1` or greater than `100`, FastAPI
  returns `422 Unprocessable Entity` before the use case is invoked.
- **F7.** When `page` is omitted from the request, it defaults to `1`.
- **F8.** When `items_per_page` is omitted from the request, it defaults to `10`.
- **F9.** The row offset applied in the adapter query equals
  `(query.page - 1) * query.items_per_page`.
- **F10.** `total_count` reflects the total number of non-deleted users in the
  database, not only the number of items on the current page.
- **F11.** `ListUsersUseCase.__call__` returns exactly the `UserPage` returned by
  `ListUsersPort.list`; it performs no transformation on the value.
- **F12.** `ListUsersPort` is decorated with `@runtime_checkable`, so
  `isinstance(adapter, ListUsersPort)` returns `True` for any structurally
  compatible adapter instance.
- **F13.** `ListUsersAdapter` explicitly names `ListUsersPort` as its base class
  in the class declaration.
- **F14.** The adapter issues no `try/except` block; any infrastructure exception
  escapes the adapter unchanged and propagates to the global exception handler.

## Non-functional requirements

- **N1.** `ListUsersUseCase` is a class with `__call__()`; it is called as
  `await use_case(query)`. Per `agent_docs/architecture.md` § Use-case shape.
- **N2.** The adapter catches no exceptions — the list operation has no
  business-meaningful infrastructure failure path; all unexpected exceptions
  propagate to the global `_catch_all` handler. Per `agent_docs/error_handling.md`
  § Right shape: read-only query, no catch.
- **N3.** Pydantic schemas that may be validated from ORM instances carry
  `model_config = ConfigDict(from_attributes=True)`. Per `CLAUDE.md`.
- **N4.** Every new file starts with `# FEATURE: list_users — <purpose>` on
  line 1. Per `agent_docs/stable_vs_feature.md`.
- **N5.** No `HTTPException` is raised inside `ListUsersUseCase`. Per `CLAUDE.md`.
- **N6.** No file in `list_users/` imports from another slice's `domain/`,
  `data/`, or `presentation/` layer. Per `agent_docs/architecture.md` § Layer
  rules.
- **N7.** All I/O in the adapter is `async def` + `await`; no synchronous
  database calls. Per `CLAUDE.md`.
- **N8.** `mypy src/app` (strict) passes with no new errors introduced by this
  slice. Per `CLAUDE.md`.
- **N9.** `ruff format src/app` and `ruff check src/app` pass with no new
  violations. Per `CLAUDE.md`.
- **N10.** `ListUsersPort` uses `@runtime_checkable` and inherits from
  `typing.Protocol`. Per `agent_docs/architecture.md` § Port pattern.
- **N11.** `ListUsersAdapter` explicitly inherits from `ListUsersPort` in the
  class declaration. Per `agent_docs/architecture.md` § Adapter pattern.
- **N12.** All imports inside `src/app/` use relative imports; no absolute
  `app.*` imports appear in the new source files. Per `agent_docs/architecture.md`
  § Import conventions.

## Out of scope

- Caching the list endpoint.
- Filtering or search by name, username, or email.
- Sorting or cursor-based pagination.
- Listing soft-deleted users (separate admin use case).
- Authentication / authorization on `GET /users`.
- Migrating `create_user`'s router to the `Provide[...]` DI pattern.
- Changes to any other use case in the `users` feature.
- Alembic migrations — no ORM or schema changes.

## Traceability

| Requirement | Verified by |
|---|---|
| F1, F2, F3 | endpoint integration test — happy path; outside-in test |
| F4 | adapter unit test — soft-delete filter; endpoint integration test |
| F5, F6 | endpoint integration test — 422 on invalid params |
| F7, F8 | endpoint integration test — default param values |
| F9 | adapter unit test — offset calculation (page 2, items_per_page 5) |
| F10 | adapter unit test — total_count vs current-page size |
| F11 | use-case unit test — return-value passthrough |
| F12 | adapter unit test — `isinstance` assertion; code review |
| F13 | code review checklist in `validation.md` |
| F14 | adapter unit test — infrastructure exception propagation |
| N1–N12 | code review checklist in `validation.md` |
