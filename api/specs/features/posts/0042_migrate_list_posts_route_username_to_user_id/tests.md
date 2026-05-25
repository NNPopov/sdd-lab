# 0042 · migrate_list_posts_route_username_to_user_id — Outside-in test spec

## Goal

Prove that `GET /api/v1/{user_id}/posts` lists an author's posts keyed by the
author's integer primary key — returning only `approved` posts to the public,
all non-deleted posts to the authenticated owner — and that the old
`/{username}/posts` URL no longer resolves (a string path segment yields 422).

## Entry point

- **Method:** `GET`
- **Path:** `/api/v1/{user_id}/posts`
- **Body:** none
- **Auth:** optional. Owner identity is taken from `get_optional_user`
  (returns a dict with an `"id"` key). Unauthenticated requests get the public
  view; the owner (`optional_user["id"] == user_id`) gets the author view.

## Wired real

- FastAPI app from `create_app()` (full stack: middleware, exception handlers).
- `ListPostsAdapter` (runs the `SELECT … JOIN User` against the test Postgres).
- `ListPostsPort` (bound to `ListPostsAdapter` in `Container`).
- `ListPostsUseCase` (pass-through to the port).
- Test Postgres via the `async_client` fixture (savepoint transaction rollback per test).
- DI container with `session_factory` overridden to use the test transaction.

## Mocked

- **Redis client (`@cache` decorator):** patched via `app.adapters.cache.redis_cache.client = AsyncMock()` with `get.return_value = None` (always a cache miss), so the cache decorator does not raise `MissingClientError`. Cache-key behaviour is verified by the endpoint integration test, not here.
- For the author-view scenario, `app.shared_dependencies.get_optional_user` is overridden via `app.dependency_overrides` to return `{"id": <author_id>, "username": "<author_username>"}`. This is a FastAPI dependency override, not a mock of the slice's own port/use-case/adapter.

No external HTTP APIs are involved.

## Fixtures used

- `oit_engine` (slice `conftest.py`): per-test async engine; ensures schema exists.
- `async_client` (slice `conftest.py`): `httpx.AsyncClient` with `ASGITransport`, `session_factory` overridden to the savepoint transaction, Redis mocked.
- `seeded_author` (slice `conftest.py`): inserts one `User` (`username="alicepost"`, `email="alicepost@example.com"`, `hashed_password="hashed_pw"`, `is_deleted=False`) through the overridden session factory and returns the row (with `.id`).
- `seeded_author_posts` (slice `conftest.py`): inserts two `Post` rows for `seeded_author` — one `status="approved"` (`title="Approved Post"`) and one `status="pending"` (`title="Pending Post"`), both `is_deleted=False` — and returns them.

## Test scenarios

### Scenario 1: happy path — public view lists only approved posts by integer ID

**Setup:**

- DB contains `seeded_author` (`id = author_id`) with one `approved` post and one `pending` post (`seeded_author_posts`).
- No `Authorization` header is sent (unauthenticated → public view).
- Redis mocked (cache miss).

**Act:**

- `await async_client.get(f"/api/v1/{author_id}/posts")`

**Expect:**

- Status: `200`.
- Body top-level keys are exactly `{"items", "total_count", "page", "items_per_page"}`.
- `total_count == 1`, `page == 1`, `items_per_page == 10`, `len(items) == 1`.
- The single item has `status == "approved"`, `created_by_user_id == author_id`, and `username == "alicepost"` (resolved via the `User` JOIN, not echoed from the URL).
- The `pending` post is absent.

**Covers requirement(s):** F1, F3, F8, F9, F11, F18.

### Scenario 2: author view — owner sees the non-approved post

**Setup:**

- Same DB seeding as Scenario 1.
- `get_optional_user` overridden to return `{"id": author_id, "username": "alicepost"}` (simulates the authenticated owner). Override removed in a `finally` block.
- Redis mocked (cache miss).

**Act:**

- `await async_client.get(f"/api/v1/{author_id}/posts")`

**Expect:**

- Status: `200`.
- `total_count == 2`, `len(items) == 2`.
- The set of returned `status` values is `{"approved", "pending"}` (the owner sees the non-approved post).
- Every item has `created_by_user_id == author_id` and `username == "alicepost"`.

**Covers requirement(s):** F4, F15, F16.

### Scenario 3: old route gone — string path segment yields 422

**Setup:**

- No seeding required.

**Act:**

- `await async_client.get("/api/v1/alicepost/posts")` (the author's username string in the path).

**Expect:**

- Status: `422` (FastAPI cannot bind the non-integer segment to the `int`-typed `user_id` path parameter).

**Covers requirement(s):** F2, F10.

## Out of scope for this test

- Non-author authenticated view returning only approved posts (F5) — covered by the endpoint integration test.
- Empty result for an existing user (F6) and unknown `user_id` → empty (F7) — covered by the endpoint integration test and adapter unit test.
- `is_author` boolean branch when `requester_user_id is None` (F12) and soft-deleted-author count/rows consistency (F13) — covered by the adapter and use-case unit tests.
- Cache key prefix / `resource_id_name` behaviour (F17) — covered by the endpoint integration test.
- Pagination across multiple pages beyond the default envelope values — covered by the endpoint integration test.
- Performance, load, concurrency.
