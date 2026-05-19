# 0029 · erase_post — Outside-in test spec

## Goal

Prove that an authenticated owner can soft-delete their own post end-to-end
through `DELETE /api/v1/{username}/post/{id}`, that the DB row is marked
deleted, that a subsequent GET returns 404, and that a caller who is not the
path user is rejected with 403.

## Entry point

- **Method:** `DELETE`
- **Path:** `/api/v1/{username}/post/{id}`
- **Body:** none
- **Auth:** Bearer token (via `get_current_user` dependency override in tests)

## Wired real

- FastAPI app from `create_app()` (full stack: middleware, exception handlers).
- `ErasePostAdapter` — the slice's real adapter against the test Postgres.
- `ErasePostPort` — bound to `ErasePostAdapter` in `Container`.
- `ErasePostUseCase` — the slice's real use-case.
- `GetPostUseCase` / `GetPostAdapter` — real, used for the subsequent-GET
  assertion in Scenario 1.
- Test Postgres via per-test savepoint transaction (rolled back at teardown);
  container's `session_factory` overridden to the same connection.
- `get_current_user` overridden via `app.dependency_overrides` to return a
  pre-seeded user dict without touching the JWT layer.

## Mocked

- **Redis cache client** (`app.adapters.cache.redis_cache.client`): replaced
  with `AsyncMock` returning cache-miss responses (`get` → `None`, `scan` →
  `(0, [])`). Required because both the `erase_post` and `get_post` endpoints
  carry `@cache` decorators that call the Redis client.

No external HTTP APIs are involved. No clock mocking is needed.

## Fixtures used

Defined in `tests/features/posts/0029_erase_post/conftest.py`, following
the same pattern as `tests/features/posts/0028_update_post/conftest.py`:

- **`async_client`** — `httpx.AsyncClient` wired to the app with:
  - Redis client patched.
  - `async_get_db` dependency overridden (for the flat `erase_db_post`
    handler that still lives in `posts/router.py`).
  - `container.session_factory` overridden to a savepoint-mode
    `async_sessionmaker` bound to the test transaction.
  - Transaction rolled back at teardown.

- **`ep29_alice`** — inserts an `User` row with `username="ep29alice"` via
  the overridden session factory; yields `{"id": ..., "username": "ep29alice",
  "is_superuser": False, ...}`. Used as the `get_current_user` return value
  when acting as Alice.

- **`ep29_bob`** — inserts an `User` row with `username="ep29bob"` via
  the overridden session factory; yields a similar dict. Used as the
  `get_current_user` return value when acting as Bob.

- **`ep29_alice_post`** — inserts a `Post` row with
  `created_by_user_id=ep29_alice["id"]`, `title="Test post"`,
  `text="Test text."`, `status="approved"`. Status `"approved"` ensures the
  subsequent unauthenticated GET in Scenario 1 would have returned 200 before
  deletion (making the 404 result unambiguously caused by the soft-delete, not
  by visibility rules). Yields `{"id": post.id}`.

## Test scenarios

### Scenario 1: owner deletes their post; subsequent GET returns 404

**Setup:**

- DB contains: `ep29alice` user, `ep29bob` user, one `approved` post owned by
  `ep29alice` (`ep29_alice_post`).
- `get_current_user` overridden to return `ep29_alice`.
- Redis mock: cache miss on every call.

**Act:**

- `DELETE /api/v1/ep29alice/post/{ep29_alice_post["id"]}` authenticated as
  `ep29_alice`.

**Expect (DELETE response):**

- Status: `200`.
- Response body: `{"message": "Post deleted"}`.

**Expect (DB state after DELETE):**

- `SELECT is_deleted, deleted_at FROM post WHERE id = {post_id}` returns a
  row with `is_deleted = true` and `deleted_at` is non-null.

**Expect (subsequent GET — no auth):**

- `GET /api/v1/ep29alice/post/{ep29_alice_post["id"]}` (unauthenticated) →
  status `404`.
- Response body: `{"error": {"code": "notfound", "message": "Post not found"}}`.

**Covers requirements:** F1, F6, F9, F11.

---

### Scenario 2: ownership gap fix — Bob targets his own path with Alice's post id

**Setup:**

- DB contains: `ep29alice` user, `ep29bob` user, one `approved` post owned by
  `ep29alice` (`ep29_alice_post`).
- `get_current_user` overridden to return `ep29_bob`.
- Redis mock: cache miss on every call.

**Act:**

- `DELETE /api/v1/ep29bob/post/{ep29_alice_post["id"]}` authenticated as
  `ep29_bob` (Bob's token, Bob's path segment, but Alice's post id).

**Expect (DELETE response):**

- Status: `404`.
- Response body: `{"error": {"code": "notfound", "message": "Post not found"}}`.

**Expect (DB state after rejected DELETE):**

- `SELECT is_deleted FROM post WHERE id = {post_id}` returns a row with
  `is_deleted = false` (post was not touched).

**Why this is the red trigger:** The existing flat `erase_post` handler checks
only that `current_user["id"] == db_user["id"]` (Bob matches Bob's path), then
fetches the post by `id` alone with no ownership filter — so it successfully
deletes Alice's post and returns 200. The new `ErasePostAdapter.find_post`
adds `created_by_user_id == owner_id` to the query, so it returns `None` for a
post that belongs to Alice (not Bob), causing the use-case to raise
`NotFoundDomainError("Post not found")` → 404.

**Covers requirements:** F5, F8.

## Out of scope for this test

- `403 Forbidden` (Bob uses Alice's path segment) — the 403 path is exercised
  by both the old flat handler and the new slice identically; it is not a
  behavioural difference and is covered by the endpoint integration test.
- `401 Unauthorized` — covered by endpoint integration test
  (`presentation/test_router.py`); requires testing the JWT layer directly.
- `404 User not found` — covered by use-case unit test and endpoint integration
  test; the outside-in test relies on the fixture to guarantee the user exists.
- Cache list-invalidation (`{username}_posts` entries) — `F12` is covered by
  the endpoint integration test, which can assert on list responses before and
  after deletion; the outside-in test focuses on the single-post path.
- Field-level validation — no request body; not applicable.
- Performance or concurrency.
