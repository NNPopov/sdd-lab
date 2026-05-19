# 0026 · get_post — Validation

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md
- Requirements: ./requirements.md

## Prerequisites

- App running locally: `uvicorn app.main:app --reload` (from `src/`).
- Test Postgres database accessible; Alembic migrations applied.
- A superuser account exists (created via `python -m scripts.create_first_superuser`).
- For moderator scenarios: a user promoted to moderator via
  `PATCH /api/v1/users/{username}/moderator`.
- Valid Bearer tokens for each actor obtained via `POST /api/v1/auth/login`.
- Variables used in curl commands below:
  - `ALICE_TOKEN` — token for user `alice` (post author).
  - `BOB_TOKEN` — token for user `bob` (non-author, non-privileged).
  - `CAROL_TOKEN` — token for user `carol` (moderator).
  - `SU_TOKEN` — token for superuser.
  - `POST_ID` — `id` returned by the create-post call in S1.

---

## Manual scenarios

### S1 — Setup: create users and a post

**Steps:**

```bash
# Register alice
curl -s -X POST http://localhost:8000/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{"username":"alice","email":"alice@example.com","password":"Pa$$w0rd1"}'

# Register bob
curl -s -X POST http://localhost:8000/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{"username":"bob","email":"bob@example.com","password":"Pa$$w0rd2"}'

# Register carol, then promote to moderator (requires superuser token)
curl -s -X POST http://localhost:8000/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{"username":"carol","email":"carol@example.com","password":"Pa$$w0rd3"}'
curl -s -X PATCH http://localhost:8000/api/v1/users/carol/moderator \
  -H "Authorization: Bearer $SU_TOKEN"

# Obtain alice token
ALICE_TOKEN=$(curl -s -X POST http://localhost:8000/api/v1/auth/login \
  -F username=alice -F password='Pa$$w0rd1' | jq -r .access_token)

# Alice creates a post (status defaults to pending_review)
POST_ID=$(curl -s -X POST http://localhost:8000/api/v1/alice/posts \
  -H "Authorization: Bearer $ALICE_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"title":"Hello","text":"World content"}' | jq -r .id)
```

**Expected:** All requests return their respective success codes. `POST_ID` is
a positive integer.

**Covers:** setup only (no requirement directly).

---

### S2 — Happy path: approved post, unauthenticated caller

**Steps:**

```bash
# Promote the post to approved (via superuser or moderator token)
CAROL_TOKEN=$(curl -s -X POST http://localhost:8000/api/v1/auth/login \
  -F username=carol -F password='Pa$$w0rd3' | jq -r .access_token)
curl -s -X PATCH http://localhost:8000/api/v1/posts/$POST_ID/moderate \
  -H "Authorization: Bearer $CAROL_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"status":"approved"}'

# Fetch the post with no token
curl -s http://localhost:8000/api/v1/users/alice/post/$POST_ID
```

**Expected:**

- Status 200.
- Body is a JSON object containing `id`, `title`, `text`, `media_url`,
  `created_at`, `created_by_user_id`, `username`, `status`, `post_uuid`.
- `username` equals `"alice"`.
- `status` equals `"approved"`.
- `post_uuid` is a non-empty UUID string.

**Covers:** F1, F15.

---

### S3 — Pending post, unauthenticated caller → 404

**Steps:**

```bash
# Create a fresh pending post
PENDING_ID=$(curl -s -X POST http://localhost:8000/api/v1/alice/posts \
  -H "Authorization: Bearer $ALICE_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"title":"Pending","text":"Awaiting review"}' | jq -r .id)

# Fetch with no token
curl -s http://localhost:8000/api/v1/users/alice/post/$PENDING_ID
```

**Expected:**

- Status 404.
- Body `{"message": "Post not found"}`.

**Covers:** F5, F7.

---

### S4 — Pending post, different authenticated user → 404

**Steps:**

```bash
BOB_TOKEN=$(curl -s -X POST http://localhost:8000/api/v1/auth/login \
  -F username=bob -F password='Pa$$w0rd2' | jq -r .access_token)

curl -s http://localhost:8000/api/v1/users/alice/post/$PENDING_ID \
  -H "Authorization: Bearer $BOB_TOKEN"
```

**Expected:**

- Status 404.
- Body `{"message": "Post not found"}`.

**Covers:** F4, F8.

---

### S5 — Pending post, author → 200

**Steps:**

```bash
curl -s http://localhost:8000/api/v1/users/alice/post/$PENDING_ID \
  -H "Authorization: Bearer $ALICE_TOKEN"
```

**Expected:**

- Status 200.
- Body includes `"status": "pending_review"` and `"username": "alice"`.

**Covers:** F2, F9.

---

### S6 — Pending post, moderator → 200

**Steps:**

```bash
curl -s http://localhost:8000/api/v1/users/alice/post/$PENDING_ID \
  -H "Authorization: Bearer $CAROL_TOKEN"
```

**Expected:**

- Status 200.
- Body includes `"status": "pending_review"`.

**Covers:** F3, F10.

---

### S7 — Pending post, superuser → 200

**Steps:**

```bash
curl -s http://localhost:8000/api/v1/users/alice/post/$PENDING_ID \
  -H "Authorization: Bearer $SU_TOKEN"
```

**Expected:**

- Status 200.
- Body includes `"status": "pending_review"`.

**Covers:** F3, F11.

---

### S8 — changes_requested post, non-author non-privileged → 404

**Steps:**

```bash
# Set post to changes_requested via moderator
curl -s -X PATCH http://localhost:8000/api/v1/posts/$PENDING_ID/moderate \
  -H "Authorization: Bearer $CAROL_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"status":"changes_requested"}'

curl -s http://localhost:8000/api/v1/users/alice/post/$PENDING_ID \
  -H "Authorization: Bearer $BOB_TOKEN"
```

**Expected:**

- Status 404.
- Body `{"message": "Post not found"}`.

**Covers:** F4, F12.

---

### S9 — changes_requested post, author → 200

**Steps:**

```bash
curl -s http://localhost:8000/api/v1/users/alice/post/$PENDING_ID \
  -H "Authorization: Bearer $ALICE_TOKEN"
```

**Expected:**

- Status 200.
- Body includes `"status": "changes_requested"`.

**Covers:** F2, F13.

---

### S10 — Unknown username → 404

**Steps:**

```bash
curl -s http://localhost:8000/api/v1/users/nonexistent_xyz/post/1
```

**Expected:**

- Status 404.
- Body `{"message": "Post not found"}`.

**Covers:** F5, F6.

---

### S11 — Unknown post id → 404

**Steps:**

```bash
curl -s http://localhost:8000/api/v1/users/alice/post/999999
```

**Expected:**

- Status 404.
- Body `{"message": "Post not found"}`.

**Covers:** F5, F6.

---

### S12 — Post id belongs to a different user → 404

**Steps:**

```bash
# Create a post as bob
BOB_POST_ID=$(curl -s -X POST http://localhost:8000/api/v1/bob/posts \
  -H "Authorization: Bearer $BOB_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"title":"Bob post","text":"content"}' | jq -r .id)

# Try to retrieve bob's post via alice's URL
curl -s http://localhost:8000/api/v1/users/alice/post/$BOB_POST_ID
```

**Expected:**

- Status 404.
- Body `{"message": "Post not found"}`.

**Covers:** F6, F16.

---

### S13 — Response body includes new fields

**Steps:**

```bash
curl -s http://localhost:8000/api/v1/users/alice/post/$POST_ID
```

(Assumes `$POST_ID` was approved in S2.)

**Expected:**

- Response JSON contains keys: `id`, `title`, `text`, `media_url`,
  `created_at`, `created_by_user_id`, `username`, `status`, `post_uuid`.
- No extra keys exposing internal fields (e.g. no `is_deleted`, no
  `hashed_password`).
- `username` is `"alice"`, not a numeric id.

**Covers:** F1, F14, F15.

---

### S14 — Cache key compatibility (smoke check)

**Steps:**

```bash
# Approved post: fetch once to populate cache
curl -s http://localhost:8000/api/v1/users/alice/post/$POST_ID

# Patch the post (invalidates cache via patch_post's existing invalidation)
curl -s -X PATCH http://localhost:8000/api/v1/users/alice/post/$POST_ID \
  -H "Authorization: Bearer $ALICE_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"title":"Updated title"}'

# Fetch again — should return updated title, not cached old title
curl -s http://localhost:8000/api/v1/users/alice/post/$POST_ID
```

**Expected:**

- Third call returns `"title": "Updated title"` (cache was invalidated).

**Covers:** F18.

---

## Code review checklist

### Architecture

- [ ] Slice folder exists at `src/app/features/posts/get_post/` with
      `domain/`, `data/`, `presentation/` subfolders, each with `__init__.py`.
- [ ] `GetPostUseCase` is a class with `__call__(self, query: GetPostQuery)`
      returning `PostItem`; no free-function use-case.
- [ ] `GetPostPort` lives in `domain/ports/get_post_port.py`, is decorated
      with `@runtime_checkable`, and inherits from `typing.Protocol`.
- [ ] `GetPostAdapter` class signature is `class GetPostAdapter(GetPostPort):` —
      explicit inheritance from the port.
- [ ] `GetPostAdapter` is the only file that imports SQLAlchemy or touches DB
      session; no SQLAlchemy in `domain/` or `presentation/`.
- [ ] Router accepts `request: Request` as first parameter (required by
      `@cache`), converts path params + `optional_user` to `GetPostQuery`,
      awaits use-case, returns `GetPostResponse`.
- [ ] `PostItem` imported from `features/posts/_shared/entities.py`; no other
      slice's `domain/` or `presentation/` folder is imported.
- [ ] All imports inside `src/app/` are **relative**; no `from app...` or
      `from src.app...` inside source files. Tests use absolute `from app...`.
- [ ] No `HTTPException` raised inside `GetPostUseCase`.
- [ ] No `try/except` block of any kind inside `GetPostUseCase`.

### Error handling

- [ ] `GetPostAdapter.get()` has **no `try/except`** — read-only query,
      nothing business-meaningful to catch.
- [ ] `NotFoundDomainError` is raised only in the use case (not in the adapter
      and not in the router).
- [ ] Both "post not found" and "post not visible" cases raise
      `NotFoundDomainError("Post not found")` with identical messages
      (prevents status enumeration).
- [ ] No new `DomainError` subclass added inside the slice folder; all domain
      errors live in `app/domain/errors.py`.
- [ ] Adapter does not log exceptions.

### Access control

- [ ] Use case checks `post.status != "approved"` before applying bypass logic.
- [ ] Author bypass: `query.requester_username == query.username`.
- [ ] Privilege bypass: `query.requester_is_privileged`.
- [ ] Router computes `requester_is_privileged` from
      `optional_user["is_superuser"] or optional_user["is_moderator"]` (only
      when `optional_user` is not `None`).
- [ ] Router computes `requester_username` as `optional_user["username"]` when
      `optional_user` is not `None`, else `None`.

### Files and headers

- [ ] Every new `.py` file starts with `# FEATURE: get_post — <purpose>` on
      line 1.
- [ ] No STABLE file was modified beyond `bootstrap/container.py` (two
      provider entries).
- [ ] `GetPostResponse` declares `model_config = ConfigDict(from_attributes=True)`.
- [ ] No `model.dict()` usage; only `model.model_dump()` or `model_validate()`.

### Cache

- [ ] `@cache(key_prefix="{username}_post_cache", resource_id_name="id")`
      is applied with exactly these values.
- [ ] `request: Request` is the first parameter of `get_post_endpoint`
      (required by the `@cache` decorator).
- [ ] No other arguments passed to `@cache` (no `expiration` override, no
      `pattern_to_invalidate_extra`) — this endpoint only reads; invalidation
      is handled by `patch_post` and `erase_post`.

### DI

- [ ] `get_post_adapter = providers.Factory(GetPostAdapter, session_factory=session_factory)` added to `Container`.
- [ ] `get_post_use_case = providers.Factory(GetPostUseCase, port=get_post_adapter)` added to `Container`.
- [ ] Router uses the lazy-import helper pattern (`_get_get_post_use_case`)
      rather than `Provide[Container.get_post_use_case]`; no
      `wiring_config.modules` entry required.

### Flat router cleanup

- [ ] `read_post` function and its `@router.get` / `@cache` decorators are
      removed from `src/app/features/posts/router.py`.
- [ ] `router.include_router(get_post_router)` is present in
      `features/posts/router.py`.
- [ ] Any imports in `features/posts/router.py` that were used **only** by
      `read_post` are also removed (verify `crud_users`, `UserRead`, etc. are
      still needed by remaining handlers before removing).

### Tests

- [ ] Use-case unit test exists at
      `tests/features/posts/0026_get_post/domain/test_use_case.py`
      and covers all six access-control branches.
- [ ] Adapter unit test exists at
      `tests/features/posts/0026_get_post/data/test_adapter.py`
      using real test Postgres (not a mock session).
- [ ] Endpoint integration test exists at
      `tests/features/posts/0026_get_post/presentation/test_router.py`
      and covers all nine HTTP scenarios from requirements.
- [ ] Outside-in test exists at
      `tests/features/posts/0026_get_post/get_post_outside_in_test.py`
      and is GREEN.
- [ ] No test leaves rows in the DB after completion (transaction rollback
      or fixture teardown confirmed).

### Quality gates

Run from project root before approving:

```
ruff format src/app tests
ruff check src/app tests
mypy src/app
pytest
```

All must pass. The smoke test inside `pytest` (`tests/smoke/test_app_starts.py`)
boots the app in a subprocess and pings `/api/v1/health`. If it fails the slice
is **not done** — it typically indicates an accidental absolute import inside
`src/app/` that works under pytest but breaks under uvicorn.
