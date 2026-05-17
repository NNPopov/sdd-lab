# 0018 · revise_post — Validation

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md
- Requirements: ./requirements.md

## Prerequisites

- App running locally (`uvicorn app.main:app --reload`).
- Test database reachable and migrated to head (`alembic upgrade head`).
- Two registered users at hand: **author** (owns the post) and **other** (a
  different regular user). A **moderator** user with `is_moderator = true` is also
  needed for setup — assign via `POST /api/v1/users/{username}/assign-moderator` using a
  superuser token, or set the flag directly in the DB.
- The `changes_requested` setup flow must be run before executing any scenario that
  targets a post in that state (see Setup below).

### Setup flow (run once before S1–S7)

```bash
# 1. Register author
curl -s -X POST http://localhost:8000/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{"username": "author1", "email": "author1@example.com", "password": "Pa$$w0rd1"}'

# 2. Authenticate as author — capture token
curl -s -X POST http://localhost:8000/api/v1/auth/token \
  -d 'username=author1&password=Pa$$w0rd1' \
  -H "Content-Type: application/x-www-form-urlencoded"
# → set AUTHOR_TOKEN=<access_token>

# 3. Create a post
curl -s -X POST http://localhost:8000/api/v1/posts \
  -H "Authorization: Bearer $AUTHOR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"title": "Original Title", "text": "Original body text."}'
# → set POST_UUID=<uuid from response>

# 4. Register moderator and assign the flag
curl -s -X POST http://localhost:8000/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{"username": "mod1", "email": "mod1@example.com", "password": "Pa$$w0rd2"}'

# Assign moderator flag (requires superuser token — $SUPER_TOKEN)
curl -s -X POST http://localhost:8000/api/v1/users/mod1/assign-moderator \
  -H "Authorization: Bearer $SUPER_TOKEN"

# 5. Authenticate as moderator
curl -s -X POST http://localhost:8000/api/v1/auth/token \
  -d 'username=mod1&password=Pa$$w0rd2' \
  -H "Content-Type: application/x-www-form-urlencoded"
# → set MOD_TOKEN=<access_token>

# 6. Move the post to changes_requested
curl -s -X POST "http://localhost:8000/api/v1/posts/$POST_UUID/moderate" \
  -H "Authorization: Bearer $MOD_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"action": "changes_requested", "message": "Please improve the title."}'
# → post.status should now be "changes_requested"
```

---

## Manual scenarios

### S1 — Happy path: revise title and text with a message

**Steps:**

```bash
curl -s -X PATCH "http://localhost:8000/api/v1/posts/$POST_UUID/revise" \
  -H "Authorization: Bearer $AUTHOR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"title": "Revised Title", "text": "Revised body.", "message": "Fixed as requested."}'
```

**Expected:**

- Status `200`.
- Body contains `"status": "pending_review"`.
- `title` is `"Revised Title"`, `text` is `"Revised body."`.
- `log_entry.event_type` is `"author_revision"`.
- `log_entry.action` is `null`.
- `log_entry.message` is `"Fixed as requested."`.
- `updated_at` is a recent UTC timestamp.
- DB row for the post has `status = "pending_review"`, updated `title` and `text`.
- A `PostModerationLog` row exists with `event_type = "author_revision"` and `action = null`.

**Covers:** F1, F7, F8, F9, F10, F11, F12, F15.

---

### S2 — Happy path: revise title only (text unchanged)

**Steps:**

```bash
# Re-run setup flow to get a fresh changes_requested post, then:
curl -s -X PATCH "http://localhost:8000/api/v1/posts/$POST_UUID/revise" \
  -H "Authorization: Bearer $AUTHOR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"title": "Title Only Update"}'
```

**Expected:**

- Status `200`.
- `title` is `"Title Only Update"`.
- `text` in the response is the original value (`"Original body text."`) — unchanged.
- `status` is `"pending_review"`.

**Covers:** F9, F10, F12.

---

### S3 — Happy path: revise text only (title unchanged)

**Steps:**

```bash
# Re-run setup flow, then:
curl -s -X PATCH "http://localhost:8000/api/v1/posts/$POST_UUID/revise" \
  -H "Authorization: Bearer $AUTHOR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"text": "Text only update."}'
```

**Expected:**

- Status `200`.
- `text` is `"Text only update."`.
- `title` in the response is the original value (`"Original Title"`) — unchanged.
- `status` is `"pending_review"`.

**Covers:** F9, F10, F12.

---

### S4 — No authorization token

**Steps:**

```bash
curl -s -X PATCH "http://localhost:8000/api/v1/posts/$POST_UUID/revise" \
  -H "Content-Type: application/json" \
  -d '{"title": "Should fail"}'
```

**Expected:**

- Status `401`.
- Body contains an error message indicating missing or invalid credentials.

**Covers:** F3.

---

### S5 — Wrong owner (another user attempts to revise)

**Steps:**

```bash
# Register and authenticate as a different user
curl -s -X POST http://localhost:8000/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{"username": "other1", "email": "other1@example.com", "password": "Pa$$w0rd3"}'

curl -s -X POST http://localhost:8000/api/v1/auth/token \
  -d 'username=other1&password=Pa$$w0rd3' \
  -H "Content-Type: application/x-www-form-urlencoded"
# → set OTHER_TOKEN=<access_token>

curl -s -X PATCH "http://localhost:8000/api/v1/posts/$POST_UUID/revise" \
  -H "Authorization: Bearer $OTHER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"title": "Unauthorized attempt"}'
```

**Expected:**

- Status `403`.
- Body `{"message": "You may only revise your own posts"}`.

**Covers:** F5.

---

### S6 — Wrong status: post is in `pending_review`

**Steps:**

```bash
# Create a fresh post — it starts in pending_review
curl -s -X POST http://localhost:8000/api/v1/posts \
  -H "Authorization: Bearer $AUTHOR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"title": "Fresh Post", "text": "Pending review."}'
# → set PENDING_UUID=<uuid>

curl -s -X PATCH "http://localhost:8000/api/v1/posts/$PENDING_UUID/revise" \
  -H "Authorization: Bearer $AUTHOR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"title": "Should be rejected"}'
```

**Expected:**

- Status `403`.
- Body `{"message": "Post is not in changes_requested status"}`.

**Covers:** F6.

---

### S7 — Wrong status: post is `approved`

**Steps:**

```bash
# Create a fresh post, then moderate it to approved
curl -s -X POST http://localhost:8000/api/v1/posts \
  -H "Authorization: Bearer $AUTHOR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"title": "Post to approve", "text": "Good content."}'
# → set APPROVED_UUID=<uuid>

curl -s -X POST "http://localhost:8000/api/v1/posts/$APPROVED_UUID/moderate" \
  -H "Authorization: Bearer $MOD_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"action": "approved"}'

curl -s -X PATCH "http://localhost:8000/api/v1/posts/$APPROVED_UUID/revise" \
  -H "Authorization: Bearer $AUTHOR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"title": "Should be rejected"}'
```

**Expected:**

- Status `403`.
- Body `{"message": "Post is not in changes_requested status"}`.

**Covers:** F6.

---

### S8 — Post UUID not found

**Steps:**

```bash
curl -s -X PATCH "http://localhost:8000/api/v1/posts/00000000-0000-0000-0000-000000000000/revise" \
  -H "Authorization: Bearer $AUTHOR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"title": "Ghost post"}'
```

**Expected:**

- Status `404`.
- Body `{"message": "Post not found"}`.

**Covers:** F4.

---

### S9 — No fields provided (neither title nor text)

**Steps:**

```bash
curl -s -X PATCH "http://localhost:8000/api/v1/posts/$POST_UUID/revise" \
  -H "Authorization: Bearer $AUTHOR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{}'
```

**Expected:**

- Status `422`.
- Body contains a validation error indicating at least one of `title` or `text` is
  required; error is returned at the schema boundary before the use-case is called.

**Covers:** F2.

---

## Code review checklist

### Architecture

- [ ] Slice folder exists at `src/app/features/posts/revise_post/` with `domain/`,
      `data/`, and `presentation/` subfolders.
- [ ] `RevisePostUseCase` is a class with `__call__(command: RevisePostCommand) ->
      RevisedPostResult`; no other public methods.
- [ ] `RevisePostPort` lives in `domain/ports/revise_post_port.py`, carries
      `@runtime_checkable`, and inherits from `typing.Protocol`.
- [ ] Adapter class signature is `class RevisePostAdapter(RevisePostPort):` — explicit
      inheritance from the port is present.
- [ ] `RevisePostAdapter` is the only place SQLAlchemy is used; no ORM calls appear in
      the use-case, router, or schemas.
- [ ] Router accepts `RevisePostRequest` and path param, converts to `RevisePostCommand`,
      awaits use-case, returns `RevisePostResponse`; no business logic in the router.
- [ ] No imports from another slice's `domain/`, `data/`, or `presentation/` folders.
- [ ] All imports inside `src/app/features/posts/revise_post/` are **relative**
      (`from ..domain...`, `from ...._shared...`). No `from app...` or `from src.app...`
      inside source files.
- [ ] `RevisePostUseCase` raises only `DomainError` subclasses; no `HTTPException` is
      raised or imported.

### Error handling

- [ ] `RevisePostAdapter.get_post_by_uuid` has no `try/except` — read-only queries
      propagate infrastructure failures to the global handler.
- [ ] `RevisePostAdapter.apply_revision` has no `try/except Exception` — the UPDATE and
      log INSERT carry no unique constraints requiring translation; failures propagate.
- [ ] No broad `except Exception` block anywhere in the adapter.
- [ ] The adapter does not log exceptions; logging is the global handler's responsibility.
- [ ] No new `DomainError` subclass was added inside the slice folder. All domain errors
      live in `app/domain/errors.py` (STABLE).
- [ ] No `UnknownDomainError` or equivalent catch-all domain error is introduced.

### Conditional update correctness

- [ ] `apply_revision` includes `Post.title` in the UPDATE SET clause **only** when
      `title is not None`; `None` title does not overwrite the existing column value.
- [ ] `apply_revision` includes `Post.text` in the UPDATE SET clause **only** when
      `text is not None`; `None` text does not overwrite the existing column value.
- [ ] The result `RevisedPostResult.title` and `.text` reflect the post row after the
      UPDATE (fetched from DB), not the raw command inputs.

### Files and headers

- [ ] Every new `.py` file starts with `# FEATURE: revise_post — <purpose>` on line 1.
- [ ] No STABLE file was modified beyond `bootstrap/container.py` (two providers + two
      imports + one `wiring_config` entry).
- [ ] `features/posts/router.py` has one new `include_router` call for the revise-post
      router; no other structural changes.
- [ ] All Pydantic schemas use `model_config = ConfigDict(from_attributes=True)`.
- [ ] No `model.dict()` calls — only `model.model_dump()`.

### DI

- [ ] `revise_post_adapter` provider added to `Container` as `providers.Factory`.
- [ ] `revise_post_use_case` provider added to `Container` as `providers.Factory`, taking
      `port=revise_post_adapter`.
- [ ] `"app.features.posts.revise_post.presentation.router"` added to
      `Container.wiring_config.modules`.
- [ ] Endpoint uses `Annotated[RevisePostUseCase, Depends(...)]` for the use-case and
      `Annotated[dict, Depends(get_current_user)]` for auth.

### Tests

- [ ] Use-case unit test exists at
      `tests/features/posts/0018_revise_post/domain/test_use_case.py` and covers all
      seven cases from the plan (not-found, ownership, wrong-status ×2, happy-path ×3).
- [ ] Adapter unit test exists at
      `tests/features/posts/0018_revise_post/data/test_adapter.py` and covers all six
      cases from the plan (get not-found, get found, title-only, text-only, both fields,
      log row created).
- [ ] Endpoint integration test exists at
      `tests/features/posts/0018_revise_post/presentation/test_router.py` and covers all
      eight cases from the plan (401, 403×2, 403×2 status, 404, 422, 200×2).
- [ ] Outside-in test exists at
      `tests/features/posts/0018_revise_post/revise_post_outside_in_test.py`, is the
      acceptance gate, and is **GREEN**.
- [ ] No test leaves rows in the DB after it completes (transaction rollback or fixture
      teardown is in place).

### Quality gates

Run from project root — all must pass before the slice is considered done:

```
ruff format src/app tests
ruff check src/app tests
mypy src/app
pytest
```

The smoke test inside `pytest` (`tests/smoke/test_app_starts.py`) boots the app in a
subprocess and pings `/api/v1/health`. If it fails, the slice is **not done** — it
usually indicates an import that works under pytest but breaks under uvicorn (e.g. an
accidental `from app...` inside `src/app/`).
