# 0026 · get_post — Outside-in test spec

## Goal

Prove that `GET /api/v1/{username}/post/{id}` enforces the full access-control
policy end-to-end: unapproved posts are hidden from non-authors and
non-privileged callers, bypassed for authors and moderators, and publicly
visible once approved — all through the real adapter, the real exception
handlers, and the test Postgres.

## Entry point

- **Method:** `GET`
- **Path:** `/api/v1/{username}/post/{id}` (path params resolved per scenario)
- **Body:** none
- **Auth:** optional Bearer token; varies per scenario

## Wired real

- FastAPI app from `create_app()` — full stack including middleware and
  exception handlers.
- `GetPostAdapter` — issues the JOIN query against the test Postgres.
- `GetPostPort` — bound to `GetPostAdapter` in the DI container.
- `GetPostUseCase` — applies access-control logic against the returned
  `PostItem`.
- Test Postgres via the `db_session` fixture (transaction rolled back after
  each test).
- DI container with `session_factory` overridden to use the test
  transaction's connection.

## Mocked

- **Redis (cache):** the `@cache` decorator is patched to be a no-op (or a
  test Redis instance is used). Caching correctness is out of scope for this
  test; functional coverage is the concern. Patch via
  `mocker.patch("app.adapters.cache.redis_cache.cache", side_effect=lambda *a, **kw: lambda f: f)`
  or equivalent no-op wrapper if a test Redis is not available in CI.

## Fixtures used

- `client` (from `tests/conftest.py`): `httpx.AsyncClient` against the app
  with the test Postgres transaction.
- `db_session` (from `tests/conftest.py`): per-test async session; used
  directly in Scenario 2 to mutate `post.status` without going through the
  HTTP layer.
- **Slice-level fixtures** (in
  `tests/features/posts/0026_get_post/conftest.py`):
  - `alice` — a non-deleted user row with `username="alice"`.
  - `alice_token` — a valid Bearer token for `alice` (obtained via
    `POST /api/v1/auth/login`).
  - `bob` — a non-deleted user row with `username="bob"` (non-author,
    non-privileged).
  - `bob_token` — Bearer token for `bob`.
  - `carol` — a non-deleted user row with `username="carol"`,
    `is_moderator=True`.
  - `carol_token` — Bearer token for `carol`.
  - `pending_post` — a `post` row owned by `alice` with
    `status="pending_review"` and `is_deleted=False`, seeded via the
    `POST /api/v1/alice/posts` endpoint using `alice_token` (so the
    `created_by_user_id` FK is correct).

---

## Test scenarios

### Scenario 1 — Access control for a pending post

**Setup:**

- DB contains users `alice`, `bob`, and `carol` (moderator).
- DB contains `pending_post` owned by `alice` with `status="pending_review"`.

**Act and expect (sequential steps within one test):**

1. `GET /api/v1/users/alice/post/{pending_post.id}` — no `Authorization` header.
   - Expected status: `404`.
   - Expected body: `{"message": "Post not found"}`.

2. `GET /api/v1/users/alice/post/{pending_post.id}` — `Authorization: Bearer bob_token`.
   - Expected status: `404`.
   - Expected body: `{"message": "Post not found"}`.

3. `GET /api/v1/users/alice/post/{pending_post.id}` — `Authorization: Bearer alice_token`.
   - Expected status: `200`.
   - Expected body fields: `status == "pending_review"`, `username == "alice"`,
     `id == pending_post.id`, `post_uuid` is a non-empty string.

4. `GET /api/v1/users/alice/post/{pending_post.id}` — `Authorization: Bearer carol_token`.
   - Expected status: `200`.
   - Expected body: `status == "pending_review"`.

**DB state after:** unchanged from setup (GET endpoint, no side effects).

**Covers requirements:** F2, F3, F4, F5, F7, F8, F9, F10, F15, F16, F17.

---

### Scenario 2 — Approved post becomes publicly visible

**Setup:**

- DB contains user `alice` and `pending_post` with `status="pending_review"`.
- Directly update `pending_post.status = "approved"` in the test DB via
  `db_session` (bypasses the HTTP layer; simulates a moderator approval that
  occurred earlier).

**Act and expect (sequential steps within one test):**

1. `GET /api/v1/users/alice/post/{pending_post.id}` — no `Authorization` header.
   - Expected status: `200`.
   - Expected body fields: `status == "approved"`, `username == "alice"`,
     `post_uuid` non-empty, `title` and `text` match the seeded values.

2. `GET /api/v1/users/unknown_xyz/post/{pending_post.id}` — no auth.
   - Expected status: `404`.
   - Expected body: `{"message": "Post not found"}`.

3. `GET /api/v1/users/alice/post/99999` — no auth.
   - Expected status: `404`.
   - Expected body: `{"message": "Post not found"}`.

**DB state after:** unchanged from setup (GET endpoint, no side effects).

**Covers requirements:** F1, F5, F6, F13, F15, F16.

---

## Out of scope for this test

- Field-level Pydantic validation errors — covered by the endpoint integration
  test.
- Adapter-level exception translation — not applicable (adapter has no
  `try/except`; covered by the read-only path in the adapter unit test).
- `changes_requested` status matrix (author and privilege bypass) — covered in
  detail by the use-case unit test and the endpoint integration test.
- Soft-deleted post visibility — covered by the adapter unit test and endpoint
  integration test.
- Cache key compatibility with `patch_post` / `erase_post` — covered by
  manual scenario S14 in `validation.md`.
- Superuser bypass — functionally identical to moderator bypass (F11); covered
  by the endpoint integration test.
- Performance, concurrency, load.
