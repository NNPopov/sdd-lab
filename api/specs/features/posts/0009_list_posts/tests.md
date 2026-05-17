# 0009 · list_posts — Outside-in test spec

## Goal

Prove that `GET /api/v1/{username}/posts` returns a paginated list of non-deleted
posts with the author's `username` populated via JOIN, and returns an empty
paginated response when the username does not exist.

## Entry point

- **Method:** `GET`
- **Path:** `/api/v1/{username}/posts`
- **Query params:** `page` (default 1), `items_per_page` (default 10)
- **Auth:** none

## Wired real

- FastAPI app from `create_app()` — full stack including middleware and exception
  handlers.
- `ListPostsAdapter` — executes the real JOIN query against the test Postgres.
- `ListPostsPort` — bound to `ListPostsAdapter` in `Container`.
- `ListPostsUseCase` — called by the presentation router.
- Test Postgres via the `db_session` fixture (transaction rollback per test).
- DI container with `session_factory` overridden to use the test transaction.

## Mocked

- **Redis cache:** the `@cache` decorator is patched to be a no-op so the test
  does not require a live Redis instance. Cache correctness is verified by the
  endpoint integration test.

## Fixtures used

- `client` (from `tests/conftest.py`): `httpx.AsyncClient` configured with
  `ASGITransport` and `session_factory` overridden to the test transaction.
- `db_session` (from `tests/conftest.py`): per-test async transaction, rolled
  back at teardown.
- `seeded_user` (slice `conftest.py`): inserts one `User` row directly into the
  test DB via `db_session`. Fields: `name="Alice"`, `username="alice"`,
  `email="alice@example.com"`, `hashed_password=<any bcrypt hash>`,
  `is_deleted=False`. Yields the inserted row's `id`.
- `seeded_posts` (slice `conftest.py`): inserts two `Post` rows into the test DB
  via `db_session`, both with `created_by_user_id=<seeded_user.id>`,
  `is_deleted=False`. First: `title="First Post"`, `text="Hello world."`.
  Second: `title="Second Post"`, `text="Another post."`. Yields a list of the
  two inserted rows.

## Test scenarios

### Scenario 1: happy path — user with posts returns paginated list with username

**Setup:**

- DB contains: one `User` row (`username="alice"`, `is_deleted=False`) and two
  `Post` rows (`created_by_user_id=alice.id`, both `is_deleted=False`).
  Provided by `seeded_user` and `seeded_posts` fixtures.
- Redis: cache decorator patched to no-op.

**Act:**

- `GET /api/v1/alice/posts` with no query parameters.

**Expect:**

- Status: `200`.
- Response body is a JSON object with:
  - `total_count == 2`
  - `page == 1`
  - `items_per_page == 10`
  - `items` is a list of 2 objects.
- Each item in `items` contains the fields `id`, `title`, `text`, `media_url`,
  `created_at`, `created_by_user_id`, and `username`.
- `username` in every item equals `"alice"` — resolved via the JOIN, not
  echoed from the URL path parameter.
- `created_by_user_id` in every item equals the seeded user's `id`.
- DB state: no rows were written or deleted (GET with no side effects).

**Covers requirement(s):** F1, F2, F3, F4, F9, F10, F15.

---

### Scenario 2: unknown username returns empty paginated response

**Setup:**

- DB contains: no user with `username="ghost"`.
- Redis: cache decorator patched to no-op.

**Act:**

- `GET /api/v1/ghost/posts` with no query parameters.

**Expect:**

- Status: `200`.
- Response body:
  - `total_count == 0`
  - `items == []`
  - `page == 1`
  - `items_per_page == 10`
- DB state: no rows were written or deleted.

**Covers requirement(s):** F5.

---

## Out of scope for this test

- Soft-deleted post and user exclusion (covered by the adapter unit test and
  endpoint integration test).
- Pagination offset and page-size boundary behaviour (covered by the endpoint
  integration test).
- `page < 1` and `items_per_page` out-of-range validation errors (covered by
  the endpoint integration test).
- Cache TTL and invalidation key compatibility (covered by the endpoint
  integration test, validation scenario S9 and S10).
- Performance, load, or concurrency.
