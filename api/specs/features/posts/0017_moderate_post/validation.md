# 0017 · moderate_post — Validation

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md
- Requirements: ./requirements.md

## Prerequisites

- App running locally (`uvicorn app.main:app --reload` from the project root).
- Test Postgres running and migrated (`alembic upgrade head`).
- A regular user, a moderator user (with `is_moderator = True`), and a superuser
  (with `is_superuser = True`) created via `POST /api/v1/users` and then elevated
  directly in the DB.
- Bearer tokens obtained for each privileged user via the login endpoint.
- A post in `pending_review` status created by the regular user (the author).
- `POST_UUID` set to the UUID returned in the create-post response.
- `AUTHOR_UUID` set to the UUID of the regular-user post author.
- `MOD_TOKEN`, `SUPER_TOKEN`, `USER_TOKEN` set to the respective Bearer tokens.
- `MOD_USER_ID` set to the moderator's integer `id`.

## Manual scenarios

### S1 — Happy path: approve a post

**Steps:**

1. Create a regular user (the author):
   ```
   curl -s -X POST http://localhost:8000/api/v1/users \
     -H "Content-Type: application/json" \
     -d '{"username": "author1", "email": "author1@example.com", "password": "Pa$$w0rd1"}'
   ```
2. Authenticate as the author, create a post; note the returned `uuid` as `POST_UUID`:
   ```
   curl -s -X POST http://localhost:8000/api/v1/users/author1/posts \
     -H "Authorization: Bearer $AUTHOR_TOKEN" \
     -H "Content-Type: application/json" \
     -d '{"title": "Hello world", "text": "My first post"}'
   ```
3. Create a moderator user and set `is_moderator = True` directly in the DB.
   Authenticate as the moderator; note the Bearer token as `MOD_TOKEN`.
4. Call the moderation endpoint:
   ```
   curl -s -X POST http://localhost:8000/api/v1/posts/$POST_UUID/moderate \
     -H "Authorization: Bearer $MOD_TOKEN" \
     -H "Content-Type: application/json" \
     -d '{"action": "approved"}'
   ```

**Expected:**

- Status 200.
- Body shape:
  ```json
  {
    "post_uuid": "<POST_UUID>",
    "status": "approved",
    "log_entry": {
      "id": <int>,
      "event_type": "moderator_review",
      "action": "approved",
      "message": null,
      "created_at": "<ISO-8601 datetime>"
    }
  }
  ```
- Fetching the post row directly in the DB shows `status = "approved"`.
- The `post_moderation_log` table has one row with `event_type = "moderator_review"` and
  `action = "approved"`.

**Covers:** F1, F11, F14, F15, F17.

---

### S2 — Happy path: request changes with a message

**Steps:**

1. Use the same author and a fresh `pending_review` post (or roll back and repeat S1
   step 2 with a new post).
2. Call moderate as the moderator:
   ```
   curl -s -X POST http://localhost:8000/api/v1/posts/$POST_UUID/moderate \
     -H "Authorization: Bearer $MOD_TOKEN" \
     -H "Content-Type: application/json" \
     -d '{"action": "changes_requested", "message": "Please fix the title grammar."}'
   ```

**Expected:**

- Status 200.
- Body `status = "changes_requested"`, `log_entry.action = "changes_requested"`,
  `log_entry.message = "Please fix the title grammar."`,
  `log_entry.event_type = "moderator_review"`.
- DB row `post_moderation_log` has `action = "changes_requested"` and the message text.

**Covers:** F1, F11, F14, F15, F17.

---

### S3 — Superuser (without moderator flag) can moderate

**Steps:**

1. Create a superuser (set `is_superuser = True` in DB); obtain `SUPER_TOKEN`.
2. Call moderate on a `pending_review` post as the superuser:
   ```
   curl -s -X POST http://localhost:8000/api/v1/posts/$POST_UUID/moderate \
     -H "Authorization: Bearer $SUPER_TOKEN" \
     -H "Content-Type: application/json" \
     -d '{"action": "approved"}'
   ```

**Expected:**

- Status 200.
- Same body shape as S1.

**Covers:** F5, F18.

---

### S4 — No Authorization header → 401

**Steps:**

```
curl -s -X POST http://localhost:8000/api/v1/posts/$POST_UUID/moderate \
  -H "Content-Type: application/json" \
  -d '{"action": "approved"}'
```

**Expected:**

- Status 401.
- Body contains a message (e.g. `"User not authenticated."`).

**Covers:** F4.

---

### S5 — Regular user (not moderator, not superuser) → 403

**Steps:**

1. Authenticate as the regular author user; obtain `USER_TOKEN`.
2. Call moderate:
   ```
   curl -s -X POST http://localhost:8000/api/v1/posts/$POST_UUID/moderate \
     -H "Authorization: Bearer $USER_TOKEN" \
     -H "Content-Type: application/json" \
     -d '{"action": "approved"}'
   ```

**Expected:**

- Status 403.
- Body contains a forbidden message.
- No `PostModerationLog` row is inserted.

**Covers:** F5, F6.

---

### S6 — Self-review guard → 403

**Steps:**

1. Create a post **as the moderator** (so `created_by_user_id` equals the moderator's PK).
   Note the post UUID as `MOD_POST_UUID`.
2. Call moderate on that post as the same moderator:
   ```
   curl -s -X POST http://localhost:8000/api/v1/posts/$MOD_POST_UUID/moderate \
     -H "Authorization: Bearer $MOD_TOKEN" \
     -H "Content-Type: application/json" \
     -d '{"action": "approved"}'
   ```

**Expected:**

- Status 403.
- Body `{"message": "Moderators may not review their own posts"}` (or similar).
- `Post.status` unchanged; no `PostModerationLog` row inserted.

**Covers:** F8.

---

### S7 — Post UUID not found → 404

**Steps:**

```
curl -s -X POST http://localhost:8000/api/v1/posts/00000000-0000-0000-0000-000000000000/moderate \
  -H "Authorization: Bearer $MOD_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"action": "approved"}'
```

**Expected:**

- Status 404.
- Body `{"message": "Post not found"}` (or similar).

**Covers:** F7.

---

### S8 — Post already in `approved` terminal state → 409

**Steps:**

1. Approve a `pending_review` post (run S1 step 4).
2. Call moderate on the same post again:
   ```
   curl -s -X POST http://localhost:8000/api/v1/posts/$POST_UUID/moderate \
     -H "Authorization: Bearer $MOD_TOKEN" \
     -H "Content-Type: application/json" \
     -d '{"action": "approved"}'
   ```

**Expected:**

- Status 409.
- Body `{"message": "Post is already approved"}` (or similar).
- No additional `PostModerationLog` row inserted.

**Covers:** F9.

---

### S9 — `changes_requested` without `message` → 422 (schema enforcement)

**Steps:**

```
curl -s -X POST http://localhost:8000/api/v1/posts/$POST_UUID/moderate \
  -H "Authorization: Bearer $MOD_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"action": "changes_requested"}'
```

**Expected:**

- Status 422.
- Body includes a validation error indicating `message` is required for
  `changes_requested`.
- Request does not reach the use-case; no DB write occurs.

**Covers:** F3.

---

### S10 — Invalid `action` value → 422

**Steps:**

```
curl -s -X POST http://localhost:8000/api/v1/posts/$POST_UUID/moderate \
  -H "Authorization: Bearer $MOD_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"action": "rejected"}'
```

**Expected:**

- Status 422.
- Body includes a validation error for the `action` field.
- Request does not reach the use-case; no DB write occurs.

**Covers:** F2.

---

### S11 — `log_entry.event_type` is always `"moderator_review"`

**Steps:**

Inspect the body from S1 and S2.

**Expected:**

- In both cases `log_entry.event_type = "moderator_review"`, regardless of `action`.

**Covers:** F17.

---

## Code review checklist

For the reviewer (human or AI) to verify on the PR. Each line is a yes/no question.
Reject the PR until all are yes.

### Architecture

- [ ] Slice folder exists at `src/app/features/posts/moderate_post/` with `domain/`,
      `data/`, `presentation/` subfolders (each with `__init__.py`).
- [ ] `ModeratePostUseCase` is a class with a single public method `__call__()`; invoked
      as `await use_case(command)`.
- [ ] `ModeratePostPort` lives in `domain/ports/moderate_post_port.py`, carries
      `@runtime_checkable`, and inherits from `typing.Protocol`.
- [ ] `ModeratePostAdapter` class signature is
      `class ModeratePostAdapter(ModeratePostPort):` — explicit inheritance is mandatory.
- [ ] `ModeratePostAdapter` is the only file that imports SQLAlchemy ORM models (`Post`,
      `PostModerationLog`).
- [ ] Router accepts `post_uuid` path param, constructs `ModeratePostCommand`, awaits the
      use-case, converts `ModeratedPostResult` to `ModeratePostResponse`. No business
      logic in the router function.
- [ ] `get_current_moderator_or_superuser` added to `features/users/dependencies.py`
      and follows the same structure as `get_current_superuser`.
- [ ] No cross-slice imports outside `_shared/`; `moderate_post` imports no types from
      other post slices' `domain/`, `data/`, or `presentation/`.
- [ ] All imports inside `src/app/` are **relative** (`from ..domain...`,
      `from ...._shared...`). No `from app...` or `from src.app...` anywhere inside
      `src/app/`. Tests use absolute `from app...` only.
- [ ] No `HTTPException` raised inside `ModeratePostUseCase`.
- [ ] Router does not wrap the use-case call in `try/except`.
- [ ] `domain/entities.py` defines `PostForModeration`, `ModerationLogEntry`, and
      `ModeratedPostResult` as `BaseModel` classes with `ConfigDict(from_attributes=True)`.
- [ ] `presentation/schemas.py` defines `ModeratePostRequest`, `ModerationLogEntrySchema`,
      and `ModeratePostResponse` as separate classes; the nested schema is
      `ModerationLogEntrySchema`, not a reuse of the domain entity directly.

### Error handling

- [ ] `ModeratePostAdapter` contains **no `try/except` block** — neither
      `get_post_by_uuid` nor `apply_decision` catches any exception; all infrastructure
      failures propagate to the global handler per `agent_docs/error_handling.md`.
- [ ] `ModeratePostAdapter` does **not** issue `UPDATE` or `DELETE` on
      `post_moderation_log` at any point.
- [ ] All five use-case guard failures raise the correct `DomainError` subclass:
      `ForbiddenDomainError` (privilege, self-review, missing message),
      `NotFoundDomainError` (post not found), `DuplicateValueDomainError` (already
      approved).
- [ ] No new `DomainError` subclass was added inside the `moderate_post` folder.
      All subclasses live in `app/domain/errors.py`.
- [ ] `ModeratePostAdapter` does not log exceptions.

### Files and headers

- [ ] Every new `.py` file starts with `# FEATURE: moderate_post — <purpose>` on line 1.
- [ ] `features/users/dependencies.py` retains its `# FEATURE: users —
      authentication/authorization dependencies.` header (not replaced by a new one).
- [ ] Only `bootstrap/container.py` is touched among STABLE files; `bootstrap/router.py`
      is **not** modified (the posts feature router is already registered there).
- [ ] All Pydantic schemas use `model_config = ConfigDict(from_attributes=True)`.
- [ ] No `model.dict()` calls — only `model.model_dump()`.
- [ ] `ModeratePostRequest` has a `@model_validator(mode="after")` that rejects
      `action="changes_requested"` with `message=None` and raises `ValueError`.

### DI

- [ ] `moderate_post_adapter` provider (Factory) added to `bootstrap/container.py` with
      `session_factory` injected.
- [ ] `moderate_post_use_case` provider (Factory) added, with `port=moderate_post_adapter`.
- [ ] The `moderate_post` router module path is added to `Container.wiring_config.modules`
      (if using `Provide[Container.moderate_post_use_case]` in the endpoint).
- [ ] The slice sub-router is added to `features/posts/router.py` via
      `router.include_router(moderate_post_router)`.

### Tests

- [ ] Use-case unit test exists at
      `tests/features/posts/0017_moderate_post/domain/test_use_case.py` and covers all
      seven branches (privilege, not found, self-review, already approved, missing message,
      approve happy path, changes_requested happy path).
- [ ] Adapter unit test exists at
      `tests/features/posts/0017_moderate_post/data/test_adapter.py` and covers:
      `get_post_by_uuid` not found, `get_post_by_uuid` found, `apply_decision` approve,
      `apply_decision` changes_requested — all verified against real test Postgres.
- [ ] Endpoint integration test exists at
      `tests/features/posts/0017_moderate_post/presentation/test_router.py` and covers
      all nine scenarios from the PRD (401, 403 unprivileged, 403 self-review, 404, 409,
      422 missing message, 200 approve, 200 changes_requested, superuser can moderate).
- [ ] Outside-in test exists at
      `tests/features/posts/0017_moderate_post/moderate_post_outside_in_test.py` and is
      **GREEN**.
- [ ] `tests/smoke/test_app_starts.py` passes — confirming the new container wiring and
      imports work under uvicorn, not just under pytest.
- [ ] No test calls `session.commit()` inside a test that uses the `db_session`
      transaction-rollback fixture.
- [ ] All async test functions carry `@pytest.mark.asyncio`.
- [ ] Port mocks in unit tests use `mocker.AsyncMock(spec=ModeratePostPort)`.

### Quality gates

Run from project root; all must pass before the slice is considered done:

```
ruff format src/app tests
ruff check src/app tests
mypy src/app
pytest
```

`tests/smoke/test_app_starts.py` runs as part of `pytest`. If it fails (typically
a relative-vs-absolute import mistake), the slice is **not done** even if every other
test is green.
