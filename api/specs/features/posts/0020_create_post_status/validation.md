# 0020 · create_post_status — Validation

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md
- Requirements: ./requirements.md

## Prerequisites

- App running locally (`uvicorn src.app.main:app --reload` from the project
  root, or `python -m uvicorn app.main:app --reload` from `src/`).
- Test database seeded: at minimum one active user (`alice`) and a valid
  superuser tier row.
- A valid Bearer token for `alice` at hand. Obtain it via:

```
POST /api/v1/login
{"username": "alice", "password": "<alice-password>"}
```

  Capture the `access_token` from the response and use it as
  `Authorization: Bearer <token>` in the steps below.

## Manual scenarios

### S1 — Happy path: post is created with status pending_review

**Steps:**

1. Authenticate as `alice` and obtain a Bearer token.
2. Send:

```
POST http://localhost:8000/api/v1/alice/post
Authorization: Bearer <alice-token>
Content-Type: application/json

{"title": "My first post", "text": "Some interesting content here."}
```

**Expected:**

- HTTP 201.
- Response body includes `"status": "pending_review"`.
- Response body includes all existing fields: `id` (integer), `title`,
  `text`, `media_url` (null), `created_by_user_id`, `created_at`.
- `"uuid"` and `"is_deleted"` are absent from the response body.

**Covers:** F1, F2, F3, F4.

---

### S2 — DB state: row has status = pending_review

**Steps:**

1. Complete S1 to create a post and note the returned `id`.
2. Query the database directly:

```sql
SELECT id, title, status FROM post WHERE id = <returned-id>;
```

**Expected:**

- Row exists with `status = 'pending_review'`.

**Covers:** F2.

---

### S3 — Existing error: forbidden (requester not the path owner)

**Steps:**

1. Authenticate as `bob` and obtain a Bearer token.
2. Send:

```
POST http://localhost:8000/api/v1/alice/post
Authorization: Bearer <bob-token>
Content-Type: application/json

{"title": "Intruder title", "text": "Intruder content."}
```

**Expected:**

- HTTP 403.
- Response body: `{"error": {"code": "forbidden", "message": "You can only post under your own username"}}`.
- No post row created in DB.

**Covers:** F5.

---

### S4 — Existing error: target username not found

**Steps:**

1. Authenticate as `alice` and obtain a Bearer token.
2. Send:

```
POST http://localhost:8000/api/v1/ghost_xyz/post
Authorization: Bearer <alice-token>
Content-Type: application/json

{"title": "A title", "text": "Some text."}
```

**Expected:**

- HTTP 404.
- Response body contains `"message": "User not found"`.

**Covers:** F5.

---

### S5 — Existing error: unauthenticated request

**Steps:**

1. Send with no `Authorization` header:

```
POST http://localhost:8000/api/v1/alice/post
Content-Type: application/json

{"title": "A title", "text": "Some text."}
```

**Expected:**

- HTTP 401.

**Covers:** F5.

---

### S6 — Existing error: validation failure (missing required field)

**Steps:**

1. Authenticate as `alice` and obtain a Bearer token.
2. Send:

```
POST http://localhost:8000/api/v1/alice/post
Authorization: Bearer <alice-token>
Content-Type: application/json

{"text": "No title provided."}
```

**Expected:**

- HTTP 422.
- Pydantic validation error body references the `title` field.

**Covers:** F5.

---

## Code review checklist

For the reviewer (human or AI) to verify on the PR. Each item is a yes/no
question. Reject the PR until all are yes.

### Modified files only — no new files

- [ ] Exactly three files are modified:
  `features/posts/create_post/domain/entities.py`,
  `features/posts/create_post/data/adapter.py`,
  `features/posts/create_post/presentation/schemas.py`.
- [ ] No new `.py` files are added under `features/posts/create_post/` or
  anywhere else.
- [ ] No `bootstrap/router.py` or `bootstrap/container.py` changes (no new
  DI entries or router registrations required).
- [ ] No migration file added (the `Post.status` column and its default already
  exist from slice 0013; no schema change is required).

### Domain entity

- [ ] `CreatedPost` in `domain/entities.py` carries `status: str` as a new field.
- [ ] `CreatedPost` retains `model_config = ConfigDict(from_attributes=True)`
  so `model_validate(orm_row)` populates `status` automatically.
- [ ] No new import is added to `domain/entities.py` (`str` is stdlib).
- [ ] The file header remains `# FEATURE: create_post — domain entities.` on line 1
  per `agent_docs/stable_vs_feature.md`.

### Data adapter

- [ ] `CreatePostAdapter.create()` passes `status="pending_review"` as an
  explicit keyword argument to the `Post(...)` constructor.
- [ ] No new `try/except` block is added to the adapter; the ORM column default
  remains as a safety net but is not the primary mechanism.
- [ ] The adapter does not log exceptions per `agent_docs/error_handling.md`
  § Logging policy.
- [ ] The file header remains `# FEATURE: create_post — data adapter.` on line 1.

### Presentation schema

- [ ] `CreatePostResponse` in `presentation/schemas.py` carries `status: str`
  as a new field.
- [ ] `CreatePostResponse` retains `model_config = ConfigDict(from_attributes=True)`.
- [ ] All pre-existing fields on `CreatePostResponse` are unchanged: `id`,
  `title`, `text`, `media_url`, `created_by_user_id`, `created_at`.
- [ ] The file header remains `# FEATURE: create_post — request/response schemas.` on
  line 1.

### Router (read-only verification)

- [ ] `presentation/router.py` is **not modified**; the router's
  `CreatePostResponse.model_validate(result)` call requires no change because
  Pydantic picks up the new field automatically.

### Architecture and imports

- [ ] No STABLE files are modified beyond the permitted exceptions
  (`bootstrap/router.py` and `bootstrap/container.py` only for new-slice wiring,
  which is not needed here) per `agent_docs/stable_vs_feature.md`.
- [ ] All imports inside the modified source files use relative paths
  (`from ..domain...`, not `from app...`) per `agent_docs/architecture.md`
  § Import conventions.
- [ ] No cross-slice imports introduced per `agent_docs/architecture.md`
  § Layer rules.

### Error handling

- [ ] No `HTTPException` raised in any modified file per
  `agent_docs/error_handling.md`.
- [ ] No new broad `except Exception` blocks per `agent_docs/error_handling.md`
  § Anti-pattern: the broad outer catch.
- [ ] No new `DomainError` subclass introduced in the slice folder; all domain
  errors live in `app/domain/errors.py` (STABLE).

### Tests

- [ ] Use-case unit test is **opted out** with documented rationale in
  `plan.md` (use-case is a pass-through with no new branches).
- [ ] Adapter unit test exists at
  `tests/features/posts/0020_create_post_status/data/test_adapter.py` and
  asserts `result.status == "pending_review"` and confirms the DB row value
  via SQL.
- [ ] Endpoint integration test exists at
  `tests/features/posts/0020_create_post_status/presentation/test_router.py`
  and asserts `response.json()["status"] == "pending_review"` on HTTP 201.
- [ ] Outside-in test exists at
  `tests/features/posts/0020_create_post_status/create_post_status_outside_in_test.py`
  and is the acceptance gate.
- [ ] Existing 0011 outside-in test
  (`tests/features/posts/0011_create_post/create_post_outside_in_test.py`)
  remains green.

### Quality gates

Run from the project root:

```
ruff format src/app tests
ruff check src/app tests
mypy src/app
pytest
```

All must pass. The smoke test inside `pytest` (`tests/smoke/test_app_starts.py`)
boots the app in a subprocess and pings `/api/v1/health`. If it fails, the
slice is **not done** even if every other test is green — it catches import
paths that work under pytest but break under uvicorn.

Outside-in test specifically:

```
pytest tests/features/posts/0020_create_post_status/create_post_status_outside_in_test.py -v
```
