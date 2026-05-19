# 0030 · erase_db_post — Outside-in test spec

## Goal

Prove that a superuser can permanently remove a post row from the database
through `DELETE /api/v1/{username}/db_post/{id}`, that the ownership filter
prevents cross-namespace deletion, that a non-superuser is rejected before the
use case runs, and that the cache is invalidated so a subsequent `GET` returns
404.

## Entry point

- **Method:** `DELETE`
- **Path:** `/api/v1/{username}/db_post/{id}`
- **Path params:** `username` (owner's username), `id` (post primary key)
- **Body:** none
- **Auth:** Bearer token; must belong to a superuser

## Wired real

- FastAPI app from `create_app()` (full stack: middleware, exception handlers,
  `@cache` decorator).
- `EraseDbPostAdapter` (the slice's adapter).
- `EraseDbPostPort` bound to `EraseDbPostAdapter` in `Container`.
- `EraseDbPostUseCase`.
- Test Postgres via the `db_session` fixture (transaction rolled back after the
  test).
- DI container with `session_factory` overridden to use the test transaction.

## Mocked

None — the test runs entirely against the test database. The `@cache` decorator
is present but the test does not depend on Redis being available; even if the
cache is a no-op in the test environment, the DB-state and GET assertions prove
the invariant.

## Fixtures used

- `client` (from `tests/conftest.py`): `httpx.AsyncClient` with
  `ASGITransport(app=app)`, base URL `http://test`.
- `db_session`: the per-test transaction that rolls back on teardown.
- `alice_token` (slice `conftest.py`): creates a regular user `alice` inside
  the test transaction and returns a valid Bearer token for her.
- `admin_token` (slice `conftest.py`): creates a superuser `admin` inside the
  test transaction and returns a valid Bearer token for them.
- `alice_post_id` (slice `conftest.py`): uses `alice_token` to call
  `POST /api/v1/alice/post` and returns the integer `id` of the created post.
- `bob_token` (slice `conftest.py`): creates a second regular user `bob` inside
  the test transaction and returns a valid Bearer token (needed for scenario 2
  wrong-namespace check).

## Test scenarios

### Scenario 1: happy path — full acceptance flow

**Setup:**

- `alice` exists (regular user), `admin` exists (superuser).
- One post exists, created by `alice`, not soft-deleted; its ID is
  `alice_post_id`.

**Act (sequential steps):**

1. `GET /api/v1/alice/post/{alice_post_id}` with Alice's token → warms any
   cache that may be present.
2. `DELETE /api/v1/alice/db_post/{alice_post_id}` with admin's token.
3. `GET /api/v1/alice/post/{alice_post_id}` with Alice's token.

**Expect:**

- Step 1: status 200 (post is visible before deletion).
- Step 2: status 200; body exactly `{"message": "Post deleted from the database"}`.
- Step 3: status 404 (post is gone; stale cached data is not served).
- DB state after step 2: no row in `post` with `id == alice_post_id`
  (the row is permanently deleted, not merely soft-deleted — `is_deleted` flag
  check is insufficient; the row must not exist at all).

**Covers requirements:** F1, F4, F7, F10.

---

### Scenario 2: authorization enforcement — wrong namespace and wrong role

**Setup:**

- `alice` exists (regular user), `admin` exists (superuser), `bob` exists
  (regular user).
- One post exists, created by `alice`, not soft-deleted; its ID is
  `alice_post_id`.

**Act (sequential steps):**

1. `DELETE /api/v1/bob/db_post/{alice_post_id}` with admin's token (correct
   credentials, wrong username namespace).
2. `DELETE /api/v1/alice/db_post/{alice_post_id}` with alice's token
   (correct namespace, not a superuser).
3. `DELETE /api/v1/alice/db_post/{alice_post_id}` with admin's token
   (correct credentials, correct namespace — confirms the post survived steps
   1 and 2).

**Expect:**

- Step 1: status 404; body `{"message": "Post not found"}` (ownership filter
  returns `None` when `created_by_user_id` does not match `bob`'s `id`).
- Step 2: status 403 (`get_current_superuser` rejects Alice before the use
  case runs).
- Step 3: status 200; body `{"message": "Post deleted from the database"}`.
- DB state after step 1: the post row still exists (step 1 did not delete it).
- DB state after step 3: no row in `post` with `id == alice_post_id`.

**Covers requirements:** F3, F8, F11.

## Out of scope for this test

- User-not-found path (username resolves to nobody → 404) — covered by endpoint
  integration test.
- Soft-deleted post path (post exists but `is_deleted=True` → 404) — covered by
  endpoint integration test.
- Unauthenticated request (no token → 401) — covered by endpoint integration
  test.
- Individual `EraseDbPostAdapter` method variants (`get_user_by_username`
  returning `None`, `find_post` owner-mismatch cases) — covered by adapter unit
  test.
- Use-case branch logic in isolation — covered by use-case unit test.
- Performance, load, concurrency.
