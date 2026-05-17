# 0003 · list_users — Outside-in test spec

## Goal

Prove that `GET /api/v1/users` returns a flat paginated list of non-deleted
users from the real database, with correct `total_count`, `page`, and
`items_per_page` metadata, and that soft-deleted users are silently excluded
from both `items` and `total_count`.

## Entry point

- **Method:** `GET`
- **Path:** `/api/v1/users`
- **Query params:** `page` (optional, default 1), `items_per_page` (optional,
  default 10)
- **Body:** none
- **Auth:** none

## Wired real

- FastAPI app from `create_app()` (full stack: middleware, exception handlers).
- `ListUsersAdapter` — issues two SQLAlchemy ORM queries against the test DB.
- `ListUsersPort` — bound to `ListUsersAdapter` in `Container`.
- `ListUsersUseCase` — delegates to the port.
- Test Postgres via the `db_session` fixture (transaction rollback per test).
- DI container with `session_factory` overridden to use the test transaction.

## Mocked

None — the slice issues read-only ORM queries against Postgres. No external
HTTP APIs, no Redis, no clock. The test runs entirely against the test
database.

## Fixtures used

- `client` (from `tests/conftest.py`): `httpx.AsyncClient` bound to the
  app with the test transaction session.
- `db_session` (from `tests/conftest.py`): per-test transaction, rolled back
  at teardown.
- `make_user` (in `tests/features/users/0003_list_users/conftest.py`): a
  factory coroutine that inserts a `User` ORM row directly into `db_session`
  and returns the inserted object. Accepts keyword overrides; defaults to
  deterministic values (`name="Test User"`, `username="user<n>"`,
  `email="user<n>@example.com"`, `hashed_password="hashed"`,
  `is_deleted=False`). Uses a counter to ensure unique usernames and emails
  across multiple calls within one test.

## Test scenarios

### Scenario 1: happy path — active users returned, deleted user excluded

**Setup:**

- Insert 3 active users via `make_user()` (is_deleted=False).
- Insert 1 soft-deleted user via `make_user(is_deleted=True, deleted_at=<now>)`.
- Total rows in DB (within this transaction): 4. Active: 3. Deleted: 1.

**Act:**

- `GET /api/v1/users` (no query params; uses defaults page=1,
  items_per_page=10).

**Expect:**

- Status: `200`.
- Response body is a JSON object with keys `items`, `total_count`, `page`,
  `items_per_page`.
- `total_count` equals `3` (soft-deleted user not counted).
- `page` equals `1`.
- `items_per_page` equals `10`.
- `items` is a list of exactly 3 elements.
- Each item has the fields `id`, `name`, `username`, `email`,
  `profile_image_url`, `tier_id`.
- The soft-deleted user's `username` does not appear in any element of
  `items`.

**Covers requirement(s):** F1, F2, F3, F4, F7, F8, F10.

---

### Scenario 2: pagination — correct offset and page metadata

**Setup:**

- Insert 7 active users via `make_user()` (is_deleted=False), numbered 1–7.

**Act:**

- `GET /api/v1/users?page=2&items_per_page=3`

**Expect:**

- Status: `200`.
- `total_count` equals `7`.
- `page` equals `2`.
- `items_per_page` equals `3`.
- `items` contains exactly 3 elements (users at offset 3, 4, 5 — i.e., the
  4th, 5th, and 6th inserted users).
- The first 3 and the 7th inserted users do not appear in `items`.

**Covers requirement(s):** F1, F9, F10.

## Out of scope for this test

- `page=0` or `items_per_page=101` validation errors — covered by the
  endpoint integration test (422 response from Pydantic, no DB interaction).
- Infrastructure failure returning 500 — covered by the adapter unit test
  (propagation assertion) and validation scenario S7.
- Use-case delegation logic — trivial; covered by the use-case unit test.
- The SQLAlchemy query structure (exact SQL issued) — a black box to the
  outside-in test; correctness is observed through the response, not inspected
  at the query level.
- Performance, load, concurrency.
