# 0058 · migrate_erase_db_post_route_username_to_user_id — Outside-in test spec

## Goal

Prove that `DELETE /api/v1/{user_id}/db_post/{id}` hard-deletes a post keyed by
the author's integer primary key — succeeding (200) for a superuser, with a
subsequent `GET /api/v1/{user_id}/post/{id}` returning 404 (proving the cache
keys were repointed to `{user_id}_…` and the hard delete invalidated the same
key the read populates, and that the row is physically gone) — and that the old
`/{username}/db_post/{id}` URL no longer resolves (a string author segment yields
422).

## Entry point

- **Method:** `DELETE`
- **Path:** `/api/v1/{user_id}/db_post/{id}`
- **Body:** none (DELETE).
- **Auth:** required, superuser only. Identity comes from `get_current_superuser`.
  In the test it is supplied via a FastAPI dependency override returning the
  authenticated superuser's dict.

## Wired real

- FastAPI app from `create_app()` / `app.main:app` (full stack: middleware, exception handlers).
- `EraseDbPostAdapter` (runs the owner-scoped `SELECT … post` and the physical `DELETE … post` with its moderation-log cascade against the test Postgres).
- `EraseDbPostPort` (bound to `EraseDbPostAdapter` in `Container`).
- `UserLookupAdapter` / `UserLookupPort` (the `SELECT User WHERE id = … AND is_deleted = false` author resolution via `get_active_user_by_id`).
- `EraseDbPostUseCase` (resolve-by-id → 404 user, owner-scoped `find_post` → 404 post, then hard delete).
- The `@cache` decorator on the endpoint with keys `{user_id}_post_cache` / `{user_id}_posts`, and the `get_post` (0054) read path under `{user_id}_post_cache` used to confirm the read-after-delete is gone.
- Test Postgres via the `async_client` fixture (savepoint transaction rollback per test).
- DI container with `session_factory` overridden to use the test transaction.

## Mocked

- **`get_current_superuser`:** overridden via `app.dependency_overrides[get_current_superuser]`
  (the function the `erase_db_post` router imports from `app.shared_dependencies`)
  to return the authenticated superuser's dict (`{"id": <id>, "username": <handle>,
  "is_superuser": True, ...}`). Override removed in a `finally`/teardown. This is a
  FastAPI dependency override, not a mock of the slice's own port/use-case/adapter.
- **Redis:** the endpoint carries a `@cache` decorator. Follow the prior-art /
  `agent_docs/testing.md` convention used by the migrated read/write/delete post
  slices: patch `app.adapters.cache.redis_cache.client` with an `AsyncMock` whose
  `get` is a cache-miss and whose `set`/`delete`/`scan` behave as no-ops, so the
  read-after-delete reflects the freshly-deleted DB state (404) rather than a
  stale cached payload. The point asserted is behavioural (post gone), not the
  specific Redis calls.

No external HTTP APIs are involved.

## Fixtures used

- `oit_engine` (slice `conftest.py`): per-test async engine; ensures schema exists.
- `async_client` (slice `conftest.py`): `httpx.AsyncClient` with `ASGITransport`, `session_factory` overridden to the savepoint transaction, and the Redis client patched (copied from the `0030_erase_db_post` / `0057` conftest).
- `edp58_author` (slice `conftest.py`): inserts one regular `User` (`name="EDP58 Author"`, `username="edp58author"`, `email="edp58author@example.com"`, `hashed_password="fake_hashed_password"`, `is_deleted=False`, `is_superuser=False`) through the overridden session factory and returns the dict (with `id`).
- `edp58_superuser` (slice `conftest.py`): inserts a distinct `User` with `is_superuser=True` (`name="EDP58 Super"`, `username="edp58super"`, `email="edp58super@example.com"`) and returns the dict (with `id`); its id differs from `edp58_author["id"]` so the no-ownership behaviour is unambiguous (a superuser deletes another user's post).
- `edp58_author_post` (slice `conftest.py`): inserts one `Post` owned by `edp58_author` (`title="Original title"`, `text="Original text."`, `status="approved"`, `is_deleted=False`, `created_by_user_id == edp58_author["id"]`) and returns the dict (with `id`). Status `approved` makes the verification `GET` succeed before the delete.
- The `get_current_superuser` override (returning `edp58_superuser`) is applied per scenario; seeding and the override both run before the HTTP call.

## Test scenarios

### Scenario 1: happy path — superuser hard-deletes by integer ID; GET then returns 404

**Setup:**

- DB contains `edp58_author` (`id = author_id`), `edp58_superuser` (`id = super_id`, `super_id != author_id`), and `edp58_author_post` (`id = post_id`, `title = "Original title"`).
- `get_current_superuser` overridden to return `edp58_superuser`'s dict.

**Act:**

- `await async_client.get(f"/api/v1/{author_id}/post/{post_id}")` (populates the read cache; 200 expected).
- `await async_client.delete(f"/api/v1/{author_id}/db_post/{post_id}")`
- then `await async_client.get(f"/api/v1/{author_id}/post/{post_id}")`

**Expect:**

- First GET status: `200` (the post is visible before deletion).
- DELETE status: `200`; body `{"message": "Post deleted from the database"}`.
- Second GET status: `404`. The fresh 404 proves the cache key was repointed to `{user_id}_post_cache` and the hard delete invalidated the same key the read populates, and that the row is physically gone. It also proves a superuser may delete another user's post (no ownership check), since `super_id != author_id`.
- DB state: no `"post"` row with `id == post_id` remains (verified via raw SQL on the overridden session factory).

**Covers requirement(s):** F1, F2, F13, F14, F15, F16, F18.

### Scenario 2: old route gone — string author segment yields 422

**Setup:**

- DB contains `edp58_author`, `edp58_superuser`, and `edp58_author_post` (`id = post_id`, `title = "Original title"`); `get_current_superuser` override active.

**Act:**

- `await async_client.delete(f"/api/v1/edp58author/db_post/{post_id}")` (the author's username string in the author path segment).

**Expect:**

- Status: `422` (FastAPI cannot bind the non-integer segment to the `int`-typed `user_id` path parameter).
- DB state: the `"post"` row with `id == post_id` still exists with `is_deleted == False` (no delete applied via the dead string route).

**Covers requirement(s):** F9, F10.

## Out of scope for this test

- 403 for a non-superuser caller (F4) — covered by the endpoint integration test; the 403 comes from the `get_current_superuser` gate, which the outside-in test always satisfies via the override.
- 401 unauthenticated (F3) — covered by the endpoint integration test.
- 404 for an unknown/soft-deleted `user_id` (F5) and for an unknown post id (F6) — covered by the use-case unit test and endpoint integration test; the exact payloads are `{"error": {"code": "notfound", "message": "User not found"}}` and `{"error": {"code": "notfound", "message": "Post not found"}}`.
- The 404(user)→404(post) ordering and downstream-port-not-called branches (F7, F8) — covered by the use-case unit test.
- The `get_active_user_by_id` usage detail (F17) — covered by the use-case unit test.
- `EraseDbPostAdapter` internals and the moderation-log cascade mechanics (F12, F18 mechanics) — unchanged; covered by the existing 0030/0031 adapter and cascade tests.
- Performance, load, concurrency.
</content>
