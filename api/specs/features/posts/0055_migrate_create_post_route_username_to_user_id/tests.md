# 0055 · migrate_create_post_route_username_to_user_id — Outside-in test spec

## Goal

Prove that `POST /api/v1/{user_id}/post` creates a post keyed by the author's
integer primary key — succeeding (201) when the authenticated requester owns
that `user_id`, refusing (403) when they target a different user's id — and that
the old `/{username}/post` URL no longer resolves (a string author segment
yields 422).

## Entry point

- **Method:** `POST`
- **Path:** `/api/v1/{user_id}/post`
- **Body:** `CreatePostRequest` (`title`, `text`, `media_url`)
- **Auth:** required. Requester identity comes from `get_current_user`
  (returns a dict including an `"id"` key). In the test it is supplied via a
  FastAPI dependency override returning the authenticated author's dict.

## Wired real

- FastAPI app from `create_app()` / `app.main:app` (full stack: middleware, exception handlers).
- `CreatePostAdapter` (runs the `INSERT … RETURNING` against the test Postgres).
- `CreatePostPort` (bound to `CreatePostAdapter` in `Container`).
- `UserLookupAdapter` / `UserLookupPort` (the `SELECT User WHERE id = … AND is_deleted = false` author resolution).
- `CreatePostUseCase` (resolve-by-id → 404, `check_post_owner` → 403, then create).
- `check_post_owner` shared policy (id comparison).
- Test Postgres via the `async_client` fixture (savepoint transaction rollback per test).
- DI container with `session_factory` overridden to use the test transaction.

## Mocked

- **`get_current_user`:** overridden via `app.dependency_overrides[get_current_user]`
  (the function the `create_post` router imports from `app.shared_dependencies`)
  to return `{"id": author_id, "username": "gp55alice", "is_superuser": False, "is_moderator": False, ...}`, simulating the authenticated author. Override removed in a `finally`/teardown. This is a FastAPI dependency override, not a mock of the slice's own port/use-case/adapter.
- **Redis:** not mocked — `create_post` has no `@cache` decorator and the route does not touch the cache client. (If any global middleware in the stack touches Redis during the request, mock `app.adapters.cache.redis_cache.client` as a cache-miss `AsyncMock`; otherwise leave it real.)

No external HTTP APIs are involved.

## Fixtures used

- `oit_engine` (slice `conftest.py`): per-test async engine; ensures schema exists.
- `async_client` (slice `conftest.py`): `httpx.AsyncClient` with `ASGITransport`, `session_factory` overridden to the savepoint transaction (copied verbatim from `agent_docs/testing.md`).
- `seeded_author` (slice `conftest.py`): inserts one `User` (`name="GP55 Alice"`, `username="gp55alice"`, `email="gp55alice@example.com"`, `hashed_password="hashed_pw"`, `is_deleted=False`) through the overridden session factory and returns the row (with `.id`).
- `seeded_other_user` (slice `conftest.py`): inserts a second distinct `User` (`name="GP55 Bob"`, `username="gp55bob"`, `email="gp55bob@example.com"`, `hashed_password="hashed_pw"`, `is_deleted=False`) and returns the row (with `.id`). Per user memory `project_flutter_route_migration_title_source`, the non-owner fixture is given a distinct id/handle so the ownership mismatch is unambiguous.
- The `get_current_user` override (returning `seeded_author`'s dict) is applied for all scenarios; seeding and the override both run before the HTTP call.

## Test scenarios

### Scenario 1: happy path — create a post under your own integer ID

**Setup:**

- DB contains `seeded_author` (`id = author_id`).
- `get_current_user` overridden to return the author's dict (`id == author_id`).

**Act:**

- `await async_client.post(f"/api/v1/{author_id}/post", json={"title": "Hello", "text": "First post", "media_url": None})`

**Expect:**

- Status: `201`.
- Body matches `CreatePostResponse`: `created_by_user_id == author_id`,
  `status == "pending_review"`, `id` set, `post_uuid` set, `created_at` set;
  `title == "Hello"`, `text == "First post"`. No `username` field in the body.
- DB state: exactly one row in `"post"` with `created_by_user_id == author_id`,
  `title == "Hello"`, `status == "pending_review"`, `is_deleted == false`
  (verified via raw SQL on the overridden session factory).

**Covers requirement(s):** F1, F2, F3, F14.

### Scenario 2: forbidden — create a post under another user's id

**Setup:**

- DB contains `seeded_author` (`id = author_id`) and `seeded_other_user` (`id = other_id`, `other_id != author_id`).
- `get_current_user` overridden to return the author's dict (`id == author_id`).

**Act:**

- `await async_client.post(f"/api/v1/{other_id}/post", json={"title": "Hi", "text": "Body", "media_url": None})`

**Expect:**

- Status: `403`.
- Body carries no ownership-specific message — `check_post_owner` raises a bare
  `ForbiddenDomainError()`; the old "You can only post under your own username"
  text is absent (the response body's `message` is empty / the project's default 403 payload).
- DB state: **no** `"post"` row exists with `created_by_user_id == other_id` (the
  create port was never called).

**Covers requirement(s):** F7, F8, F9, F18.

### Scenario 3: old route gone — string author segment yields 422

**Setup:**

- DB contains `seeded_author`; `get_current_user` override active.

**Act:**

- `await async_client.post("/api/v1/gp55alice/post", json={"title": "Hi", "text": "Body", "media_url": None})` (the author's username string in the path).

**Expect:**

- Status: `422` (FastAPI cannot bind the non-integer segment to the `int`-typed `user_id` path parameter).
- DB state: no new `"post"` row created.

**Covers requirement(s):** F10, F11.

## Out of scope for this test

- 404 for an unknown/soft-deleted `target_user_id` (F6) — covered by the use-case unit test and endpoint integration test; note the exact payload is `{"error": {"code": "notfound", "message": "User not found"}}`.
- 401 unauthenticated (F5) — covered by the endpoint integration test (the outside-in test always supplies the auth override).
- 422 for an invalid request body (F4) — covered by the endpoint integration test.
- `get_active_user_by_id` filter / soft-delete behaviour (F15, F16) — covered by the shared adapter unit test in slice 0032.
- The retained `get_active_user_by_username` and `check_post_owner` int-comparison details (F17) — covered by unit tests.
- `erase_post` cross-slice ownership update (F19, F20) — covered by the `erase_post` use-case unit test and the unchanged `erase_post` endpoint/outside-in tests; the full-suite baseline proves zero net-new failures.
- Performance, load, concurrency.
