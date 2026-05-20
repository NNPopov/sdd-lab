# 0031 · fix_erase_db_post_cascade — Outside-in test spec

## Goal

Prove that `DELETE /api/v1/{username}/db_post/{id}` permanently removes both the
`Post` row and all associated `PostModerationLog` rows when the target post has
moderation history, without breaking the no-logs case already covered in slice
0030.

## Entry point

The HTTP call the tests make (unchanged from slice 0030).

- **Method:** `DELETE`
- **Path:** `/api/v1/{username}/db_post/{id}`
- **Body:** none
- **Auth:** Bearer token (superuser) — injected via `dependency_overrides` on
  `get_current_user`

## Test file

**No new test file is created.** Both scenarios live in the existing acceptance
test:

```
tests/features/posts/0030_erase_db_post/erase_db_post_outside_in_test.py
```

Scenario 1 (`test_admin_hard_deletes_post_row_is_gone_and_get_returns_404`) is
**extended** to cover the cascade path. Scenario 2 is **unchanged**.

## Wired real

- FastAPI app from `app.main.app` (full stack: middleware, exception handlers).
- `EraseDbPostAdapter` (real adapter).
- `EraseDbPostUseCase` (real use-case).
- `EraseDbPostPort` binding from `Container`.
- Test Postgres via `oit_engine` (per the slice's `conftest.py`); savepoint
  transactions give per-test isolation with rollback.
- DI container with `session_factory` overridden to use the test transaction's
  connection.

## Mocked

- **Redis:** mocked via `mock_redis` in `async_client` fixture (already in
  place from slice 0030 conftest). `get` returns `None`; `scan` returns
  `(0, [])`. Prevents cache hits from masking deletion.
- **`get_current_user`:** overridden via
  `app.dependency_overrides[get_current_user] = lambda: _SUPERUSER` for
  superuser calls; reset in `finally`. This pattern is already in place in
  both scenarios.

## Fixtures used

- `async_client` — `httpx.AsyncClient` with savepoint isolation and mocked
  Redis. Defined in the slice's `conftest.py`.
- `ep30_alice` — seeds alice user (`username="ep30alice"`). Defined in the
  slice's `conftest.py`.
- `ep30_alice_post` — seeds an approved `Post` owned by alice. Returns a dict
  with `"id"`. Defined in the slice's `conftest.py`.
- `ep30_bob` — seeds bob user (used by Scenario 2 only, unchanged).

No new fixture is added for `PostModerationLog`. The moderation-log row is
seeded **inline** inside the extended Scenario 1, using a raw `INSERT` via
`session.execute(text(...))` through `container.session_factory()()`. This
keeps the fixture list minimal and the seeding intent explicit at the test call
site.

## Test scenarios

### Scenario 1 (extended): admin hard-deletes a post that has moderation logs

**Current state:** the test seeds and deletes alice's post, then asserts the
`post` row is gone and `GET` returns 404. No moderation log is seeded, so the
cascade path is not exercised.

**Extension:** before the `DELETE` call, seed one `PostModerationLog` row. After
the `DELETE` call, add a DB assertion that no `post_moderation_log` rows with
that `post_id` remain.

**Setup:**

- DB contains `ep30_alice` user and `ep30_alice_post` post (from fixtures).
- One `PostModerationLog` row is inserted inline: `post_id` = `ep30_alice_post["id"]`,
  `moderator_id` = any valid user id (use `ep30_alice["id"]` for simplicity),
  `action` = `"approve"`, `note` = `"seeded for cascade test"`. Capture the
  inserted log's `id` as `log_id`.
- `get_current_user` dependency overridden to return `_SUPERUSER`.

**Act:**

- `await async_client.delete("/api/v1/ep30alice/db_post/{post_id}")` with
  superuser auth override.

**Expect:**

- Status: `200`.
- Response body: `{"message": "Post deleted from the database"}`.
- DB state — `post` table: no row with `id == post_id` (row is permanently
  deleted, not soft-deleted).
- DB state — `post_moderation_log` table: no row with `post_id == post_id`
  (cascade deleted the child rows alongside the parent).
- Subsequent `GET /api/v1/ep30alice/post/{post_id}`: status `404` (cache
  invalidated).

**Covers requirements:** F1, F2, F3, F4 (cascade), N1, N2.

---

### Scenario 2 (unchanged): wrong namespace → 404; non-superuser → 403; correct delete → 200

No moderation log is seeded for this scenario. The cascade path is not
relevant; the test exercises authorization and ownership enforcement only.

**Setup:**

- DB contains `ep30_alice`, `ep30_bob`, `ep30_alice_post` (from fixtures).
- No `PostModerationLog` rows.

**Act (three sequential sub-steps):**

1. Superuser targets alice's post via `bob`'s namespace.
2. Alice (non-superuser) targets her own post via her namespace.
3. Superuser targets alice's post via alice's namespace (correct).

**Expect:**

- Sub-step 1: status `404`, body `{"error": {"code": "notfound", "message": "Post not found"}}`. Post row still exists.
- Sub-step 2: status `403`. Post row still exists.
- Sub-step 3: status `200`, body `{"message": "Post deleted from the database"}`. Post row permanently gone.

**Covers requirements:** F1, F5, F6, F7, F8.

---

## Out of scope for this test

- Seeding multiple moderation log rows (one is sufficient to prove the cascade;
  exhaustive volume testing is not the outside-in test's job).
- Verifying that `lazy="raise"` raises `InvalidRequestError` when accidentally
  triggered — that is an adapter unit test concern.
- HTTP contract variations (401, wrong `Content-Type`) — covered by the
  endpoint integration test in `presentation/test_router.py`.
- Adapter-level exception translation — covered by adapter unit test in
  `data/test_adapter.py`.
- Performance or concurrency under load.
