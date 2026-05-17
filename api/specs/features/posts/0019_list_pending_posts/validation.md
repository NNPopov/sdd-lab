# 0019 · list_pending_posts — Validation

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md
- Requirements: ./requirements.md

## Prerequisites

- App running locally (`uvicorn app.main:app --reload` from `src/`).
- Test database seeded. Use the scripts:
  ```
  python -m scripts.create_first_superuser   # creates a superuser
  python -m scripts.create_first_tier        # creates default tier
  ```
- A regular user, a moderator user, and a superuser exist.
  The moderator can be promoted via `POST /api/v1/users/{username}/assign-moderator`
  using a superuser token.
- Valid Bearer tokens for: an unauthenticated request (no token), a regular
  user, a moderator, and a superuser.  Obtain tokens via
  `POST /api/v1/auth/login` (or equivalent login endpoint).
- At least one post seeded in `pending_review` status (all new posts start
  there).

---

## Manual scenarios

### S1 — Happy path: moderator retrieves pending queue

**Setup:** One post exists in `pending_review` status created by a regular
author.

**Steps:**

```bash
curl -X GET "http://localhost:8000/api/v1/posts/pending" \
  -H "Authorization: Bearer <MODERATOR_TOKEN>"
```

**Expected:**

- Status 200.
- Body has shape:
  ```json
  {
    "items": [
      {
        "post_uuid": "<uuid>",
        "title": "...",
        "text": "...",
        "media_url": null,
        "status": "pending_review",
        "created_at": "<iso8601>",
        "updated_at": null,
        "author_username": "<author>",
        "moderation_log": []
      }
    ],
    "total_count": 1,
    "page": 1,
    "items_per_page": 10
  }
  ```
- `author_username` is the actual username of the post's creator.

**Covers:** F1, F2, F3, F10, F17.

---

### S2 — Superuser can access the queue

**Setup:** Same as S1.

**Steps:**

```bash
curl -X GET "http://localhost:8000/api/v1/posts/pending" \
  -H "Authorization: Bearer <SUPERUSER_TOKEN>"
```

**Expected:**

- Status 200.
- Response shape identical to S1.

**Covers:** F1, F18.

---

### S3 — Unauthenticated request returns 401

**Steps:**

```bash
curl -X GET "http://localhost:8000/api/v1/posts/pending"
```

**Expected:**

- Status 401.

**Covers:** F15.

---

### S4 — Regular user (non-moderator) returns 403

**Steps:**

```bash
curl -X GET "http://localhost:8000/api/v1/posts/pending" \
  -H "Authorization: Bearer <REGULAR_USER_TOKEN>"
```

**Expected:**

- Status 403.

**Covers:** F16.

---

### S5 — Approved post is excluded from the queue

**Setup:**
1. Create a post (status becomes `pending_review`).
2. Moderate it to `approved` via:
   ```bash
   curl -X POST "http://localhost:8000/api/v1/posts/<UUID>/moderate" \
     -H "Authorization: Bearer <MODERATOR_TOKEN>" \
     -H "Content-Type: application/json" \
     -d '{"action": "approved"}'
   ```

**Steps:**

```bash
curl -X GET "http://localhost:8000/api/v1/posts/pending" \
  -H "Authorization: Bearer <MODERATOR_TOKEN>"
```

**Expected:**

- The approved post does **not** appear in `items`.
- `total_count` does not count it.

**Covers:** F5.

---

### S6 — `changes_requested` post appears in the queue

**Setup:**
1. Create a post (status `pending_review`).
2. Moderate it to `changes_requested`:
   ```bash
   curl -X POST "http://localhost:8000/api/v1/posts/<UUID>/moderate" \
     -H "Authorization: Bearer <MODERATOR_TOKEN>" \
     -H "Content-Type: application/json" \
     -d '{"action": "changes_requested", "message": "Please add more detail."}'
   ```

**Steps:**

```bash
curl -X GET "http://localhost:8000/api/v1/posts/pending" \
  -H "Authorization: Bearer <MODERATOR_TOKEN>"
```

**Expected:**

- The post appears with `"status": "changes_requested"`.

**Covers:** F5.

---

### S7 — Moderation log is populated and ordered oldest-first

**Setup:**
1. Create a post (status `pending_review`).
2. Moderator requests changes (log entry 1).
3. Author revises the post via `PATCH /api/v1/posts/<UUID>/revise` (log entry 2,
   status returns to `pending_review`).

**Steps:**

```bash
curl -X GET "http://localhost:8000/api/v1/posts/pending" \
  -H "Authorization: Bearer <MODERATOR_TOKEN>"
```

**Expected:**

- The post item has `moderation_log` with two entries.
- First entry: `event_type = "moderator_review"`, `action = "changes_requested"`.
- Second entry: `event_type = "author_revision"`, `action = null`.
- Second entry `created_at` is later than first entry `created_at`.

**Covers:** F4, F9.

---

### S8 — Empty queue returns 200 with zero items

**Setup:** No posts in `pending_review` or `changes_requested` exist (or database
is freshly reset).

**Steps:**

```bash
curl -X GET "http://localhost:8000/api/v1/posts/pending" \
  -H "Authorization: Bearer <MODERATOR_TOKEN>"
```

**Expected:**

- Status 200.
- Body: `{"items": [], "total_count": 0, "page": 1, "items_per_page": 10}`.

**Covers:** F11.

---

### S9 — Pagination: second page

**Setup:** Create 12 posts in `pending_review` status.

**Steps:**

```bash
# Page 1 — should return 10 items
curl -X GET "http://localhost:8000/api/v1/posts/pending?page=1&items_per_page=10" \
  -H "Authorization: Bearer <MODERATOR_TOKEN>"

# Page 2 — should return 2 items
curl -X GET "http://localhost:8000/api/v1/posts/pending?page=2&items_per_page=10" \
  -H "Authorization: Bearer <MODERATOR_TOKEN>"
```

**Expected (page 1):**

- Status 200, `items` has 10 entries, `total_count = 12`, `page = 1`,
  `items_per_page = 10`.

**Expected (page 2):**

- Status 200, `items` has 2 entries, `total_count = 12`, `page = 2`.

**Covers:** F12, F13.

---

### S10 — Posts are ordered newest-first

**Setup:** Create two posts sequentially so they have different `created_at`
values.

**Steps:**

```bash
curl -X GET "http://localhost:8000/api/v1/posts/pending" \
  -H "Authorization: Bearer <MODERATOR_TOKEN>"
```

**Expected:**

- The post created later appears first in `items`.

**Covers:** F8.

---

### S11 — Invalid `page` parameter returns 422

**Steps:**

```bash
curl -X GET "http://localhost:8000/api/v1/posts/pending?page=0" \
  -H "Authorization: Bearer <MODERATOR_TOKEN>"
```

**Expected:**

- Status 422.

**Covers:** F19.

---

### S12 — `items_per_page` exceeding 100 returns 422

**Steps:**

```bash
curl -X GET "http://localhost:8000/api/v1/posts/pending?items_per_page=101" \
  -H "Authorization: Bearer <MODERATOR_TOKEN>"
```

**Expected:**

- Status 422.

**Covers:** F20.

---

### S13 — Soft-deleted post is excluded

**Setup:**
1. Create a post (status `pending_review`).
2. Soft-delete it via `DELETE /{username}/post/{id}` (or set `is_deleted=True`
   directly in the DB).

**Steps:**

```bash
curl -X GET "http://localhost:8000/api/v1/posts/pending" \
  -H "Authorization: Bearer <MODERATOR_TOKEN>"
```

**Expected:**

- The soft-deleted post does not appear in `items`.
- It is not counted in `total_count`.

**Covers:** F6.

---

### S14 — Post by soft-deleted user is excluded

**Setup:**
1. Create a post under a regular author.
2. Soft-delete the author (set `is_deleted=True` on the user row directly in
   the DB or via the delete-user endpoint).

**Steps:**

```bash
curl -X GET "http://localhost:8000/api/v1/posts/pending" \
  -H "Authorization: Bearer <MODERATOR_TOKEN>"
```

**Expected:**

- The post is absent from `items` and not counted in `total_count`.

**Covers:** F7.

---

## Code review checklist

### Architecture

- [ ] Slice folder exists at `src/app/features/posts/list_pending_posts/` with
      `domain/`, `data/`, and `presentation/` subfolders each containing
      `__init__.py`.
- [ ] `ListPendingPostsUseCase` is a class with a single public method
      `__call__(self, query: ListPendingPostsQuery) -> PendingPostPage`.
- [ ] `ListPendingPostsPort` lives in `domain/ports/list_pending_posts_port.py`,
      carries `@runtime_checkable`, and inherits from `typing.Protocol`.
- [ ] `class ListPendingPostsAdapter(ListPendingPostsPort):` — explicit
      inheritance from the port is present (greppability + reader intent).
- [ ] `ListPendingPostsAdapter` is the only place SQLAlchemy is used in this
      slice; no SQL in the use-case or router.
- [ ] Router builds `ListPendingPostsQuery` from query params + the resolved
      `current_user` dict, awaits the use-case, and returns
      `ListPendingPostsResponse`. No business logic in the router.
- [ ] No cross-slice imports; `PendingModerationLogEntry`, `PendingPostItem`,
      and `PendingPostPage` are defined fresh in this slice's
      `domain/entities.py`, not imported from `moderate_post` or `revise_post`.
- [ ] All imports inside `src/app/features/posts/list_pending_posts/` are
      **relative**. No `from app...` or `from src.app...` anywhere in source.
- [ ] No `HTTPException` raised in `ListPendingPostsUseCase`.
- [ ] `ListPendingPostsUseCase.__call__` raises only `ForbiddenDomainError`;
      no other exception type is raised or caught inside the use-case.

### Error handling

- [ ] `ListPendingPostsAdapter.list()` has **no `try/except`** — this is a
      read-only operation with no business-meaningful exception path per
      `agent_docs/error_handling.md` § Right shape: read-only query, no catch.
- [ ] No broad `except Exception` block anywhere in this slice.
- [ ] Adapter does not log exceptions.
- [ ] No new `DomainError` subclass was added inside the slice folder; all
      domain errors remain in `app/domain/errors.py`.

### Files and headers

- [ ] Every new `.py` file (except empty `__init__.py`) starts with
      `# FEATURE: list_pending_posts — <purpose>` on line 1.
- [ ] No STABLE file was modified beyond `bootstrap/container.py` (two
      imports + two providers) and `features/posts/router.py`
      (one import + one `include_router` call).
- [ ] `ListPendingPostsResponse`, `PendingPostItemSchema`, and
      `PendingModerationLogEntrySchema` all carry
      `model_config = ConfigDict(from_attributes=True)`.
- [ ] No `model.dict()` usage — only `model.model_dump()` if used.

### DI wiring

- [ ] `list_pending_posts_adapter = providers.Factory(ListPendingPostsAdapter,
      session_factory=session_factory)` added to `Container`.
- [ ] `list_pending_posts_use_case = providers.Factory(ListPendingPostsUseCase,
      port=list_pending_posts_adapter)` added to `Container`.
- [ ] Router uses the **lazy-import helper** pattern
      (`_get_list_pending_posts_use_case` function importing `container` from
      `bootstrap.container`), consistent with `moderate_post` and `revise_post`.
      No `wiring_config.modules` entry is required for this pattern.
- [ ] `list_pending_posts_router` imported and `include_router`'d in
      `features/posts/router.py`. `bootstrap/router.py` is **not** touched.

### Adapter correctness

- [ ] The adapter runs exactly two queries: one count + paginated posts query
      (JOIN `Post` + `User`, filter status IN, exclude soft-deleted, ORDER BY
      `created_at DESC`, OFFSET + LIMIT), and one bulk log query (IN list of
      post IDs, ORDER BY `created_at ASC`). No per-post log query.
- [ ] Both queries share one `async with self._session_factory() as session:`
      context.
- [ ] Log entries are merged in Python (not via a nested query loop).
- [ ] `updated_at` is allowed to be `None` in `PendingPostItem` (posts that
      have never been revised have `updated_at = null`).

### Tests

- [ ] Use-case unit test covers: `requester_is_privileged=False` →
      `ForbiddenDomainError`; happy path with mocked port.
- [ ] Adapter unit test uses a real async session against test Postgres and
      covers: status filter (approved excluded), soft-deleted post excluded,
      soft-deleted-user post excluded, log ordering, pagination,
      empty-queue response.
- [ ] Endpoint integration test uses `httpx.AsyncClient` and covers: 200
      (moderator), 200 (superuser), 401, 403, approved-post exclusion,
      empty queue, 422 for bad query params.
- [ ] Outside-in test covers the five-step scenario (create → moderate
      changes_requested → revise → GET pending → assert log order).
- [ ] Outside-in test is **GREEN** (this is the acceptance gate).

### Quality gates

Run from project root:

```bash
ruff format src/app tests
ruff check src/app tests
mypy src/app
pytest                        # includes tests/smoke/test_app_starts.py
```

All must pass. The smoke test boots the app in a subprocess and pings
`/health`. If it fails the slice is **not done** — it usually signals an
accidental absolute import inside `src/app/` that works under pytest but
breaks under uvicorn.
