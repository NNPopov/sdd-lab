# 0022 · list_all_posts_visibility — Outside-in test spec

## Goal

Prove that `GET /api/v1/posts` returns only `approved` posts to non-privileged
callers and all posts to privileged callers (moderators), with the `status`
field populated on every item.

## Entry point

- **Method:** `GET`
- **Path:** `/api/v1/posts`
- **Body:** none
- **Auth:** Optional Bearer token (none, regular user, moderator — tested separately
  across scenarios).

## Wired real

- FastAPI app (full stack: middleware, exception handlers).
- `ListAllPostsAdapter` — reads from the test Postgres, applies the conditional status
  filter.
- `ListAllPostsPort` — bound to the adapter in `Container`.
- `ListAllPostsUseCase` — thin pass-through; wired real to prove composition holds.
- Test Postgres via the per-test transaction (savepoint rollback on teardown).
- DI container with `session_factory` overridden to use the test transaction so the
  adapter and the fixture share the same connection.
- `get_optional_user` dependency — wired real; uses the test app's JWT verification
  against tokens minted during setup.

## Mocked

- **Redis client (`app.adapters.cache.redis_cache.client`):** replaced with an
  `AsyncMock` whose `get` returns `None` (simulates a cache miss on every request).
  This prevents `MissingClientError` and ensures the adapter is always called, making
  assertions on DB state meaningful.

## Fixtures used

- `oit_engine` (in slice `conftest.py`): per-test async engine; creates the schema via
  `Base.metadata.create_all`, disposed on teardown. Same pattern as
  `tests/features/posts/0010_list_all_posts/conftest.py`.
- `async_client` (in slice `conftest.py`): `httpx.AsyncClient` wired to the app with
  a savepoint transaction and the Redis mock in place.
- `seed_data` (in slice `conftest.py`): seeds the following rows through a combination
  of HTTP calls (for realistic token/auth state) and direct DB writes (for the status
  update that has no HTTP endpoint in this slice):
  - A superuser (`oit22super`, `oit22super@example.com`) created directly via the
    session factory (bypasses HTTP; gives a controllable `is_superuser=True` row).
  - `alice` registered via `POST /api/v1/users` and authenticated; her Bearer token
    is stored for use in Scenario 2.
  - Three posts created by `alice` via `POST /api/v1/posts`; all default to
    `status='pending_review'`.
  - One of the three posts updated to `status='approved'` directly via the session
    factory (no HTTP endpoint for status update exists outside the moderation flow;
    this direct write mirrors the technique used in the 0021 outside-in test).
  - `mod` registered via `POST /api/v1/users`, then promoted to moderator via
    `POST /api/v1/users/mod22/moderator` using the superuser Bearer token (obtained by
    calling `POST /api/v1/auth/login` for the superuser). `mod`'s Bearer token is
    stored for use in Scenario 3.

## Test scenarios

### Scenario 1 — Unauthenticated caller sees only the approved post

**Setup:**

- DB contains three posts for `alice`: one with `status='approved'`, two with
  `status='pending_review'` (from `seed_data` fixture).
- No `Authorization` header is sent.

**Act:**

- `GET /api/v1/posts` with no auth header, default pagination (`page=1`,
  `items_per_page=10`).

**Expect:**

- Status: `200`.
- `total_count == 1`.
- `len(items) == 1`.
- `items[0]["status"] == "approved"`.
- No item with `status == "pending_review"` appears in `items`.
- Every item carries the `status` key.

**Covers requirements:** F1, F2, F6, F7 (the single-item variant), F8.

---

### Scenario 2 — Authenticated regular user sees only the approved post

**Setup:**

- Same DB state as Scenario 1.
- `alice`'s Bearer token is available from `seed_data`.

**Act:**

- `GET /api/v1/posts` with `Authorization: Bearer <alice_token>`.

**Expect:**

- Status: `200`.
- `total_count == 1`.
- `len(items) == 1`.
- `items[0]["status"] == "approved"`.
- No item with `status == "pending_review"` appears.

**Covers requirements:** F1, F3, F6, F8.

---

### Scenario 3 — Moderator sees all three posts regardless of status

**Setup:**

- Same DB state as Scenario 1 (three posts: one `approved`, two `pending_review`).
- `mod`'s Bearer token is available from `seed_data`; `mod` has `is_moderator=True`.

**Act:**

- `GET /api/v1/posts` with `Authorization: Bearer <mod_token>`.

**Expect:**

- Status: `200`.
- `total_count == 3`.
- `len(items) == 3`.
- Items include at least one post with `status == "pending_review"` and one with
  `status == "approved"`.
- Every item carries the `status` key.

**Covers requirements:** F1, F4, F6, F8.

---

## Out of scope for this test

- Superuser visibility (`is_superuser=True`) — covered by the endpoint integration
  test; the privilege logic is identical to the moderator path and does not warrant a
  separate outside-in scenario.
- Empty result (`total_count == 0`) — covered by the endpoint integration test.
- `items_per_page` / `page` pagination behaviour — covered by the 0010 outside-in
  test which already seeded and paginated the full list.
- Cache key segmentation — not observable via HTTP; covered by the code review
  checklist in `validation.md`.
- Field-level response schema validation beyond the `status` field — covered by the
  endpoint integration test.
- Specific SQLAlchemy exception handling — the adapter has no `try/except`; nothing to
  test there.
- Performance, load, concurrency.
