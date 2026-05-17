---
name: feature-tests
description: This skill should be used when the user wants to generate tests.md for a slice. Trigger when the user invokes /feature-tests, says "write outside-in test spec", or asks to describe the slice-level integration test in markdown form before any code is written. Use only after prd.md, plan.md, requirements.md, validation.md exist. Produces markdown specification only; does not write Python code.
disable-model-invocation: false
---

# feature-tests

Generate `tests.md` for a slice. The output is a **markdown specification** of
one outside-in integration test that exercises the slice end-to-end through
its HTTP entry point, with the real adapter, the test Postgres, and mocks only
at external system boundaries.

The Python implementation is produced separately by `/slice-test-red`. This
skill writes prose, not code.

## Process

### 1. Find the target slice

Same determination as in `/feature-validation`. Output:
`specs/features/<feature>/<NNNN>_<slice>/tests.md`.

### 2. Read the inputs

Read **all four** existing spec files:

- `prd.md` — overall behavior.
- `plan.md` — public surface (HTTP path, Request/Response schemas).
- `requirements.md` — functional requirements.
- `validation.md` — manual scenarios. The outside-in test typically covers the
  happy-path scenario plus the most important failure path.

Plus:

- `agent_docs/testing.md` — fixtures, mocking conventions, reference tests.
- `agent_docs/entry_points/fastapi.md` — for the HTTP-call shape.

If any of the four spec files is missing, stop and ask the user to create it.

### 3. Decide the test boundary

For this project, the outside-in test goes through the **full HTTP stack**:

- **Wired real:** FastAPI app (with all middleware and exception handlers),
  the slice's adapter, the test Postgres database with transaction rollback.
- **Mocked:** external HTTP APIs, Redis (sometimes — depends on slice), the
  clock (for time-dependent tests).

The test makes HTTP calls through `httpx.AsyncClient(transport=ASGITransport(app=app))`.
It does not call the use-case or adapter directly.

### 4. Write the file

Use this structure. Keep section names unchanged. Keep prose tight.

```markdown
# NNNN · slice_name — Outside-in test spec

## Goal

One sentence: what end-to-end slice behavior does this test prove?

## Entry point

The HTTP call the test makes.

- **Method:** `POST`
- **Path:** `/api/v1/users`
- **Body:** `CreateUserRequest`
- **Auth:** none / Bearer token / etc.

## Wired real

- FastAPI app from `create_app()` (full stack: middleware, exception handlers).
- The slice's adapter (`CreateUserAdapter`).
- The slice's port (`CreateUserPort`, bound to the adapter in `Container`).
- The slice's use-case (`CreateUserUseCase`).
- Test Postgres via the `db_session` fixture (transaction rollback per test).
- DI container with `session_factory` overridden to use the test transaction.

## Mocked

- **<External HTTP API name>:** patched with `mocker.patch("module.path")`.
  Returns `<shape>`.
- **<Redis client>:** patched if cache is touched. Returns `<shape>`.
- **Clock:** patched if time matters (use `freezegun` or `mocker.patch("time.time")`).
- **<Other external boundary>:** as needed.

If nothing external is touched, write "None — the test runs entirely against
the test database."

## Fixtures used

- `client` (from `tests/conftest.py`): the `httpx.AsyncClient` against the app.
- `db_session`: the per-test transaction.
- `<slice-specific factory fixture>` (in slice `conftest.py`): seeds required
  prerequisite rows (e.g. a tier row before creating a user). State explicit
  rows.

## Test scenarios

### Scenario 1: happy path

**Setup:**

- DB contains: <list any seed rows from fixtures>.
- Mocks configured: <list any explicit mock returns>.

**Act:**

- `await client.post("/api/v1/users", json={"username": "alice", "email":
  "a@b.c", "password": "Pa$$w0rd"})`

**Expect:**

- Status: `201`.
- Response body matches `CreateUserResponse` shape with `username == "alice"`,
  `is_superuser == False`, `id` set.
- DB state: a row exists in `users` with `username == "alice"`.

**Covers requirement(s):** F1.

### Scenario 2: most important failure path

**Setup:**

- DB contains a user with `username == "alice"`.

**Act:**

- `await client.post("/api/v1/users", json={"username": "alice", ...})`

**Expect:**

- Status: `409`.
- Response body: `{"message": "Username or email already taken"}`.
- DB state: still exactly one row for `alice` (no duplicate created).

**Covers requirement(s):** F4.

## Out of scope for this test

- Field-level validation errors (covered by endpoint integration test).
- Specific SQLAlchemy exception variants (covered by adapter unit test).
- Branches inside the use-case beyond the two scenarios above (covered by
  use-case unit test).
- Performance, load, concurrency.
```

### 5. Save and confirm

Write to `specs/features/<feature>/<NNNN>_<slice>/tests.md`. Tell the user the
file was created, list the scenarios, and suggest:

> Next step: `/slice-test-red` to generate the failing Python test from this spec.

## Style rules

- **English only**.
- **Two scenarios is the default**: one happy path, one most-important failure
  path. Add a third only if a critical scenario cannot be covered by the
  endpoint integration test or the unit tests.
- **Concrete fixtures**: `username="alice"`, not `username=<some_value>`.
- **Exact response payloads**: write the literal `{"message": "..."}` the
  exception handler emits. If unsure, check
  `agent_docs/error_handling.md`.
- **Database assertions are part of the test.** "DB state: ..." is mandatory
  for any scenario that writes.

## What this file is NOT

- Not a Python file. No `def test_...`, no `await client.post(...)` as code,
  no `assert`. Those live in the Python file produced by `/slice-test-red`.
- Not a replacement for `validation.md`. validation.md is for manual scenarios
  and code review. tests.md is for one executable outside-in scenario set.
- Not a list of unit tests.

## Hard limits

- ❌ Writing Python code inside tests.md. The code goes in
  `*_outside_in_test.py`.
- ❌ Mocking the slice's own port, use-case, or adapter. Those are wired
  real. Mocking them defeats the outside-in principle.
- ❌ Skipping the "DB state" expectation for scenarios that write. Without
  it, the test cannot prove the side effect occurred.
- ❌ Including widget/UI assertions. There is no UI; the API contract is the
  HTTP response.

## Common mistakes

- ❌ Listing many failure scenarios. Pick the most important one. Other
  failures are covered by adapter unit tests and endpoint integration tests.
- ❌ Using a use-case call as the entry point ("Act: `await use_case(command)`").
  The entry point is HTTP. The test exercises the whole stack.
- ❌ Forgetting to specify auth setup for authenticated endpoints. Either
  list the bearer token fixture or note "auth: none."
- ❌ Mocking `session_factory` and asserting on its calls. The session
  factory is overridden to use the test transaction; tests should assert on
  DB state, not on the mock.
