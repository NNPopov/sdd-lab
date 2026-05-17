# 0021 · list_posts_visibility — Outside-in test spec

## Goal

Prove that `GET /api/v1/{username}/posts` returns different result sets
depending on whether the caller is the post author, a different authenticated
user, or an unauthenticated visitor — and that every returned item carries the
`status` field.

## Entry point

Three calls to the same endpoint, with different authentication headers:

- **Method:** `GET`
- **Path:** `/{username}/posts` (registered under `/api/v1` in `bootstrap/router.py`)
- **Body:** none
- **Auth:** varies by scenario — no header, alice's Bearer token, bob's Bearer token

## Wired real

- FastAPI app from `create_app()` (full stack: middleware, exception handlers).
- `ListPostsAdapter` (the modified adapter with conditional `status` filter).
- `ListPostsPort` bound to the adapter in `Container`.
- `ListPostsUseCase` (thin pass-through).
- Test Postgres via the `db_session` fixture (transaction rollback per test).
- DI container with `session_factory` overridden to use the test transaction.

## Mocked

- **Redis / `@cache`:** the cache decorator is either disabled in the test
  environment or the test Postgres session override effectively bypasses it.
  If the decorator is active, a second identical request within 60 s might
  return a cached response — the test should account for this by using distinct
  request parameters or disabling the cache in the test app configuration.
  Check the existing 0009 test for the precedent used in this project.

Everything else runs against real components. No external HTTP APIs are involved.

## Fixtures used

- `client` (from `tests/conftest.py`): `httpx.AsyncClient` pointed at the app
  with the test transaction.
- `db_session` (from `tests/conftest.py`): per-test Postgres transaction, rolled
  back at teardown.
- **`alice_token`** (slice `conftest.py` or inline): register `alice` via
  `POST /api/v1/users`, then authenticate via the login endpoint to obtain a
  Bearer token.
- **`bob_token`** (slice `conftest.py` or inline): register `bob` via
  `POST /api/v1/users`, then authenticate via the login endpoint to obtain a
  Bearer token.
- **Three posts for alice** (inline in the test): created via the `create_post`
  endpoint authenticated as alice, all defaulting to `status = 'pending_review'`.
- **One approved post** (inline in the test): after the three posts are created,
  execute `UPDATE post SET status = 'approved' WHERE id = <one_post_id>` directly
  through `db_session` to bypass the moderation workflow.

## Test scenarios

### Scenario 1 — Unauthenticated caller sees only the approved post

**Setup:**

- DB contains: three posts by alice — two with `status = 'pending_review'`, one
  with `status = 'approved'` (set directly via `db_session`).
- No `Authorization` header on the request.

**Act:**

- `GET /api/v1/alice/posts` with no `Authorization` header.

**Expect:**

- Status: `200`.
- `total_count == 1`.
- `items` has exactly one element.
- That element has `status == "approved"`.
- That element has all standard fields present: `id`, `title`, `text`,
  `media_url`, `created_at`, `created_by_user_id`, `username`.
- DB state: unchanged (read-only request; all three posts still exist).

**Covers requirement(s):** F1, F5, F6.

---

### Scenario 2 — Author sees all three posts

**Setup:**

- Same DB state as Scenario 1 (three posts by alice, one approved).
- Request authenticated as alice (Bearer token).

**Act:**

- `GET /api/v1/alice/posts` with `Authorization: Bearer <alice_token>`.

**Expect:**

- Status: `200`.
- `total_count == 3`.
- `items` has exactly three elements.
- At least one item has `status == "pending_review"` and exactly one item has
  `status == "approved"`.
- Every item has a `status` field.
- DB state: unchanged.

**Covers requirement(s):** F3, F5.

---

### Scenario 3 — Different authenticated user sees only the approved post

**Setup:**

- Same DB state as Scenario 1 (three posts by alice, one approved).
- Request authenticated as bob (Bearer token for a user who is not alice).

**Act:**

- `GET /api/v1/alice/posts` with `Authorization: Bearer <bob_token>`.

**Expect:**

- Status: `200`.
- `total_count == 1`.
- `items` has exactly one element.
- That element has `status == "approved"`.
- Result is identical to Scenario 1.
- DB state: unchanged.

**Covers requirement(s):** F2, F5.

---

## Out of scope for this test

- Zero-approved-posts empty response (covered by endpoint integration test).
- Moderator/superuser as non-author (same code path as Scenario 3; covered by
  endpoint integration test).
- Pagination correctness under visibility filtering (covered by adapter unit test).
- `status` filter on the count query producing a correct `total_count` under
  pagination (covered by adapter unit test).
- Cache key split behavior (F12, F13) — verified by code review and, if needed,
  by a targeted endpoint integration test.
- `list_all_posts` adapter and schema changes (F16, F17) — verified by code review
  and the existing 0010 test suite remaining green.
- 0009 test pre-condition fix (F18) — verified by the 0009 outside-in test
  remaining green.
- Performance, concurrency, load.
