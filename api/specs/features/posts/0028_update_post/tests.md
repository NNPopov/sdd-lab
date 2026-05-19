# 0028 · update_post — Outside-in test spec

## Goal

Prove that an authenticated post owner can update a field via
`PATCH /api/v1/{username}/post/{id}`, receive `{"message": "Post updated"}`,
and that the changed field is visible on a subsequent `GET`.

## Entry point

- **Method:** `PATCH`
- **Path:** `/api/v1/{username}/post/{id}`
- **Body:** `UpdatePostRequest` — e.g. `{"title": "Updated title"}`
- **Auth:** `get_current_user` FastAPI dependency overridden with the owning
  user's dict (same technique used by `create_post` outside-in test)

## Wired real

- FastAPI app from `app.main.app` (full stack: middleware, exception handlers).
- `UpdatePostAdapter` — performs user lookup, post lookup, and SQL `UPDATE`.
- `UpdatePostPort` bound to `UpdatePostAdapter` in `Container`.
- `UpdatePostUseCase` bound in `Container`.
- Test Postgres via `async_client` fixture (savepoint-mode rollback per test).
- DI container's `session_factory` overridden to use the test connection.
- `GetPostUseCase` and its adapter (reached in the verification GET of
  scenario 1).

## Mocked

- **Redis (`app.adapters.cache.redis_cache.client`):** replaced with
  `AsyncMock` in the `async_client` fixture; `mock_redis.get.return_value =
  None` simulates a cache miss on every call. This prevents
  `MissingClientError` from the `@cache` decorator on both the PATCH and GET
  endpoints. Cache invalidation is verified indirectly — the GET after PATCH
  returns the updated DB value, not a stale cached value.

## Fixtures used

- `async_client` (in slice `conftest.py`): `httpx.AsyncClient` against the
  app with savepoint-mode rollback and Redis mocked (see above).
- `up28_alice` (in slice `conftest.py`): seeds
  `User(name="UP28 Alice", username="up28alice",
  email="up28alice@example.com", hashed_password="fake_hashed_password")` via
  the overridden session factory; returns
  `{"id": ..., "username": "up28alice", "email": "up28alice@example.com",
  "name": "UP28 Alice", "is_superuser": False}`.
- `up28_bob` (in slice `conftest.py`): seeds
  `User(name="UP28 Bob", username="up28bob",
  email="up28bob@example.com", hashed_password="fake_hashed_password")`;
  returns an analogous dict.
- `up28_alice_post` (in slice `conftest.py`, depends on `up28_alice`): seeds
  `Post(created_by_user_id=up28_alice["id"], title="Original title",
  text="Original text.", status="approved")`; returns `{"id": post.id}`.
  Status `approved` ensures the verification GET in scenario 1 succeeds
  without auth (approved posts are publicly visible per the `get_post` slice).

## Test scenarios

### Scenario 1: happy path — owner patches their post; GET confirms the change

**Setup:**

- DB contains: a `User` row for `up28alice` and a `Post` row with
  `title="Original title"`, `text="Original text."`, `status="approved"`,
  owned by `up28alice`.
- `get_current_user` dependency overridden to return `up28_alice` dict for
  the PATCH step (removed after the PATCH call).
- Redis `get` returns `None` on every call.

**Act:**

1. `await client.patch("/api/v1/up28alice/post/{post_id}",
   json={"title": "Updated title"})` with `get_current_user` overridden to
   `up28_alice`.
2. `await client.get("/api/v1/up28alice/post/{post_id}")` with no auth
   override (approved post is publicly readable).

**Expect:**

- Step 1 status: `200`.
- Step 1 response body: `{"message": "Post updated"}`.
- Step 2 status: `200`.
- Step 2 response body: `title == "Updated title"` and
  `text == "Original text."` (unchanged field is preserved).
- DB state: `SELECT title, updated_at FROM post WHERE id = {post_id}` returns
  `title == "Updated title"` and `updated_at IS NOT NULL`.

**Covers requirement(s):** F1, F9.

---

### Scenario 2: ownership violation — bob targets alice's post; 403, DB unchanged

**Setup:**

- DB contains: a `User` row for `up28alice`, a `User` row for `up28bob`, and
  a `Post` row with `title="Original title"`, `status="approved"`, owned by
  `up28alice`.
- `get_current_user` dependency overridden to return `up28_bob` dict.

**Act:**

- `await client.patch("/api/v1/up28alice/post/{post_id}",
  json={"title": "Hijacked title"})` with `get_current_user` overridden to
  `up28_bob`.

**Expect:**

- Status: `403`.
- Response body:
  `{"error": {"code": "forbidden", "message": "You can only update your own posts"}}`.
- DB state: `SELECT title FROM post WHERE id = {post_id}` still returns
  `"Original title"` (no change applied).

**Covers requirement(s):** F4.

---

## Out of scope for this test

- Missing or invalid token (401) — covered by endpoint integration test.
- Non-existent `username` in path (404, user not found) — covered by endpoint
  integration test.
- Non-existent or soft-deleted `post_id` (404, post not found) — covered by
  endpoint integration test.
- Field-level Pydantic validation failures (422) — covered by endpoint
  integration test.
- Adapter-level exception variants — covered by adapter unit test.
- `port.update` not called when user/post checks fail — covered by use-case
  unit test.
- Performance, load, concurrency.
