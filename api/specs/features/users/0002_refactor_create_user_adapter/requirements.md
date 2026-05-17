# 0002 · refactor_create_user_adapter — Requirements

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md

## Functional requirements

- **F1.** `email_exists` returns `True` when a `User` row with a matching
  `email` value exists in the database.
- **F2.** `email_exists` returns `False` when no `User` row with a matching
  `email` value exists in the database.
- **F3.** `email_exists` propagates any exception that is not a `DomainError`
  subclass unchanged — it does not catch, wrap, or re-raise under a different
  type.
- **F4.** `username_exists` returns `True` when a `User` row with a matching
  `username` value exists in the database.
- **F5.** `username_exists` returns `False` when no `User` row with a matching
  `username` value exists in the database.
- **F6.** `username_exists` propagates any exception that is not a `DomainError`
  subclass unchanged.
- **F7.** `create` returns a `CreatedUser` entity populated from the persisted
  ORM model on success.
- **F8.** `create` raises `DuplicateValueDomainError` (with cause chained via
  `from exc`) when `session.commit()` raises `IntegrityError`.
- **F9.** `create` propagates any exception other than `IntegrityError` raised
  by `session.commit()` unchanged — it does not wrap it in any `DomainError`
  subclass.
- **F10.** `CreateUserPort` is decorated with `@runtime_checkable`, so
  `isinstance(adapter, CreateUserPort)` returns `True` for any structurally
  compatible adapter instance.
- **F11.** `CreateUserAdapter` explicitly names `CreateUserPort` as its base
  class in the class declaration.

## Non-functional requirements

- **N1.** The adapter catches only business-meaningful infrastructure
  exceptions at the exact call site where they can occur; it does not use a
  broad `except Exception` block. Per `agent_docs/error_handling.md`.
- **N2.** The adapter does not log exceptions. Logging of unexpected errors is
  the sole responsibility of the global `_catch_all` exception handler in
  `adapters/http/exception_handlers.py`. Per `agent_docs/error_handling.md`.
- **N3.** `UnknownDomainError` is not used in the adapter. Unknown failures
  are not domain concerns and must not be modelled as `DomainError` subclasses.
  Per `agent_docs/error_handling.md`.
- **N4.** Both modified files retain their `# FEATURE: create_user — ...`
  header on line 1. Per `agent_docs/stable_vs_feature.md`.
- **N5.** No STABLE files are modified as part of this slice. Per
  `agent_docs/stable_vs_feature.md`.
- **N6.** The port uses `@runtime_checkable` and inherits from
  `typing.Protocol`. Per `agent_docs/architecture.md` § Port pattern.
- **N7.** The adapter class explicitly inherits from its port in the class
  declaration. Per `agent_docs/architecture.md` § Adapter pattern.
- **N8.** All I/O in the adapter is `async def` + `await`; no synchronous
  database calls. Per `CLAUDE.md`.
- **N9.** `mypy src/app` (strict) passes with no new errors introduced by this
  slice. Per `CLAUDE.md`.
- **N10.** `ruff format src/app` and `ruff check src/app` pass with no new
  violations. Per `CLAUDE.md`.

## Out of scope

- Changes to the use-case logic, domain commands, or entities.
- Changes to the presentation layer (router, schemas).
- Refactoring any other slice's adapter or port.
- Caching, rate limiting, or observability additions.
- New `DomainError` subclasses in `app/domain/errors.py`.
- Alembic migrations — no ORM or schema changes.

## Traceability

| Requirement | Verified by |
|---|---|
| F1, F2 | adapter unit test — `email_exists` happy-path cases |
| F3 | adapter unit test — `email_exists` propagation case |
| F4, F5 | adapter unit test — `username_exists` happy-path cases |
| F6 | adapter unit test — `username_exists` propagation case |
| F7 | adapter unit test — `create` success case |
| F8 | adapter unit test — `create` IntegrityError mapping |
| F9 | adapter unit test — `create` non-IntegrityError propagation |
| F10 | adapter unit test — `isinstance` assertion; code review |
| F11 | code review checklist in `validation.md` |
| N1–N10 | code review checklist in `validation.md` |
