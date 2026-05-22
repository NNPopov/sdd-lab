# 0032 · extract_user_lookup — Outside-in test spec

## Goal

Confirm that user resolution through `UserLookupAdapter` is correct in isolation,
and that all four affected post endpoints continue to behave identically to their
pre-refactor state.

## Outside-in test: opt-out rationale

This slice introduces **no user-visible behavior change** and **no new HTTP entry
point**. The PRD explicitly states:

> "No new outside-in test is written for this slice because no user-visible
> behavior changes."

The acceptance gate for the refactor is the four **existing** outside-in tests,
which exercise the full HTTP stack of each affected endpoint end-to-end:

| Existing test file | Endpoint exercised | Acceptance signal |
|---|---|---|
| `tests/features/posts/0011_create_post/create_post_outside_in_test.py` | `POST /{username}/post` | Green |
| `tests/features/posts/0028_update_post/update_post_outside_in_test.py` | `PATCH /{username}/post/{id}` | Green |
| `tests/features/posts/0029_erase_post/erase_post_outside_in_test.py` | `DELETE /{username}/post/{id}` | Green |
| `tests/features/posts/0030_erase_db_post/erase_db_post_outside_in_test.py` | `DELETE /{username}/db_post/{id}` | Green |

Run command:

```
pytest tests/features/posts/ -k "outside_in" -v
```

All four must be green **without modifying the test files themselves**. Any
regression in any of the four is a blocking failure for this slice.

---

## New test: `UserLookupAdapter` unit test

This is the only new automated test file introduced by this slice. It validates
the correctness of `UserLookupAdapter` in isolation. The four use-case unit tests
are **updated** (not new) and are documented in the section below.

### File location

`tests/features/posts/0032_extract_user_lookup/data/test_user_lookup_adapter.py`

### Entry point

Direct call to `UserLookupAdapter.get_active_user_by_username(username)` with a
mocked async session factory. Not an HTTP test.

### Wired real

- `UserLookupAdapter` (the class under test).
- `UserLookupPort` (used as the spec for `isinstance` verification).

### Mocked

- `async_sessionmaker[AsyncSession]` — replaced with `AsyncMock` that returns a
  mocked `AsyncSession` context manager.
- `session.execute(...)` — configured to return a mock result per scenario.
- No Postgres, no FastAPI app, no HTTP client.

### Fixtures used

- `mocker` (from `pytest-mock`): creates `AsyncMock` instances for the session
  factory and session.
- No slice-specific `conftest.py` fixtures needed.

### Test scenarios

#### Scenario 1: active user found → `UserIdentity` returned

**Setup:**

- `session.execute(...)` returns a mock result where `scalar_one_or_none()` returns
  a `User` ORM object with `id=42`, `username="alice"`, `is_deleted=False`.

**Act:**

- Call `await adapter.get_active_user_by_username("alice")`.

**Expect:**

- Return value is a `UserIdentity` instance with `id=42` and `username="alice"`.
- `session.execute` was called once. The SQL expression targets
  `User.username == "alice"` and `User.is_deleted.is_(False)`.

**Covers requirement(s):** F5, F6.

---

#### Scenario 2: username does not exist → `None` returned

**Setup:**

- `session.execute(...)` returns a mock result where `scalar_one_or_none()` returns
  `None`.

**Act:**

- Call `await adapter.get_active_user_by_username("ghost")`.

**Expect:**

- Return value is `None`.

**Covers requirement(s):** F7.

---

#### Scenario 3: user exists but is soft-deleted → `None` returned

**Setup:**

- `session.execute(...)` returns a mock result where `scalar_one_or_none()` returns
  `None` (the filter `is_deleted = False` excludes the row, so the query itself
  returns nothing).

**Act:**

- Call `await adapter.get_active_user_by_username("deleted_user")`.

**Expect:**

- Return value is `None`.

**Covers requirement(s):** F8.

*Note: the filter is applied inside the SQL query, not in Python. The mock simulates
the DB returning nothing because the `is_deleted = False` predicate excluded the
row.*

---

#### Scenario 4: infrastructure exception propagates unchanged

**Setup:**

- `session.execute(...)` raises `sqlalchemy.exc.OperationalError` (simulates a DB
  connection failure).

**Act:**

- Call `await adapter.get_active_user_by_username("alice")`.

**Expect:**

- `OperationalError` propagates out of the adapter unchanged (not caught, not
  translated). No `DomainError` is raised.

**Covers requirement(s):** N3 (adapter contains no `try/except` for read-only
queries; per `agent_docs/error_handling.md`).

---

## Updated tests: use-case unit tests (four files)

These are **updates to existing test files**, not new files. The `/slice-test-red`
skill generates only the new `UserLookupAdapter` test above; the use-case test
updates are part of implementation.

For each of the four slices, the existing use-case unit test must be updated to:

1. Replace the single `AsyncMock(spec=XPort)` with two mocks:
   `AsyncMock(spec=XPort)` (per-slice port) and
   `AsyncMock(spec=UserLookupPort)` (shared user lookup).
2. Replace calls to `port.get_user_by_username.return_value = ...` with
   `user_lookup.get_active_user_by_username.return_value = ...`.
3. Construct the use-case with both arguments:
   `XUseCase(port=mock_port, user_lookup=mock_user_lookup)`.

The test scenarios themselves (happy path, user not found, forbidden access) are
unchanged in intent; only the mock target moves from the per-slice port to
`UserLookupPort`.

Files to update:

- `tests/features/posts/0011_create_post/domain/test_use_case.py`
- `tests/features/posts/0028_update_post/domain/test_use_case.py`
- `tests/features/posts/0029_erase_post/domain/test_use_case.py`
- `tests/features/posts/0030_erase_db_post/domain/test_use_case.py`

---

## Out of scope for this test

- A new outside-in test file for this slice (opted out per PRD decision).
- Field-level validation errors (no new HTTP contract; existing endpoint integration
  tests cover this for each slice).
- Adapter unit tests for the four per-slice adapters (their `get_user_by_username`
  methods are deleted, not replaced; existing adapter tests remain valid for the
  remaining methods).
- Performance, load, concurrency.
