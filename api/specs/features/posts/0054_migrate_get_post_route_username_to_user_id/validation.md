# 0054 · migrate_get_post_route_username_to_user_id — Validation

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md
- Requirements: ./requirements.md

## Prerequisites

- App running locally (`uvicorn app.main:app --reload` from `src/`).
- Test Postgres running (`docker compose up test-db -d`).
- At least one registered user whose integer `id` you know, with one `approved`
  post and one non-`approved` (e.g. `pending`) post. The scripts
  `create_first_superuser` and `create_first_tier` must have been run once.
- A valid Bearer token for that user, obtained via `POST /api/v1/login`.

Placeholders used below:

- `$USER_ID` — integer primary key of the post author.
- `$USERNAME` — that author's `username` string (used only to demonstrate the
  old route is gone).
- `$APPROVED_ID` — post `id` of the author's `approved` post.
- `$PENDING_ID` — post `id` of the author's non-`approved` (e.g. `pending`) post.
- `$TOKEN_OWNER` — JWT for the author (`$USER_ID`).
- `$TOKEN_OTHER` — JWT for a different, non-privileged registered user.
- `$TOKEN_ADMIN` — JWT for a superuser or moderator.

---

## Manual scenarios

### S1 — Happy path: get an approved post by integer ID (unauthenticated)

**Steps:**

1. Ensure `$USER_ID` has an `approved` post `$APPROVED_ID`.
2. Send:
   ```
   curl http://localhost:8000/api/v1/$USER_ID/post/$APPROVED_ID
   ```

**Expected:**

- Status 200.
- Body matches `GetPostResponse`: `id == $APPROVED_ID`, `created_by_user_id == $USER_ID`,
  `status == "approved"`, and `username` equal to the author's handle (from the JOIN).
- Body includes `title`, `text`, `media_url`, `created_at`, `post_uuid`.

**Covers:** F1, F3, F10, F16.

---

### S2 — Author can read their own non-approved post

**Steps:**

1. Log in as the author to obtain `$TOKEN_OWNER`.
2. Send:
   ```
   curl http://localhost:8000/api/v1/$USER_ID/post/$PENDING_ID \
     -H "Authorization: Bearer $TOKEN_OWNER"
   ```

**Expected:**

- Status 200.
- The non-approved post is returned with its `status` (e.g. `pending`).

**Covers:** F4, F15.

---

### S3 — Privileged viewer (superuser/moderator) can read a non-approved post

**Steps:**

1. Log in as a superuser/moderator to obtain `$TOKEN_ADMIN`.
2. Send:
   ```
   curl http://localhost:8000/api/v1/$USER_ID/post/$PENDING_ID \
     -H "Authorization: Bearer $TOKEN_ADMIN"
   ```

**Expected:**

- Status 200.
- The non-approved post is returned regardless of authorship.

**Covers:** F5, F15.

---

### S4 — Non-author, non-privileged viewer gets 404 for a non-approved post

**Steps:**

1. Log in as a different non-privileged user to obtain `$TOKEN_OTHER`.
2. Send:
   ```
   curl -i http://localhost:8000/api/v1/$USER_ID/post/$PENDING_ID \
     -H "Authorization: Bearer $TOKEN_OTHER"
   ```
3. Also send the same request unauthenticated.

**Expected:**

- Status 404 in both cases.
- Body `{"error": {"code": "notfound", "message": "Post not found"}}` — the pending post is not exposed.

**Covers:** F6.

---

### S5 — Unknown post → 404

**Steps:**

1. Send with a `post_id` that does not exist (e.g. 999999):
   ```
   curl -i http://localhost:8000/api/v1/$USER_ID/post/999999
   ```

**Expected:**

- Status 404.
- Body `{"error": {"code": "notfound", "message": "Post not found"}}`.

**Covers:** F7.

---

### S6 — Wrong author / unknown user_id → 404 (no leak)

**Steps:**

1. Send the approved post `id` under a different author's integer ID:
   ```
   curl -i http://localhost:8000/api/v1/999999/post/$APPROVED_ID
   ```

**Expected:**

- Status 404, `{"error": {"code": "notfound", "message": "Post not found"}}` — no
  distinct "user not found"; the response does not reveal whether user 999999 exists.

**Covers:** F7, F8.

---

### S7 — Non-integer user_id → 422 (old string route is gone)

**Steps:**

1. Send with the author's username string instead of the ID:
   ```
   curl -i http://localhost:8000/api/v1/$USERNAME/post/$APPROVED_ID
   ```

**Expected:**

- Status 422.
- Body contains a `detail` array reporting that the path value is not a valid
  integer.

**Covers:** F2, F9.

---

### S8 — Cache key keyed by user_id

**Steps:**

1. Send S1 twice in quick succession (within the TTL).
2. (Optional) Inspect Redis keys: `redis-cli KEYS "$USER_ID_post_cache*"`.

**Expected:**

- Second response is served identically (cache hit), under a key beginning with
  `$USER_ID_post_cache`. No key beginning with `$USERNAME_post_cache` is written.

**Covers:** F16.

---

## Code review checklist

### Architecture

- [ ] `get_post` slice files were modified **in place**; no new `src/app` slice folder was created for 0054.
- [ ] `GetPostUseCase` is still a class with `__call__(query: GetPostQuery) -> PostItem`; only the author comparison inside the non-approved branch changed.
- [ ] `GetPostPort` lives in `domain/ports/get_post_port.py`, carries `@runtime_checkable`, inherits `Protocol`, and its `get(query: GetPostQuery)` signature is unchanged.
- [ ] `GetPostAdapter` class signature is `class GetPostAdapter(GetPostPort):` — explicit inheritance retained.
- [ ] `GetPostAdapter` is the only file using SQLAlchemy directly; `domain/` and `presentation/` have no ORM imports.
- [ ] Router accepts `user_id: int` and `id: int` from the path, builds `GetPostQuery`, awaits the use-case, returns `GetPostResponse`.
- [ ] No cross-slice imports outside `features/posts/_shared/`; `posts/_shared` user-lookup port/adapter and `check_post_owner` policy were **not** touched.
- [ ] All imports inside `src/app/` are **relative**; no `from app…` / `from src.app…` in source.
- [ ] No `HTTPException` raised inside the use-case or adapter.

### Migration correctness

- [ ] `GetPostQuery` has `user_id: int` and `requester_user_id: int | None`; `username` and `requester_username` are gone. `post_id` and `requester_is_privileged` are unchanged.
- [ ] Use-case author check is `query.requester_user_id == query.user_id`; the `post is None` guard, privileged bypass, and final 404 are unchanged.
- [ ] Adapter filters on `Post.created_by_user_id == query.user_id` pinned by `Post.id == query.post_id` — no `User.username == …` filter remains.
- [ ] The `Post → User` JOIN and the `User.is_deleted == False` / `Post.is_deleted == False` guards are retained; `PostItem.username` comes from the JOIN; a non-matching row still yields `None`.
- [ ] Router path is `"/{user_id}/post/{id}"`; `requester_user_id = optional_user["id"] if optional_user else None`; `requester_is_privileged` derivation is unchanged.
- [ ] Cache `key_prefix` is `"{user_id}_post_cache"` and `resource_id_name="id"`.
- [ ] `GetPostResponse` fields are unchanged from 0026.

### Error handling

- [ ] `GetPostAdapter.get` has **no `try/except`** (read-only query; nothing business-meaningful to translate).
- [ ] No new `DomainError` subclass was added; only `NotFoundDomainError` is raised, in the use-case.
- [ ] Adapter does **not** log.

### Files and headers

- [ ] Every modified `.py` file keeps its `# FEATURE: get_post — …` header on line 1.
- [ ] No STABLE file was modified (no `bootstrap/container.py` or `bootstrap/router.py` change was needed; confirm none was made).

### DI

- [ ] `bootstrap/container.py` `get_post_adapter` / `get_post_use_case` providers are unchanged.
- [ ] `Container.wiring_config.modules` still includes the `get_post` router module.
- [ ] Endpoint still uses `Annotated[GetPostUseCase, Depends(Provide[Container.get_post_use_case])]`.

### Tests

- [ ] Use-case unit test at `tests/features/posts/0054_…/domain/test_use_case.py` passes (approved, author, privileged, non-author 404, missing 404).
- [ ] Adapter unit test at `tests/features/posts/0054_…/data/test_adapter.py` passes (found by id, wrong author, missing post, soft-deleted post, soft-deleted author, username from JOIN).
- [ ] Endpoint integration test at `tests/features/posts/0054_…/presentation/test_router.py` passes (200 approved/author/privileged, 404 non-author/unknown, 422 non-integer, old route gone).
- [ ] Outside-in test `tests/features/posts/0054_…/migrate_get_post_route_username_to_user_id_outside_in_test.py` is GREEN.
- [ ] The old `tests/features/posts/0026_get_post/` tests were updated to the integer route (or explicitly superseded) and the whole suite is green; baseline shows zero net-new failures.
- [ ] `conftest.py` uses savepoint-mode rollback (`join_transaction_mode="create_savepoint"`); no test leaves rows in the DB.

### Quality gates

Run from project root:

```
ruff format src/app tests
ruff check src/app tests
mypy src/app
pytest                       # includes tests/smoke/test_app_starts.py
```

Plus the architecture gate (import-linter via `.importlinter`, run from `api/src` with UTF-8 / `lint-imports`).

All must pass. If `tests/smoke/test_app_starts.py` fails after editing the router's relative imports, an import is using the wrong convention for its layer.
