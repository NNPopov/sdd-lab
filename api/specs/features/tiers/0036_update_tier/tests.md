# 0036 · update_tier — Outside-in test spec

## Goal

Prove that a superuser can rename an existing tier through `PATCH /api/v1/tier/{name}`,
that the database row is updated and the old name is gone, and that attempting to rename
to a name already taken by another tier returns HTTP 409 via the full exception-handler
chain.

## Entry point

- **Method:** `PATCH`
- **Path:** `/api/v1/tier/{name}` — where `name` is the path parameter holding the current tier name
- **Body:** `{"new_name": "<new_tier_name>"}`
- **Auth:** Bearer token for a superuser (applied via `Authorization` header)

## Wired real

- FastAPI app from `create_app()` (full stack: middleware, exception handlers).
- `UpdateTierAdapter` — executes real SQL against the test Postgres.
- `UpdateTierPort` — bound to `UpdateTierAdapter` via `Container`.
- `UpdateTierUseCase` — called by the router through DI.
- Test Postgres via the `async_client` fixture (savepoint-mode transaction rollback per test).
- DI container with `session_factory` overridden to the test-transaction session factory, so
  adapter writes and test-side assertions share the same savepoint.

## Mocked

None — the test runs entirely against the test database. There are no external HTTP calls,
no Redis touches, and no clock dependency in this slice.

## Fixtures used

- `async_client` (from slice `conftest.py`): `httpx.AsyncClient` wired to the app with
  savepoint-mode rollback. Defined following the canonical pattern in `agent_docs/testing.md`.
- **Superuser token fixture** (shared or slice-level): obtains a valid Bearer token for a
  superuser account. Either inject the header directly via a helper that calls
  `POST /api/v1/login`, or use an existing `superuser_token` fixture from the project's
  shared conftest.
- Inline DB seeding via `_di_container.session_factory()()` using raw SQL (`sqlalchemy.text`):
  inserts the required tier rows inside the savepoint transaction before each scenario.

## Test scenarios

### Scenario 1: happy path — successful rename

**Setup:**

- DB contains one tier row: `name="silver"`, `updated_at=NULL` (or any prior timestamp).
- Superuser Bearer token at hand.

**Act:**

- `PATCH /api/v1/tier/silver` with body `{"new_name": "platinum"}` and the superuser token.

**Expect:**

- Status: `200`.
- Response body: `{"message": "Tier updated"}`.
- DB state after the call (asserted via raw SQL on the same session factory):
  - A row exists with `name="platinum"` and a non-null `updated_at` timestamp.
  - No row exists with `name="silver"` (the old name is gone).

**Covers requirements:** F1, F5, F8, F9, F14.

---

### Scenario 2: duplicate name — new name already taken

**Setup:**

- DB contains two tier rows: `name="silver"` and `name="gold"`.
- Superuser Bearer token at hand.

**Act:**

- `PATCH /api/v1/tier/silver` with body `{"new_name": "gold"}` and the superuser token.

**Expect:**

- Status: `409`.
- Response body: `{"error": {"code": "duplicatevalue", "message": "Tier name already exists"}}`.
- DB state: both `"silver"` and `"gold"` rows are unchanged (the rename did not commit).

**Covers requirements:** F10, F11, F15.

---

## Out of scope for this test

- Field-level validation errors (missing `new_name`, empty string) — covered by the endpoint
  integration test (F2).
- Authentication and authorization failures (401, 403) — covered by the endpoint integration
  test (F3, F4).
- The not-found path (HTTP 404) — covered by the endpoint integration test (F7) and the
  use-case unit test (F6).
- Verifying that `port.update` is never called when the tier is not found — covered by the
  use-case unit test (F6).
- Verifying that non-`IntegrityError` exceptions propagate unchanged — covered by the adapter
  unit test (F16).
- `get` having no `try/except` — covered by code review (F17).
- Performance, load, concurrency.
