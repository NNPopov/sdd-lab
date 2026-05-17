# 0010 · list_all_posts — Outside-in test spec

## Goal

Prove that `GET /api/v1/posts` returns a paginated, newest-first list of all
non-deleted posts from all non-deleted users — without any auth token — with
correct response shape, author username resolution, and pagination metadata.

## Entry point

- **Method:** `GET`
- **Path:** `/api/v1/posts`
- **Query params:** `page` and `items_per_page` (optional; defaults 1 and 10).
- **Auth:** none — no Authorization header.

## Wired real

- FastAPI app from `create_app()` (full stack: middleware, exception handlers).
- `ListAllPostsAdapter` (SQLAlchemy JOIN against the test Postgres).
- `ListAllPostsPort` (bound to the adapter in `Container`).
- `ListAllPostsUseCase`.
- Test Postgres via the `db_session` fixture (transaction rollback per test).
- DI container with `session_factory` overridden to use the test transaction.

## Mocked

None — the test runs entirely against the test database. Redis is not mocked;
the `@cache` decorator is exercised as-is (cache misses are acceptable in the
test environment).

## Fixtures used

- `client` (from `tests/conftest.py`): `httpx.AsyncClient` against the app.
- `db_session`: the per-test Postgres transaction (rolls back on teardown).
- `seed_users_and_posts` (in `tests/features/posts/0010_list_all_posts/conftest.py`):
  creates the following rows in the test DB:
  - User `alice` (not deleted).
  - User `bob` (not deleted).
  - Post "Oldest Post" authored by `alice`, `created_at` = T−120s.
  - Post "Middle Post" authored by `bob`, `created_at` = T−60s.
  - Post "Newest Post" authored by `alice`, `created_at` = T (most recent).
  All three posts have `is_deleted = false`.

## Test scenarios

### Scenario 1: happy path — all posts, newest-first, correct usernames

**Setup:**

- DB seeded by `seed_users_and_posts`: three posts across two authors at
  distinct timestamps.

**Act:**

- `GET /api/v1/posts` with no query parameters and no Authorization header.

**Expect:**

- Status: `200`.
- Response body shape matches `ListAllPostsResponse`:
  - `total_count == 3`.
  - `page == 1`.
  - `items_per_page == 10`.
  - `items` is a list of 3 objects.
- Each item contains `id`, `title`, `text`, `media_url`, `created_at`,
  `created_by_user_id`, and `username`.
- Items are ordered newest-first:
  - `items[0].title == "Newest Post"` and `items[0].username == "alice"`.
  - `items[1].title == "Middle Post"` and `items[1].username == "bob"`.
  - `items[2].title == "Oldest Post"` and `items[2].username == "alice"`.
- `username` is resolved from the `user` table via JOIN — the value is the
  actual stored username, not derived from any request parameter.

**Covers requirement(s):** F1, F2, F3, F4, F5, F11, F14, F16.

---

### Scenario 2: invalid pagination parameter returns 422

**Setup:**

- DB seeded by `seed_users_and_posts` (state does not matter; the error is
  raised before any DB query).

**Act:**

- `GET /api/v1/posts?page=0` (page below minimum of 1).

**Expect:**

- Status: `422`.
- Response body is a Pydantic validation error that references the `page`
  field.

**Covers requirement(s):** F12.

---

## Out of scope for this test

- Empty database scenario (covered by endpoint integration test and adapter
  unit test).
- `items_per_page` boundary validation — `0` and `101` (covered by endpoint
  integration test).
- Soft-delete filtering for posts and users (covered by adapter unit test and
  endpoint integration test).
- Pagination offset correctness beyond the default page (covered by adapter
  unit test).
- Cache TTL and Redis key structure (covered by endpoint integration test).
- Branches inside the use-case (delegation only; covered by use-case unit
  test).
- Performance, load, concurrency.
