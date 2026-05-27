# 0057 · migrate_erase_post_route_username_to_user_id — Outside-in test spec

## Goal

Prove that `DELETE /api/v1/{user_id}/post/{id}` soft-deletes a post keyed by the
author's integer primary key — succeeding (200) when the authenticated requester
owns that `user_id`, with a subsequent `GET /api/v1/{user_id}/post/{id}`
returning 404 (proving the cache keys were repointed to `{user_id}_…` and the
delete invalidated the same key the read populates) — refusing (403, bare
message) when a different user targets the author's id, and that the old
`/{username}/post/{id}` URL no longer resolves (a string author segment yields
422).

## Entry point

- **Method:** `DELETE`
- **Path:** `/api/v1/{user_id}/post/{id}`
- **Body:** none.
- **Auth:** required. Requester identity comes from `get_current_user` (returns a
  dict including an `"id"` key). In the test it is supplied via a FastAPI
  dependency override returning the authenticated user's dict.

## Wired real

- FastAPI app from `create_app()` / `app.main:app` (full stack: middleware, exception handlers).
- `ErasePostAdapter` (runs `find_post(post_id, owner_id)` filtered on `Post.created_by_user_id` and the `UPDATE … SET is_deleted = true` soft delete against the test Postgres).
- `ErasePostPort` (bound to `ErasePostAdapter` in `Container`).
- `UserLookupAdapter` / `UserLookupPort` (the `SELECT User WHERE id = … AND is_deleted = false` author resolution via `get_active_user_by_id`).
- `ErasePostUseCase` (resolve-by-id → 404 user, `check_post_owner` → 403, owner-scoped `find_post` → 404 post, then soft delete).
- `check_post_owner` shared policy (id comparison).
- The `@cache` decorator on the endpoint with keys `{user_id}_post_cache` / `{user_id}_posts` (the `to_invalidate_extra` dict form), and the `get_post` (0054) read path under `{user_id}_post_cache` used to confirm the read-after-delete is a miss → 404.
- Test Postgres via the `async_client` fixture (savepoint transaction rollback per test).
- DI container with `session_factory` overridden to use the test transaction.

## Mocked

- **`get_current_user`:** overridden via `app.dependency_overrides[get_current_user]`
  (the function the `erase_post` router imports from `app.shared_dependencies`;
  `app.features.users.dependencies.get_current_user` resolves to the same object,
  as used by the existing 0029 test) to return the authenticated user's dict
  (`{"id": <id>, "username": <handle>, "is_superuser": False, "is_moderator": False, ...}`).
  Override removed in a `finally`/teardown. This is a FastAPI dependency override,
  not a mock of the slice's own port/use-case/adapter.
- **Redis:** the endpoint carries a `@cache` decorator. Follow the prior-art /
  `agent_docs/testing.md` convention used by the migrated read/write post slices:
  either run against a real test Redis or patch `app.adapters.cache.redis_cache.client`
  with an `AsyncMock` whose `get` is a cache-miss and whose `set`/`delete`/`scan`
  behave as no-ops, so the read-after-delete returns 404 (the deleted DB row)
  rather than a stale cached payload. The point asserted is behavioural (the post
  is gone after delete), not the specific Redis calls.

No external HTTP APIs are involved.

## Fixtures used

- `oit_engine` (slice `conftest.py`): per-test async engine; ensures schema exists.
- `async_client` (slice `conftest.py`): `httpx.AsyncClient` with `ASGITransport`, `session_factory` overridden to the savepoint transaction (copied verbatim from `agent_docs/testing.md`).
- `ep57_alice` (slice `conftest.py`): inserts one `User` (`name="EP57 Alice"`, `username="ep57alice"`, `email="ep57alice@example.com"`, `hashed_password="hashed_pw"`, `is_deleted=False`) through the overridden session factory and returns the dict (with `id`).
- `ep57_bob` (slice `conftest.py`): inserts a second distinct `User` (`name="EP57 Bob"`, `username="ep57bob"`, `email="ep57bob@example.com"`, `hashed_password="hashed_pw"`, `is_deleted=False`) and returns the dict (with `id`). Per user memory `project_flutter_route_migration_title_source`, the non-owner fixture is given a distinct id/handle so the ownership mismatch is unambiguous.
- `ep57_alice_post` (slice `conftest.py`): inserts one `Post` owned by `ep57_alice` (`title="Original title"`, `text="Original text."`, `status="pending_review"`, `is_deleted=False`, `created_by_user_id == ep57_alice["id"]`) and returns the dict (with `id`).
- The `get_current_user` override (returning the relevant user's dict) is applied per scenario; seeding and the override both run before the HTTP call.

## Test scenarios

### Scenario 1: happy path — owner deletes their post by integer ID; GET confirms it is gone

**Setup:**

- DB contains `ep57_alice` (`id = alice_id`) and `ep57_alice_post` (`id = post_id`, `is_deleted = False`).
- `get_current_user` overridden to return alice's dict (`id == alice_id`).

**Act:**

- `await async_client.get(f"/api/v1/{alice_id}/post/{post_id}")` (populates `{user_id}_post_cache`)
- then `await async_client.delete(f"/api/v1/{alice_id}/post/{post_id}")`
- then `await async_client.get(f"/api/v1/{alice_id}/post/{post_id}")`

**Expect:**

- First GET status: `200` (the post exists and the read cache is populated).
- DELETE status: `200`; body `{"message": "Post deleted"}`.
- Second GET status: `404`. The fresh 404 read proves the cache key was repointed to `{user_id}_post_cache` and the delete invalidated the same key the read populates (no stale 200).
- DB state: the `"post"` row with `id == post_id` has `is_deleted == True` and `deleted_at` set (verified via raw SQL on the overridden session factory).

**Covers requirement(s):** F1, F2, F13, F14, F15.

### Scenario 2: forbidden — a different user deletes the author's post under the author's id

**Setup:**

- DB contains `ep57_alice` (`id = alice_id`), `ep57_bob` (`id = bob_id`, `bob_id != alice_id`), and `ep57_alice_post` (`id = post_id`, `is_deleted = False`).
- `get_current_user` overridden to return bob's dict (`id == bob_id`).

**Act:**

- `await async_client.delete(f"/api/v1/{alice_id}/post/{post_id}")` (bob targets alice's id).

**Expect:**

- Status: `403`. `check_post_owner(bob_id, alice_id)` raises a bare `ForbiddenDomainError()`; the body carries the project's default 403 payload with no ownership-specific message.
- DB state: the `"post"` row with `id == post_id` still has `is_deleted == False` (the soft delete was never called — ownership fails before `find_post`/`soft_delete`).

**Covers requirement(s):** F5, F8, F16.

### Scenario 3: old route gone — string author segment yields 422

**Setup:**

- DB contains `ep57_alice` and `ep57_alice_post`; `get_current_user` override active (alice).

**Act:**

- `await async_client.delete(f"/api/v1/ep57alice/post/{post_id}")` (alice's username string in the author path segment).

**Expect:**

- Status: `422` (FastAPI cannot bind the non-integer segment to the `int`-typed `user_id` path parameter).
- DB state: the `"post"` row with `id == post_id` still has `is_deleted == False` (no delete applied).

**Covers requirement(s):** F9, F10.

## Out of scope for this test

- 404 for an unknown/soft-deleted `user_id` (F4) — covered by the use-case unit test and endpoint integration test; the exact payload is `{"error": {"code": "notfound", "message": "User not found"}}`.
- 404 for an unknown post id under the owner (F6) — covered by the use-case unit test and endpoint integration test; the exact payload is `{"error": {"code": "notfound", "message": "Post not found"}}`.
- 401 unauthenticated (F3) — covered by the endpoint integration test (the outside-in test always supplies the auth override).
- The 404(user)→403(owner)→404(post) ordering across all branches (F7) and the downstream-ports-not-called assertions (F8 in full) — covered by the use-case unit test.
- The `get_active_user_by_id` / `check_post_owner` usage details (F17) and the owner-scoped `find_post` filter (F18) — covered by the use-case unit test and the shared adapter unit test in slice 0032.
- `ErasePostAdapter` internals (F12) — unchanged; covered by the existing 0029 adapter test.
- Performance, load, concurrency.
