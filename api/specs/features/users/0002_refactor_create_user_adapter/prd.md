# PRD — Refactor create_user Adapter and Port (Slice 0002)

## Problem Statement

The `create_user` adapter (slice 0001) was implemented with an overengineered
error-handling pattern that violates the project's architectural rules:

- `email_exists` and `username_exists` wrap bare SELECT queries in a double
  try/except that catches all exceptions and re-raises them as
  `UnknownDomainError`. There is no business-meaningful exception to translate
  at those sites — the wrapping is pure noise that obscures the real failure and
  breaks the rule "adapter catches only business-meaningful infrastructure
  exceptions."
- `create` also wraps its entire session block in an outer `except Exception`
  that logs and re-raises as `UnknownDomainError`. The project's global
  exception handler in `adapters/http/exception_handlers.py` already handles
  unexpected infrastructure errors by returning HTTP 500 and logging them.
  Duplicating that behaviour inside the adapter adds no value.
- `CreateUserAdapter` does not explicitly inherit from `CreateUserPort`. The
  project rule requires `class Adapter(Port):` so the port→adapter binding is
  greppable and enforced at class-definition time.
- `CreateUserPort` is not decorated with `@runtime_checkable`. Every port in
  this project must carry the decorator so that `isinstance(adapter, Port)` is
  usable for diagnostics and DI container validation.

## Solution

Refactor the adapter and port to conform to the project's established rules:

- Remove all try/except from `email_exists` and `username_exists`. Unknown
  infrastructure errors propagate unmodified to the global exception handler.
- In `create`, keep exactly one try/except scoped to `session.commit()`. It
  catches `IntegrityError` and translates it to `DuplicateValueDomainError`.
  No outer catch, no `UnknownDomainError`, no adapter-level logging.
- Change `class CreateUserAdapter:` to `class CreateUserAdapter(CreateUserPort):`.
- Add `@runtime_checkable` to `CreateUserPort`.
- Remove the now-unused `structlog` import and `UnknownDomainError` import from
  the adapter.

No behaviour visible to API clients changes. The only observable difference is
that unexpected infrastructure failures in `email_exists` and `username_exists`
will now reach the global handler directly instead of being wrapped in
`UnknownDomainError` first — which is the correct outcome.

## User Stories

1. As a developer, I want `email_exists` and `username_exists` to be bare async
   methods without try/except so that unexpected infrastructure errors surface
   with their original type and stack trace at the global handler, making
   incidents easier to diagnose.
2. As a developer, I want the adapter's `create` method to catch `IntegrityError`
   only at the `session.commit()` call site so that the exception mapping is
   co-located with the only operation that can actually raise it.
3. As a developer, I want the adapter to not catch unexpected exceptions so that
   the global handler in `exception_handlers.py` is the single place responsible
   for logging and returning HTTP 500, avoiding duplicated responsibilities.
4. As a developer, I want `CreateUserAdapter` to explicitly inherit from
   `CreateUserPort` so that the port→adapter binding is visible and greppable
   in the class definition.
5. As a developer, I want `CreateUserPort` to carry `@runtime_checkable` so that
   `isinstance(adapter, CreateUserPort)` works for diagnostics and DI container
   assertions without requiring a structural check at runtime.
6. As a developer, I want dead imports (`structlog`, `UnknownDomainError`) removed
   from the adapter so that the import list reflects only what the file actually
   uses.

## Implementation Decisions

### Modules to modify

- **`create_user` port** — add `@runtime_checkable` decorator and add
  `runtime_checkable` to the `typing` import.
- **`create_user` adapter** — three changes:
  1. Strip double try/except from `email_exists` and `username_exists`, leaving
     the session query as the only statement in each method.
  2. Narrow `create`'s try/except to wrap only `session.commit()`. The
     `session.add()` and `session.refresh()` calls are outside the try block.
  3. Change the class declaration to inherit explicitly from `CreateUserPort`.
  4. Remove the `structlog`, `logger`, and `UnknownDomainError` imports.

### Error-handling contract (post-refactor)

| Method | Exception caught | Translated to | Propagates unchanged |
|---|---|---|---|
| `email_exists` | — | — | All |
| `username_exists` | — | — | All |
| `create` | `IntegrityError` at commit | `DuplicateValueDomainError` | Everything else |

### No schema or migration changes

This refactor touches only Python source files. No ORM models, no Alembic
migrations, no API contract changes.

## Testing Decisions

Good tests verify observable behaviour, not implementation details. A test
should assert on exception types and return values, not on whether a specific
internal method was called or a log line was emitted.

### Adapter unit tests (primary target)

The adapter is the only changed module with testable logic. Tests use a mocked
`async_sessionmaker` / `AsyncSession`. Assert:

- `email_exists` returns `True` when the query finds a matching row.
- `email_exists` returns `False` when no row is found.
- `username_exists` returns `True` / `False` symmetrically.
- `email_exists` and `username_exists` do **not** catch arbitrary exceptions —
  verified by asserting that a non-DomainError raised by the session propagates
  unchanged with its original type.
- `create` returns a `CreatedUser` on success.
- `create` raises `DuplicateValueDomainError` when `session.commit()` raises
  `IntegrityError`.
- `create` does **not** catch non-`IntegrityError` exceptions from `commit` —
  verified by asserting the original exception type is re-raised.

### No new use-case or endpoint tests

The use case and router are unchanged. Existing tests for those layers must
continue to pass without modification.

## Out of Scope

- Changing the use case logic or domain commands.
- Changing the presentation layer (router, schemas).
- Adding caching or rate limiting.
- Refactoring any other slice's adapter.
- Modifying `app/domain/errors.py` — no new `DomainError` subclasses are needed.

## Further Notes

- The global exception handler at `adapters/http/exception_handlers.py` already
  logs unexpected errors with `exc_info=True` and returns HTTP 500. Removing
  the adapter-level logging does not reduce observability.
- `UnknownDomainError` is defined in `app/domain/errors.py` and remains there;
  it is simply not used by this adapter after the refactor.
- After the refactor, `isinstance(adapter, CreateUserPort)` will return `True`
  due to `@runtime_checkable` and structural compatibility.
