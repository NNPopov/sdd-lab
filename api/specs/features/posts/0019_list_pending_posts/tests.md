# 0019 · list_pending_posts — Outside-in test spec

## Goal

Prove that a moderator calling `GET /api/v1/posts/pending` receives a
paginated list of non-terminal posts with the full moderation log attached,
and that a non-moderator receives HTTP 403.

## Entry point

- **Method:** `GET`
- **Path:** `/api/v1/posts/pending`
- **Query params:** `page=1&items_per_page=10` (defaults accepted in happy path)
- **Auth:** Bearer token for the moderator user (Scenario 1); Bearer token for
  a regular user (Scenario 2).

## Wired real

- FastAPI app from `create_app()` (full stack: middleware, exception handlers).
- `ListPendingPostsAdapter` — queries the test Postgres directly.
- `ListPendingPostsPort` — bound to `ListPendingPostsAdapter` in `Container`.
- `ListPendingPostsUseCase` — wired to the port.
- `ModeratePostAdapter` / `ModeratePostUseCase` — used by the setup step that
  calls `POST /api/v1/posts/{uuid}/moderate` to add a log entry.
- `RevisePostAdapter` / `RevisePostUseCase` — used by the setup step that
  calls `PATCH /api/v1/posts/{uuid}/revise` to add a second log entry.
- `CreateUserAdapter` / `CreateUserUseCase` — used to create the author and
  moderator users via the API.
- Test Postgres via the `db_session` fixture (transaction rollback per test).
- DI container with `session_factory` overridden to use the test transaction.

## Mocked

None — the test runs entirely against the test database.

## Fixtures used

- `client` (from `tests/conftest.py`): the `httpx.AsyncClient` against the app
  with `session_factory` overridden to the test transaction session.
- `db_session` (from `tests/conftest.py`): per-test async session; transaction
  rolls back at teardown.
- The test creates all required rows through HTTP calls; no pre-seeded fixture
  rows are needed beyond what the test itself creates.

## Test scenarios

### Scenario 1: happy path — moderator sees the pending queue with full log

**Setup:**

1. Create a regular author user by calling
   `POST /api/v1/users` with body
   `{"username": "author_bob", "email": "bob@example.com", "password": "Pa$$w0rd1"}`.
   Record the returned `id` as `author_id`.

2. Create a moderator user by calling
   `POST /api/v1/users` with body
   `{"username": "mod_alice", "email": "alice@example.com", "password": "Pa$$w0rd2"}`.
   Record the returned `id` as `moderator_id`.
   Then promote `mod_alice` to moderator by setting `is_moderator = True`
   directly on the user row in the test DB via `db_session` (same technique used
   in `moderate_post` outside-in test — see
   `tests/features/posts/0017_moderate_post/moderate_post_outside_in_test.py`).

3. Authenticate as `author_bob` via `POST /api/v1/auth/login` to obtain
   `AUTHOR_TOKEN`.

4. Authenticate as `mod_alice` via `POST /api/v1/auth/login` to obtain
   `MODERATOR_TOKEN`.

5. Create a post as `author_bob` by calling `POST /api/v1/posts` (or the
   existing create-post endpoint) with a title and body text.
   Record the returned `post_uuid`.

6. As `mod_alice`, call `POST /api/v1/posts/{post_uuid}/moderate` with
   body `{"action": "changes_requested", "message": "Please clarify section 2."}`.
   This creates log entry 1 and moves the post to `changes_requested`.

7. As `author_bob`, call `PATCH /api/v1/posts/{post_uuid}/revise` with body
   `{"message": "Clarified section 2."}`.
   This creates log entry 2 and returns the post to `pending_review`.

**Act:**

- As `mod_alice`, call `GET /api/v1/posts/pending`.

**Expect:**

- Status: `200`.
- Response body has `total_count = 1`, `page = 1`, `items_per_page = 10`.
- `items` contains exactly one entry.
- The entry has:
  - `post_uuid` matching the post created in step 5.
  - `status` equal to `"pending_review"`.
  - `author_username` equal to `"author_bob"`.
  - `moderation_log` with exactly 2 entries in chronological order:
    - Entry 0: `event_type = "moderator_review"`,
      `action = "changes_requested"`,
      `message = "Please clarify section 2."`.
    - Entry 1: `event_type = "author_revision"`,
      `action = null`,
      `message = "Clarified section 2."`.
  - Entry 1 `created_at` is strictly later than entry 0 `created_at`.

- **DB state:** one `post_moderation_log` row per setup step (6 and 7) exists
  for the post UUID; the post row has `status = "pending_review"`.

**Covers requirements:** F1, F2, F3, F4, F5, F9, F10, F11, F17.

---

### Scenario 2: 403 when caller is not a moderator or superuser

**Setup:**

1. Create a regular user by calling
   `POST /api/v1/users` with body
   `{"username": "plain_user", "email": "plain@example.com", "password": "Pa$$w0rd3"}`.

2. Authenticate as `plain_user` via `POST /api/v1/auth/login` to obtain
   `PLAIN_TOKEN`.

**Act:**

- Call `GET /api/v1/posts/pending` with `Authorization: Bearer <PLAIN_TOKEN>`.

**Expect:**

- Status: `403`.
- Response body: `{"message": "You do not have enough privileges."}` (the
  message emitted by `get_current_moderator_or_superuser` before the use-case
  is reached) — or the equivalent message if `ForbiddenDomainError` fires from
  the use case; either path produces HTTP 403.

- **DB state:** unchanged (no writes occur in this scenario).

**Covers requirements:** F14, F16.

---

## Out of scope for this test

- 401 for unauthenticated requests (covered by endpoint integration test).
- Pagination mechanics — `total_count` accuracy and page offset behaviour
  (covered by adapter unit test).
- Soft-deleted post and soft-deleted-user exclusion (covered by adapter unit
  test).
- `approved` post exclusion (covered by adapter unit test and endpoint
  integration test).
- `items_per_page` / `page` query-param validation errors (422) — covered
  by endpoint integration test.
- Superuser access (covered by endpoint integration test).
- Ordering of items newest-first within a page (covered by adapter unit test).
- Specific SQLAlchemy exception propagation (covered by adapter unit test,
  which asserts no catch exists).
- Performance, load, concurrency.
