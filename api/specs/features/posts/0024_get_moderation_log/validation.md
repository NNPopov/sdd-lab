# 0024 · get_moderation_log — Validation

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md
- Requirements: ./requirements.md

## Prerequisites

- App running locally (`uvicorn app.main:app --reload` from `src/`).
- Test database seeded (`alembic upgrade head`).
- A superuser created (`python -m scripts.create_first_superuser`).
- A default tier exists (`python -m scripts.create_first_tier`).
- Bearer tokens at hand (obtain via `POST /api/v1/login`).
- Slice 0023 (`expose_post_uuid`) must be complete so that `post_uuid` is
  present in create-post and list-posts responses.

## Manual scenarios

### S1 — Happy path: author reads a log with entries

**Steps:**

1. Register an author:
   ```
   curl -s -X POST http://localhost:8000/api/v1/users \
     -H "Content-Type: application/json" \
     -d '{"username":"author1","email":"author1@example.com","password":"Pa$$w0rd1"}'
   ```
2. Log in as author, capture `access_token`:
   ```
   curl -s -X POST http://localhost:8000/api/v1/login \
     -d 'username=author1&password=Pa$$w0rd1'
   ```
3. Create a post, capture `post_uuid` from the response:
   ```
   curl -s -X POST http://localhost:8000/api/v1/posts \
     -H "Authorization: Bearer <AUTHOR_TOKEN>" \
     -H "Content-Type: application/json" \
     -d '{"title":"Test post","text":"Content"}'
   ```
4. Assign moderator role to a second user (log in as superuser first):
   ```
   curl -s -X PATCH http://localhost:8000/api/v1/users/mod1/assign-moderator \
     -H "Authorization: Bearer <SUPERUSER_TOKEN>"
   ```
5. Moderator requests changes:
   ```
   curl -s -X POST http://localhost:8000/api/v1/posts/<POST_UUID>/moderate \
     -H "Authorization: Bearer <MOD_TOKEN>" \
     -H "Content-Type: application/json" \
     -d '{"action":"changes_requested","message":"Please fix the title."}'
   ```
6. Author calls the moderation log:
   ```
   curl -s http://localhost:8000/api/v1/posts/<POST_UUID>/moderation-log \
     -H "Authorization: Bearer <AUTHOR_TOKEN>"
   ```

**Expected:**

- Status `200 OK`.
- Body:
  ```json
  {
    "items": [
      {
        "id": <int>,
        "event_type": "moderator_review",
        "action": "changes_requested",
        "message": "Please fix the title.",
        "created_at": "<ISO 8601 UTC>",
        "actor_user_id": <int>,
        "actor_username": "mod1"
      }
    ]
  }
  ```
- `actor_username` is `"mod1"` (resolved from JOIN, not stored in the log row).

**Covers:** F1, F6, F11, F12, F13.

---

### S2 — Happy path: empty log for a newly created post

**Steps:**

1. Create a post as in S1 steps 1–3 (or reuse existing author and token).
2. Call the moderation log immediately after post creation (no moderation yet):
   ```
   curl -s http://localhost:8000/api/v1/posts/<POST_UUID>/moderation-log \
     -H "Authorization: Bearer <AUTHOR_TOKEN>"
   ```

**Expected:**

- Status `200 OK`.
- Body: `{"items": []}`.

**Covers:** F1, F10.

---

### S3 — Unauthenticated request returns 401

**Steps:**

1. Call the endpoint without an Authorization header:
   ```
   curl -s http://localhost:8000/api/v1/posts/<ANY_UUID>/moderation-log
   ```

**Expected:**

- Status `401 Unauthorized`.
- Body contains a `message` field.

**Covers:** F2.

---

### S4 — Authenticated user who is not author, moderator, or superuser returns 403

**Steps:**

1. Register a third user (`other1`) who is not the author, not a moderator,
   and not a superuser. Log in, capture token.
2. Use the `post_uuid` of a post created by `author1` (from S1 step 3).
3. Call the moderation log as `other1`:
   ```
   curl -s http://localhost:8000/api/v1/posts/<POST_UUID>/moderation-log \
     -H "Authorization: Bearer <OTHER1_TOKEN>"
   ```

**Expected:**

- Status `403 Forbidden`.
- Body contains a `message` field.

**Covers:** F5.

---

### S5 — Non-existent post UUID returns 404

**Steps:**

1. Call the endpoint with a well-formed UUID that does not correspond to any post:
   ```
   curl -s http://localhost:8000/api/v1/posts/00000000-0000-0000-0000-000000000000/moderation-log \
     -H "Authorization: Bearer <AUTHOR_TOKEN>"
   ```

**Expected:**

- Status `404 Not Found`.
- Body contains a `message` field.

**Covers:** F3, F14.

---

### S6 — Soft-deleted post returns 404

**Steps:**

1. Delete a post that was previously created by `author1` (using the delete endpoint
   if available, or mark `is_deleted = true` directly in the DB for this manual check).
2. Call the moderation log with that post's UUID:
   ```
   curl -s http://localhost:8000/api/v1/posts/<DELETED_POST_UUID>/moderation-log \
     -H "Authorization: Bearer <AUTHOR_TOKEN>"
   ```

**Expected:**

- Status `404 Not Found`.
- Body contains a `message` field.
- The response is indistinguishable from a post that never existed (no information leak).

**Covers:** F4, F14.

---

### S7 — Moderator (not the author) can read the log

**Steps:**

1. Create a post as `author1` (S1 steps 1–3).
2. As `mod1` (moderator, not the post author), call the moderation log:
   ```
   curl -s http://localhost:8000/api/v1/posts/<POST_UUID>/moderation-log \
     -H "Authorization: Bearer <MOD_TOKEN>"
   ```

**Expected:**

- Status `200 OK`.
- `items` list returned (may be empty if no moderation has occurred yet).

**Covers:** F7.

---

### S8 — Superuser (not the author) can read the log

**Steps:**

1. Use the `post_uuid` of a post created by `author1`.
2. Call the moderation log as the superuser:
   ```
   curl -s http://localhost:8000/api/v1/posts/<POST_UUID>/moderation-log \
     -H "Authorization: Bearer <SUPERUSER_TOKEN>"
   ```

**Expected:**

- Status `200 OK`.
- `items` list returned.

**Covers:** F8.

---

### S9 — User who is both author and moderator can read the log

**Steps:**

1. Assign the moderator role to `author1` (using the superuser token):
   ```
   curl -s -X PATCH http://localhost:8000/api/v1/users/author1/assign-moderator \
     -H "Authorization: Bearer <SUPERUSER_TOKEN>"
   ```
2. Call the moderation log for `author1`'s own post:
   ```
   curl -s http://localhost:8000/api/v1/posts/<POST_UUID>/moderation-log \
     -H "Authorization: Bearer <AUTHOR1_TOKEN>"
   ```

**Expected:**

- Status `200 OK`.
- `items` list returned (reading one's own post log is not a conflict of interest).

**Covers:** F9.

---

### S10 — Chronological ordering verified

**Steps:**

1. Using an established post and moderator from S1, run the full editorial cycle:
   - Moderator requests changes (log entry 1).
   - Author revises (log entry 2).
   - Moderator approves (log entry 3).
2. Call the moderation log as the author.

**Expected:**

- Status `200 OK`.
- `items` has 3 entries.
- `items[0].event_type` is `"moderator_review"` with `action="changes_requested"`.
- `items[1].event_type` is `"author_revision"` with `action=null`.
- `items[2].event_type` is `"moderator_review"` with `action="approved"`.
- Each entry's `created_at` is greater than or equal to the previous one.

**Covers:** F11.

---

## Code review checklist

### Architecture

- [ ] Slice folder exists at `src/app/features/posts/get_moderation_log/` with
      `domain/`, `data/`, and `presentation/` subfolders.
- [ ] `GetModerationLogUseCase` is a class with a single `__call__()` method that
      takes `GetModerationLogQuery` and returns `ModerationLog`.
- [ ] `GetModerationLogPort` lives in `domain/ports/`, carries `@runtime_checkable`,
      and inherits from `typing.Protocol`.
- [ ] `GetModerationLogAdapter` class signature is
      `class GetModerationLogAdapter(GetModerationLogPort):` — explicit port
      inheritance is mandatory.
- [ ] `GetModerationLogAdapter` is the only place `PostModerationLog`, `Post`, and
      `User` ORM models are referenced.
- [ ] Router converts `post_uuid` path param + `current_user` dict into
      `GetModerationLogQuery`, awaits use-case, converts `ModerationLog` to
      `GetModerationLogResponse`.
- [ ] The endpoint dependency is `get_current_user` (not
      `get_current_moderator_or_superuser`) because authors must also be able to
      call it; the multi-condition auth check is in the use-case.
- [ ] No cross-slice imports: `PostForModerationLog`, `ModerationLogEntry`, and
      `ModerationLog` are defined fresh in this slice's `domain/entities.py`.
- [ ] All imports inside `src/app/` are relative. No `from app.*` or
      `from src.app.*` appears in any source file of this slice.
- [ ] No `HTTPException` raised inside `GetModerationLogUseCase`.

### Error handling

- [ ] `GetModerationLogAdapter.get_post_by_uuid` has **no `try/except`**.
- [ ] `GetModerationLogAdapter.get_log` has **no `try/except`**.
- [ ] The use-case translates `None` from `get_post_by_uuid` into
      `NotFoundDomainError` (not the adapter).
- [ ] `GetModerationLogUseCase` raises `ForbiddenDomainError` when none of
      author / moderator / superuser conditions are met.
- [ ] No new `DomainError` subclass introduced in the slice folder; only
      `NotFoundDomainError` and `ForbiddenDomainError` from
      `app/domain/errors.py` are used.
- [ ] Adapter does not log exceptions.

### Files and headers

- [ ] Every new `.py` file starts with `# FEATURE: get_moderation_log — <purpose>`
      on line 1.
- [ ] Only `bootstrap/container.py` has been modified among STABLE files (two
      providers and two imports added).
- [ ] `src/app/features/posts/router.py` (FEATURE) has the new
      `include_router(get_moderation_log_router)` line.
- [ ] No `model.dict()` — only `model.model_dump()`.
- [ ] `ModerationLogEntrySchema` and `GetModerationLogResponse` use
      `model_config = ConfigDict(from_attributes=True)`.

### DI

- [ ] `get_moderation_log_adapter` (Factory) provider added to `Container`.
- [ ] `get_moderation_log_use_case` (Factory, takes `port=get_moderation_log_adapter`)
      provider added to `Container`.
- [ ] Router uses the lazy-import helper pattern
      (`_get_get_moderation_log_use_case` that imports `container` at call time)
      — **not** a `wiring_config` entry, consistent with `moderate_post` and
      `list_pending_posts`.
- [ ] Endpoint injects use-case via
      `Annotated[GetModerationLogUseCase, Depends(_get_get_moderation_log_use_case)]`.

### Tests

- [ ] Use-case unit test exists at
      `tests/features/posts/0024_get_moderation_log/domain/test_use_case.py`
      and passes; covers all 9 branches from `requirements.md`.
- [ ] Adapter unit test exists at
      `tests/features/posts/0024_get_moderation_log/data/test_adapter.py`
      and passes; covers `get_post_by_uuid` (not found, deleted, found) and
      `get_log` (empty, entries with correct JOIN, entries from other posts excluded).
- [ ] Endpoint integration test exists at
      `tests/features/posts/0024_get_moderation_log/presentation/test_router.py`
      and passes; covers 401, 403, 404 (both variants), 200 with items, 200 with
      empty items.
- [ ] Outside-in test exists at
      `tests/features/posts/0024_get_moderation_log/get_moderation_log_outside_in_test.py`,
      is the acceptance gate, and is **GREEN**.
- [ ] No existing outside-in test (0017, 0018, 0019, 0020, 0021, 0022) has been
      broken by this slice.

### Quality gates

Run from project root before approving:

```
ruff format src/app tests
ruff check src/app tests
mypy src/app
pytest
```

All must pass. Pay special attention to `tests/smoke/test_app_starts.py` —
it boots the app in a subprocess and pings `/api/v1/health`. A failure here
usually means an accidental `from app.*` absolute import inside `src/app/`
that works under pytest's `PYTHONPATH` but breaks under uvicorn. The slice
is **not done** until the smoke test is green.
