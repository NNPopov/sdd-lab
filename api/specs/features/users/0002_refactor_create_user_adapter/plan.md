# 0002 · refactor_create_user_adapter — Implementation plan

## 1. Header

- **Feature:** users
- **Slice:** 0002_refactor_create_user_adapter
- **PRD:** ./prd.md
- **Reference slice:** ../0001_create_user/plan.md (same adapter and port files)
- **HTTP path:** none — this is a pure refactor with no API contract changes
- **STABLE files touched:** none

## 2. Context summary

Slice 0001 produced a working `create_user` adapter and port, but both files
were generated with patterns that violate the current project rules: the adapter
uses a double try/except that wraps read-only queries and re-raises unknown
exceptions as `UnknownDomainError`, the adapter class does not explicitly
inherit from its port, and the port lacks `@runtime_checkable`. This slice
corrects those issues in place. No new files are created, no API contract
changes, no migrations required.

## 3. API contract

No changes. The public API (`POST /api/v1/user`) is unchanged. All request
fields, response fields, and status codes remain identical to slice 0001.

The only change observable in production is that unexpected infrastructure
errors in `email_exists` and `username_exists` now propagate with their
original type and full stack trace to the global `_catch_all` handler, instead
of being wrapped in `UnknownDomainError` first. The HTTP response (500) is the
same in both cases.

## 4. File structure

No new files. Two existing files are modified:

```
src/app/features/users/create_user/
├── domain/
│   └── ports/
│       └── create_user_port.py   ← add @runtime_checkable
└── data/
    └── adapter.py                ← remove dead error-handling, add port inheritance
```

## 5. Implementation steps

1. **Port — add `@runtime_checkable`.**
   In `create_user_port.py`, add `runtime_checkable` to the `typing` import
   and place `@runtime_checkable` on the line immediately before
   `class CreateUserPort(Protocol):`. Verify: `mypy src/app` must pass;
   `isinstance(CreateUserAdapter(...), CreateUserPort)` must return `True`.

2. **Adapter — clean imports.**
   In `adapter.py`, remove the `structlog` import, the `logger = ...` line,
   and `UnknownDomainError` from the `domain.errors` import. Add an import of
   `CreateUserPort` from `..domain.ports.create_user_port`.
   Verify: `ruff check src/app` reports no unused imports.

3. **Adapter — fix class declaration.**
   Change `class CreateUserAdapter:` to `class CreateUserAdapter(CreateUserPort):`.
   Verify: `mypy src/app` confirms structural compatibility between the class
   and the protocol.

4. **Adapter — strip `email_exists` try/except.**
   Replace the entire body of `email_exists` with the bare session block:
   open a session, execute the SELECT, return `scalar_one_or_none() is not None`.
   No try/except. Per `agent_docs/error_handling.md` — read-only queries have
   no business-meaningful exception to translate.

5. **Adapter — strip `username_exists` try/except.**
   Same transformation as step 4, applied to `username_exists`.

6. **Adapter — narrow `create` try/except.**
   Restructure the `create` method body so that `session.add(user)` is outside
   the try block, the `try` wraps only `await session.commit()`, the `except
   IntegrityError` maps to `DuplicateValueDomainError` with `from exc`, and
   `await session.refresh(user)` and the return statement are outside the try
   block. Remove the outer `except Exception` block entirely.
   Per `agent_docs/error_handling.md` — `session.add` cannot raise
   `IntegrityError`; the commit is the only site worth catching.

7. **Verify.**
   Run in order:
   ```
   ruff format src/app
   ruff check src/app
   mypy src/app
   pytest
   ```
   All four must pass before the slice is considered done.

## 6. Tests planned

### Adapter unit tests — `tests/features/users/0002_refactor_create_user_adapter/data/test_adapter.py`

These are the only new tests. Mock `async_sessionmaker` and `AsyncSession`.
Assert:

- `email_exists` returns `True` when the query result contains a row.
- `email_exists` returns `False` when the query result is empty.
- `username_exists` returns `True` / `False` symmetrically.
- `email_exists` propagates a non-`DomainError` exception unchanged (assert
  the original exception type is re-raised, not wrapped).
- `username_exists` propagates a non-`DomainError` exception unchanged.
- `create` returns a `CreatedUser` on success.
- `create` raises `DuplicateValueDomainError` when `session.commit()` raises
  `IntegrityError`.
- `create` propagates a non-`IntegrityError` exception from `commit` unchanged.

**Opt-outs:**

- **Use-case unit tests** — skipped. The use-case class is unchanged; its
  existing tests (from slice 0001) already cover all branches.
- **Endpoint integration tests** — skipped. The router and schemas are
  unchanged; existing integration tests from slice 0001 already cover the
  full HTTP stack.
- **Outside-in test** — skipped. No behavior change is introduced; the
  outside-in test from slice 0001 remains the acceptance gate for the
  `create_user` slice.

## 7. Out of scope for this slice

- Changing the use-case logic, commands, or entities.
- Changing the presentation layer (router, schemas).
- Refactoring any other feature's adapter.
- Adding caching, rate limiting, or observability beyond what the global
  handler already provides.
- Modifying `app/domain/errors.py` — no new `DomainError` subclasses needed.
- Alembic migrations — no ORM or schema changes.

## 8. Open questions

None.
