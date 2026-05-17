# 0011 · create_post — Outside-in test spec

## Goal

Prove that an authenticated user can create a post under their own username via
`POST /api/v1/{username}/post` and receive the created post in the response, and that
the ownership guard correctly rejects a request where the requester's username differs
from the path username.

## Entry point

- **Method:** `POST`
- **Path:** `/api/v1/{username}/post`
- **Body:** `CreatePostRequest` — `{"title": str, "text": str, "media_url": str | None}`
- **Auth:** Bearer token via the `get_current_user` dependency (overridden in the test —
  see Fixtures used).

## Wired real

- FastAPI app from `create_application()` (full stack: middleware, exception handlers).
- `CreatePostAdapter` — executes real SQL against the test Postgres.
- `CreatePostPort` — bound to `CreatePostAdapter` via `Container`.
- `CreatePostUseCase` — real instance; exercises user lookup and ownership check.
- Test Postgres via the `db_session` fixture (transaction rollback per test).
- DI container with `session_factory` overridden to use the test transaction's session.

## Mocked

- **`get_current_user` dependency:** overridden via FastAPI's `app.dependency_overrides`
  to return a fixed `dict` representing the authenticated user without performing a real
  JWT verification or `crud_users` lookup. This keeps auth (a separate feature) out of
  scope for this slice's acceptance test.
- **Redis / cache:** not touched by this slice; no mock needed.
- **Clock:** not needed; `created_at` is asserted to be a non-null datetime, not an exact
  value.

## Fixtures used

- `client` (from `tests/conftest.py`): `httpx.AsyncClient` against the app with
  `session_factory` overridden to use the test transaction.
- `db_session` (from `tests/conftest.py`): per-test transaction, rolled back at teardown.
- `seeded_user` (slice `conftest.py`): inserts one active user row directly into the test
  DB via `db_session` and returns a dict with at least `{"id": int, "username": "alice",
  "is_deleted": False}`. Username is `"alice"`.
- `override_current_user` (slice `conftest.py`): installs an `app.dependency_overrides`
  entry for `get_current_user` that returns a fixed dict matching the seeded user
  (`{"id": <alice.id>, "username": "alice", "is_superuser": False}`), then cleans up
  after the test.

## Test scenarios

### Scenario 1: happy path — create post under own username

**Setup:**

- DB contains one active user: `username="alice"`, `is_deleted=False`.
- `get_current_user` override returns `{"id": <alice.id>, "username": "alice",
  "is_superuser": False}`.

**Act:**

- `POST /api/v1/alice/post` with body
  `{"title": "Hello world", "text": "My first post.", "media_url": null}`.

**Expect:**

- Status: `201`.
- Response body is valid JSON matching `CreatePostResponse`:
  - `id` is an integer.
  - `title == "Hello world"`.
  - `text == "My first post."`.
  - `media_url` is `null`.
  - `created_by_user_id == alice.id`.
  - `created_at` is a non-null ISO 8601 datetime string.
  - No extra fields (`uuid`, `is_deleted`, `updated_at`, `deleted_at`) appear.
- DB state: a row exists in the `post` table with `title="Hello world"` and
  `created_by_user_id=alice.id` and `is_deleted=False`.

**Covers requirement(s):** F1, F6, F9, F10, F13, F14.

---

### Scenario 2: ownership mismatch — requester differs from path username

**Setup:**

- DB contains two active users: `username="alice"` and `username="bob"`.
- `get_current_user` override returns `{"id": <bob.id>, "username": "bob",
  "is_superuser": False}` (bob is the authenticated requester).

**Act:**

- `POST /api/v1/alice/post` with body
  `{"title": "Intruder title", "text": "Intruder text."}`.

**Expect:**

- Status: `403`.
- Response body: `{"message": "You can only post under your own username"}`.
- DB state: no new row in the `post` table (no post was created).

**Covers requirement(s):** F8.

## Out of scope for this test

- Field-level validation errors (422 for missing `title`, `text`, extra fields) — covered
  by the endpoint integration test.
- The `NotFoundDomainError` path (unknown username → 404) — covered by the endpoint
  integration test and use-case unit test; the outside-in DB state assertion for the happy
  path already exercises the user lookup code path.
- Adapter-level DB failure paths (e.g. `OperationalError` propagation) — covered by the
  adapter unit test.
- Soft-deleted user returning `None` — covered by the adapter unit test.
- Absence of `write_post` handler — covered by the endpoint integration test routing check.
- Performance, load, concurrency.
