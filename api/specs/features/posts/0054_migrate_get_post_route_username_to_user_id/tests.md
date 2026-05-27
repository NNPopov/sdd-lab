# 0054 · migrate_get_post_route_username_to_user_id — Outside-in test spec

## Goal

Prove that `GET /api/v1/{user_id}/post/{id}` fetches a single post keyed by the
author's integer primary key — returning an `approved` post to any caller and a
non-approved post to its author — and that the old `/{username}/post/{id}` URL
no longer resolves (a string author segment yields 422).

## Entry point

- **Method:** `GET`
- **Path:** `/api/v1/{user_id}/post/{id}`
- **Body:** none
- **Auth:** optional. Requester identity is taken from `get_optional_user`
  (returns a dict with `"id"`, `"is_superuser"`, `"is_moderator"` keys).
  Unauthenticated requests see only approved posts; the author
  (`optional_user["id"] == user_id`) and privileged viewers see non-approved
  posts too.

## Wired real

- FastAPI app from `create_app()` (full stack: middleware, exception handlers).
- `GetPostAdapter` (runs the `SELECT Post, User.username … JOIN User` against the test Postgres).
- `GetPostPort` (bound to `GetPostAdapter` in `Container`).
- `GetPostUseCase` (visibility logic over the port result).
- Test Postgres via the `async_client` fixture (savepoint transaction rollback per test).
- DI container with `session_factory` overridden to use the test transaction.

## Mocked

- **Redis client (`@cache` decorator):** patched via
  `app.adapters.cache.redis_cache.client = AsyncMock()` with
  `get.return_value = None` (always a cache miss), so the cache decorator does
  not raise `MissingClientError`. Cache-key behaviour is verified by the
  endpoint integration test, not here.
- For the author-view scenario, `app.shared_dependencies.get_optional_user` is
  overridden via `app.dependency_overrides` to return
  `{"id": <author_id>, "username": "<author_username>", "is_superuser": False, "is_moderator": False}`.
  This is a FastAPI dependency override (matching what the `get_post` router
  imports), not a mock of the slice's own port/use-case/adapter.

No external HTTP APIs are involved.

## Fixtures used

- `oit_engine` (slice `conftest.py`): per-test async engine; ensures schema exists.
- `async_client` (slice `conftest.py`): `httpx.AsyncClient` with `ASGITransport`, `session_factory` overridden to the savepoint transaction, Redis mocked.
- `seeded_author` (slice `conftest.py`): inserts one `User` (`name="GP54 Alice"`, `username="gp54alice"`, `email="gp54alice@example.com"`, `hashed_password="hashed_pw"`, `is_deleted=False`) through the overridden session factory and returns the row (with `.id`).
- `seeded_approved_post` (slice `conftest.py`): inserts one `Post` for `seeded_author` with `status="approved"` (`title="Approved Post"`, `is_deleted=False`) and returns it (with `.id`).
- `seeded_pending_post` (slice `conftest.py`): inserts one non-approved `Post` for `seeded_author` with `status="pending"` (`title="Pending Post"`, `is_deleted=False`) and returns it (with `.id`).

## Test scenarios

### Scenario 1: happy path — get an approved post by integer ID (unauthenticated)

**Setup:**

- DB contains `seeded_author` (`id = author_id`) and `seeded_approved_post` (`id = post_id`, `status="approved"`).
- No `Authorization` header is sent (unauthenticated).
- Redis mocked (cache miss).

**Act:**

- `await async_client.get(f"/api/v1/{author_id}/post/{post_id}")`

**Expect:**

- Status: `200`.
- Body matches `GetPostResponse`: `id == post_id`, `status == "approved"`,
  `created_by_user_id == author_id`, and `username == "gp54alice"` (resolved via
  the `User` JOIN, not echoed from the URL).
- Body contains `title`, `text`, `media_url`, `created_at`, `post_uuid`.

**Covers requirement(s):** F1, F3, F10, F11, F16.

### Scenario 2: author view — the author reads their own non-approved post

**Setup:**

- DB contains `seeded_author` (`id = author_id`) and `seeded_pending_post` (`id = post_id`, `status="pending"`).
- `app.shared_dependencies.get_optional_user` overridden to return
  `{"id": author_id, "username": "gp54alice", "is_superuser": False, "is_moderator": False}`
  (simulates the authenticated author). Override removed in a `finally` block.
- Redis mocked (cache miss).

**Act:**

- `await async_client.get(f"/api/v1/{author_id}/post/{post_id}")`

**Expect:**

- Status: `200`.
- Body `status == "pending"`, `id == post_id`, `created_by_user_id == author_id`, `username == "gp54alice"`.

**Covers requirement(s):** F4, F13, F15.

### Scenario 3: old route gone — string author segment yields 422

**Setup:**

- No seeding required.

**Act:**

- `await async_client.get("/api/v1/gp54alice/post/1")` (the author's username string in the path).

**Expect:**

- Status: `422` (FastAPI cannot bind the non-integer segment to the `int`-typed `user_id` path parameter).

**Covers requirement(s):** F2, F9.

## Out of scope for this test

- Non-approved post visible to a privileged viewer (F5) — covered by the use-case unit test and endpoint integration test.
- 404 for a non-approved post viewed by a non-author non-privileged caller (F6) — covered by the use-case unit test and endpoint integration test.
- 404 for a missing post, wrong author, or unknown `user_id` (F7, F8) — covered by the adapter and endpoint integration tests; note the exact payload is `{"error": {"code": "notfound", "message": "Post not found"}}`.
- Adapter filter / JOIN details and soft-delete behaviour (F11, F12) — covered by the adapter unit test.
- Cache key prefix / `resource_id_name` behaviour (F16) — covered by the endpoint integration test.
- Performance, load, concurrency.
