# 0056 · migrate_update_post_route_username_to_user_id — Outside-in test spec

## Goal

Prove that `PATCH /api/v1/{user_id}/post/{id}` updates a post keyed by the
author's integer primary key — succeeding (200) when the authenticated requester
owns that `user_id`, with a subsequent `GET /api/v1/{user_id}/post/{id}`
returning the updated content (proving the cache keys were repointed to
`{user_id}_…` and the update invalidated the same key the read populates) —
refusing (403, bare message) when a different user targets the author's id, and
that the old `/{username}/post/{id}` URL no longer resolves (a string author
segment yields 422).

## Entry point

- **Method:** `PATCH`
- **Path:** `/api/v1/{user_id}/post/{id}`
- **Body:** `UpdatePostRequest` (optional `title`, `text`, `media_url`)
- **Auth:** required. Requester identity comes from `get_current_user` (returns a
  dict including an `"id"` key). In the test it is supplied via a FastAPI
  dependency override returning the authenticated user's dict.

## Wired real

- FastAPI app from `create_app()` / `app.main:app` (full stack: middleware, exception handlers).
- `UpdatePostAdapter` (runs the `SELECT … post by id` and the `UPDATE … post` against the test Postgres).
- `UpdatePostPort` (bound to `UpdatePostAdapter` in `Container`).
- `UserLookupAdapter` / `UserLookupPort` (the `SELECT User WHERE id = … AND is_deleted = false` author resolution).
- `UpdatePostUseCase` (resolve-by-id → 404 user, `check_post_owner` → 403, fetch post → 404 post, then update).
- `check_post_owner` shared policy (id comparison).
- The `@cache` decorator on the endpoint with keys `{user_id}_post_cache` / `{user_id}_posts:*`, and the `get_post` (0054) read path under `{user_id}_post_cache` used to confirm the read-after-update is fresh.
- Test Postgres via the `async_client` fixture (savepoint transaction rollback per test).
- DI container with `session_factory` overridden to use the test transaction.

## Mocked

- **`get_current_user`:** overridden via `app.dependency_overrides[get_current_user]`
  (the function the `update_post` router imports from `app.shared_dependencies`;
  `app.features.users.dependencies.get_current_user` resolves to the same object,
  as used by the existing 0028 test) to return the authenticated user's dict
  (`{"id": <id>, "username": <handle>, "is_superuser": False, "is_moderator": False, ...}`).
  Override removed in a `finally`/teardown. This is a FastAPI dependency override,
  not a mock of the slice's own port/use-case/adapter.
- **Redis:** the endpoint carries a `@cache` decorator. Follow the prior-art /
  `agent_docs/testing.md` convention used by the migrated read/write post slices:
  either run against a real test Redis or patch `app.adapters.cache.redis_cache.client`
  with an `AsyncMock` whose `get` is a cache-miss and whose `set`/`delete`/`scan`
  behave as no-ops, so the read-after-update returns the freshly-written DB row
  rather than a stale cached payload. The point asserted is behavioural (fresh
  read), not the specific Redis calls.

No external HTTP APIs are involved.

## Fixtures used

- `oit_engine` (slice `conftest.py`): per-test async engine; ensures schema exists.
- `async_client` (slice `conftest.py`): `httpx.AsyncClient` with `ASGITransport`, `session_factory` overridden to the savepoint transaction (copied verbatim from `agent_docs/testing.md`).
- `up56_alice` (slice `conftest.py`): inserts one `User` (`name="UP56 Alice"`, `username="up56alice"`, `email="up56alice@example.com"`, `hashed_password="hashed_pw"`, `is_deleted=False`) through the overridden session factory and returns the dict (with `id`).
- `up56_bob` (slice `conftest.py`): inserts a second distinct `User` (`name="UP56 Bob"`, `username="up56bob"`, `email="up56bob@example.com"`, `hashed_password="hashed_pw"`, `is_deleted=False`) and returns the dict (with `id`). Per user memory `project_flutter_route_migration_title_source`, the non-owner fixture is given a distinct id/handle so the ownership mismatch is unambiguous.
- `up56_alice_post` (slice `conftest.py`): inserts one `Post` owned by `up56_alice` (`title="Original title"`, `text="Original text."`, `status="pending_review"`, `is_deleted=False`, `created_by_user_id == up56_alice["id"]`) and returns the dict (with `id`).
- The `get_current_user` override (returning the relevant user's dict) is applied per scenario; seeding and the override both run before the HTTP call.

## Test scenarios

### Scenario 1: happy path — owner updates their post by integer ID; GET confirms the change

**Setup:**

- DB contains `up56_alice` (`id = alice_id`) and `up56_alice_post` (`id = post_id`, `title = "Original title"`, `text = "Original text."`).
- `get_current_user` overridden to return alice's dict (`id == alice_id`).

**Act:**

- `await async_client.patch(f"/api/v1/{alice_id}/post/{post_id}", json={"title": "Updated title"})`
- then `await async_client.get(f"/api/v1/{alice_id}/post/{post_id}")`

**Expect:**

- PATCH status: `200`; body `{"message": "Post updated"}`.
- GET status: `200`; body `title == "Updated title"`, `text == "Original text."` (unchanged field untouched). The fresh read proves the cache key was repointed to `{user_id}_post_cache` and the update invalidated the same key the read populates.
- DB state: the `"post"` row with `id == post_id` has `title == "Updated title"` and `updated_at` set (verified via raw SQL on the overridden session factory).

**Covers requirement(s):** F1, F3, F14, F15, F16.

### Scenario 2: forbidden — a different user updates the author's post

**Setup:**

- DB contains `up56_alice` (`id = alice_id`), `up56_bob` (`id = bob_id`, `bob_id != alice_id`), and `up56_alice_post` (`id = post_id`, `title = "Original title"`).
- `get_current_user` overridden to return bob's dict (`id == bob_id`).

**Act:**

- `await async_client.patch(f"/api/v1/{alice_id}/post/{post_id}", json={"title": "Hijacked title"})`

**Expect:**

- Status: `403`.
- Body carries no ownership-specific message — `check_post_owner` raises a bare `ForbiddenDomainError()`; the old `{"error": {"code": "forbidden", "message": "You can only update your own posts"}}` text is gone (the `message` is empty / the project's default 403 payload).
- DB state: the `"post"` row with `id == post_id` still has `title == "Original title"` (the update port was never called).

**Covers requirement(s):** F6, F9, F17.

### Scenario 3: old route gone — string author segment yields 422

**Setup:**

- DB contains `up56_alice` and `up56_alice_post`; `get_current_user` override active (alice).

**Act:**

- `await async_client.patch(f"/api/v1/up56alice/post/{post_id}", json={"title": "X"})` (alice's username string in the author path segment).

**Expect:**

- Status: `422` (FastAPI cannot bind the non-integer segment to the `int`-typed `user_id` path parameter).
- DB state: the `"post"` row with `id == post_id` still has `title == "Original title"` (no update applied).

**Covers requirement(s):** F10, F11.

## Out of scope for this test

- 404 for an unknown/soft-deleted `target_user_id` (F5) — covered by the use-case unit test and endpoint integration test; the exact payload is `{"error": {"code": "notfound", "message": "User not found"}}`.
- 404 for an unknown post id (F7) — covered by the use-case unit test and endpoint integration test; the exact payload is `{"error": {"code": "notfound", "message": "Post not found"}}`.
- 401 unauthenticated (F4) — covered by the endpoint integration test (the outside-in test always supplies the auth override).
- 422 for an invalid request body (F2) — covered by the endpoint integration test.
- The 404(user)→403(owner)→404(post) ordering across all branches (F8) — covered by the use-case unit test.
- The preserved no-owner-filter gap on `get_post_by_id` (F18) and the `get_active_user_by_id` / `check_post_owner` usage details (F19) — covered by the use-case unit test and the shared adapter unit test in slice 0032.
- `UpdatePostAdapter` internals (F13) — unchanged; covered by the existing 0028 adapter test.
- Performance, load, concurrency.
