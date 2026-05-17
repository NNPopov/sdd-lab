# 0023 · expose_post_uuid — Outside-in test spec

## Goal

Prove that after creating a post, all four affected endpoints return `post_uuid`
as a valid UUID, and that the same `post_uuid` value is consistent across all
four responses for the same post.

## Entry points

This test exercises four existing endpoints sequentially within a single
scenario:

1. `POST /api/v1/{username}/post` — create a post (captures `post_uuid`).
2. `GET /api/v1/{username}/posts` — list user's posts.
3. `GET /api/v1/posts` — global feed.
4. `GET /api/v1/{username}/post/{id}` — single post read.

Auth: Bearer token obtained via `POST /api/v1/login` for the registered user.

## Wired real

- FastAPI app from `create_app()` (full stack: middleware, exception handlers).
- `ListPostsAdapter`, `ListAllPostsAdapter`, `CreatePostAdapter`.
- Their respective ports and use-cases.
- Test Postgres via the `db_session` fixture (transaction rollback per test).
- DI container with `session_factory` overridden to use the test transaction.
- `crud_posts` (FastCRUD) used by `read_post` in `posts/router.py`.

## Mocked

None — the test runs entirely against the test database. Redis cache is not
mocked; the test app does not activate caching in the test environment (or, if
it does, the single-request result is served from DB without a warm cache).

## Fixtures used

- `client` (from `tests/conftest.py`): `httpx.AsyncClient` against the app.
- `db_session` (from `tests/conftest.py`): per-test transaction for DB
  manipulation and rollback.
- No slice-specific fixture file is required — all setup is done inline via
  HTTP calls and direct DB manipulation using `db_session`.

## Test scenarios

### Scenario 1 — `post_uuid` present and consistent across all four endpoints

**Setup:**

- DB contains no users, no posts (clean transaction).

**Act:**

1. Register `alice` via `POST /api/v1/users` with username `"alice"`, email
   `"alice@example.com"`, password `"Pa$$w0rd1"`.
2. Log in as `alice` via `POST /api/v1/login` and capture the Bearer token.
3. Create a post via `POST /api/v1/alice/post` with title `"Test Post"` and
   text `"Content for UUID test."`. Capture `post_uuid` and `id` from the
   `201` response body.
4. Directly update the post's `status` to `"approved"` through `db_session`
   (so it appears in the public global feed and the unauthenticated list).
5. Call `GET /api/v1/alice/posts` with the Bearer token. Capture `post_uuid`
   from `items[0].post_uuid`.
6. Call `GET /api/v1/posts` without auth. Capture `post_uuid` from
   `items[0].post_uuid`.
7. Call `GET /api/v1/alice/post/{id}` without auth. Capture `post_uuid` from
   the response body.

**Expect:**

- Step 1: HTTP 201.
- Step 2: HTTP 200, token returned.
- Step 3: HTTP 201; `post_uuid` is present in the response body and is a
  valid UUID string (non-null, matches UUID format).
- Step 4: DB update succeeds; no HTTP assertion.
- Step 5: HTTP 200; `items` contains at least one entry; `items[0].post_uuid`
  is a valid UUID string.
- Step 6: HTTP 200; `items` contains at least one entry; `items[0].post_uuid`
  is a valid UUID string.
- Step 7: HTTP 200; `post_uuid` is a valid UUID string in the response body.
- **Final assertion:** the four `post_uuid` values captured in steps 3, 5, 6,
  and 7 are all equal to each other.

**Covers requirement(s):** F1, F2, F3, F4, F5.

---

### Scenario 2 — `read_post` response exposes `post_uuid`, not `uuid`

**Setup:**

- Reuse the post created in Scenario 1 (or create a fresh one with the same
  registration and login steps). The post must be approved.

**Act:**

- Call `GET /api/v1/alice/post/{id}` and capture the full response body as a
  JSON object.

**Expect:**

- HTTP 200.
- The response body contains a key `"post_uuid"` with a valid UUID value.
- The response body does **not** contain a top-level key `"uuid"` — the ORM
  column name must not appear in the serialized output.

**Covers requirement(s):** F4, F9.

## Out of scope for this test

- Adapter exception translation (no `try/except` blocks exist; covered by the
  absence of infrastructure failures in a healthy test environment).
- `patch_post` and `erase_post` response shapes (covered by existing tests).
- `list_pending_posts` regression (covered by its own existing outside-in test).
- Field-level Pydantic validation errors on the create endpoint (covered by
  endpoint integration test).
- Cache behaviour under repeated calls (not relevant to field presence).
- Performance, concurrency, pagination edge cases.
