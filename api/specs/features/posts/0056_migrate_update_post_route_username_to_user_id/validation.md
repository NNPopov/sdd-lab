# 0056 · migrate_update_post_route_username_to_user_id — Validation

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md
- Requirements: ./requirements.md

## Prerequisites

- App running locally (`uvicorn app.main:app --reload` from `src/`).
- Test Postgres running (`docker compose up test-db -d`) and Redis running (the
  endpoint carries a `@cache` decorator; without Redis the cache scenarios cannot
  be exercised).
- At least two registered users whose integer `id`s you know. The scripts
  `create_first_superuser` and `create_first_tier` must have been run once.
- A valid Bearer token for each user, obtained via `POST /api/v1/login`.

Placeholders used below:

- `$USER_ID` — integer primary key of the authenticated author.
- `$USERNAME` — that author's `username` string (used only to demonstrate the
  old route is gone).
- `$OTHER_ID` — integer primary key of a different registered user.
- `$TOKEN_OWNER` — JWT for the author (`$USER_ID`).
- `$TOKEN_OTHER` — JWT for the different user (`$OTHER_ID`).
- `$POST_ID` — id of a post owned by `$USER_ID`.
- `$UNKNOWN_ID` — an integer matching no user (e.g. `999999`).
- `$UNKNOWN_POST` — an integer matching no post (e.g. `999999`).

---

## Manual scenarios

### S1 — Happy path: update your own post by integer ID

**Steps:**

1. Log in as the author to obtain `$TOKEN_OWNER`. Create or note a post `$POST_ID` owned by `$USER_ID`.
2. Send:
   ```
   curl -i -X PATCH http://localhost:8000/api/v1/$USER_ID/post/$POST_ID \
     -H "Authorization: Bearer $TOKEN_OWNER" \
     -H "Content-Type: application/json" \
     -d '{"title": "Updated title"}'
   ```

**Expected:**

- Status 200.
- Body `{"message": "Post updated"}`.

**Covers:** F1, F3, F14.

---

### S2 — Cache invalidation: read-after-update returns fresh content

**Steps:**

1. Read the post to populate the cache:
   ```
   curl -i http://localhost:8000/api/v1/$USER_ID/post/$POST_ID \
     -H "Authorization: Bearer $TOKEN_OWNER"
   ```
2. Update its title via S1.
3. Read it again (same GET as step 1).

**Expected:**

- The second read returns the **updated** title, not the cached old one — the
  update invalidated `{user_id}_post_cache` (and `{user_id}_posts:*`), realigning
  with the keys `get_post` (0054) and `list_posts` (0042) read from.

**Covers:** F15, F16.

---

### S3 — Forbidden: update a post under another user's ID

**Steps:**

1. As a different user (`$TOKEN_OTHER`), target the author's ID and post:
   ```
   curl -i -X PATCH http://localhost:8000/api/v1/$USER_ID/post/$POST_ID \
     -H "Authorization: Bearer $TOKEN_OTHER" \
     -H "Content-Type: application/json" \
     -d '{"title": "Hijack"}'
   ```

**Expected:**

- Status 403.
- Body carries no ownership-specific message (bare `ForbiddenDomainError()`):
  the old "You can only update your own posts" text is gone.

**Covers:** F6, F17.

---

### S4 — Not found: unknown user_id → 404 (before ownership)

**Steps:**

1. Send (authenticated) to an id matching no user:
   ```
   curl -i -X PATCH http://localhost:8000/api/v1/$UNKNOWN_ID/post/$POST_ID \
     -H "Authorization: Bearer $TOKEN_OWNER" \
     -H "Content-Type: application/json" \
     -d '{"title": "X"}'
   ```

**Expected:**

- Status 404 (returned before any ownership check).
- Body `{"error": {"code": "notfound", "message": "User not found"}}`.

**Covers:** F5, F8.

---

### S5 — Not found: unknown post → 404

**Steps:**

1. As the owner, target an unknown post id under your own user_id:
   ```
   curl -i -X PATCH http://localhost:8000/api/v1/$USER_ID/post/$UNKNOWN_POST \
     -H "Authorization: Bearer $TOKEN_OWNER" \
     -H "Content-Type: application/json" \
     -d '{"title": "X"}'
   ```

**Expected:**

- Status 404.
- Body `{"error": {"code": "notfound", "message": "Post not found"}}` — returned
  only after the user resolves and ownership passes.

**Covers:** F7, F8.

---

### S6 — Unauthenticated → 401

**Steps:**

1. Send without an `Authorization` header:
   ```
   curl -i -X PATCH http://localhost:8000/api/v1/$USER_ID/post/$POST_ID \
     -H "Content-Type: application/json" \
     -d '{"title": "X"}'
   ```

**Expected:**

- Status 401. The use-case is never reached.

**Covers:** F4.

---

### S7 — Non-integer user_id → 422 (old string route is gone)

**Steps:**

1. Send with the author's username string instead of the ID:
   ```
   curl -i -X PATCH http://localhost:8000/api/v1/$USERNAME/post/$POST_ID \
     -H "Authorization: Bearer $TOKEN_OWNER" \
     -H "Content-Type: application/json" \
     -d '{"title": "X"}'
   ```

**Expected:**

- Status 422.
- Body contains a `detail` array reporting that the path value is not a valid
  integer.

**Covers:** F10, F11.

---

### S8 — Invalid body → 422

**Steps:**

1. Send (authenticated) with a title under 2 chars or an extra field:
   ```
   curl -i -X PATCH http://localhost:8000/api/v1/$USER_ID/post/$POST_ID \
     -H "Authorization: Bearer $TOKEN_OWNER" \
     -H "Content-Type: application/json" \
     -d '{"title": "x", "rogue": 1}'
   ```

**Expected:**

- Status 422 (`title` violates `min_length=2`; `rogue` violates `extra="forbid"`).

**Covers:** F2.

---

## Code review checklist

### Architecture

- [ ] The `update_post` slice files were modified **in place**; no new `src/app` slice folder was created for 0056.
- [ ] `UpdatePostUseCase` is still a class with `__call__(command: UpdatePostCommand) -> None`; only the lookup, ownership, and imports changed (post fetch + update steps unchanged).
- [ ] `UpdatePostPort` lives in `domain/ports/update_post_port.py`, carries `@runtime_checkable`, inherits `Protocol`, and its `get_post_by_id` / `update` signatures are unchanged.
- [ ] `UpdatePostAdapter` class signature is `class UpdatePostAdapter(UpdatePostPort):` — explicit inheritance retained; the adapter file is unchanged.
- [ ] Adapters are the only files using SQLAlchemy directly; `domain/`, `presentation/`, and `_shared/policies.py` have no ORM imports.
- [ ] Router accepts `user_id: int` and `id: int` from the path, builds `UpdatePostCommand`, awaits the use-case, returns `UpdatePostResponse`.
- [ ] No cross-slice imports outside `features/posts/_shared/`; `update_post` imports `check_post_owner` and `UserLookupPort` from `posts/_shared` only.
- [ ] All imports inside `src/app/` are **relative**; no `from app…` / `from src.app…` in source.
- [ ] No `HTTPException` raised inside the use-case, adapter, or policy.

### Migration correctness

- [ ] `UpdatePostCommand` has `target_user_id: int` and `requester_user_id: int`; `target_username` and `requester_username` are gone. `post_id`, `title`, `text`, `media_url` unchanged.
- [ ] `UpdatePostAdapter` (`get_post_by_id`, `update`) is unchanged.
- [ ] Use-case calls `get_active_user_by_id(command.target_user_id)`, raises `NotFoundDomainError("User not found")` on `None`, then `check_post_owner(command.requester_user_id, author.id)`, then `get_post_by_id(command.post_id)` raising `NotFoundDomainError("Post not found")` on `None`, then `update(command)` — 404(user)→403(owner)→404(post) ordering preserved.
- [ ] The inline username comparison and the "You can only update your own posts" message are removed; `ForbiddenDomainError` is no longer imported by the use-case.
- [ ] No owner filter was added to `get_post_by_id` (pre-existing gap preserved).
- [ ] Router path is `"/{user_id}/post/{id}"`; command is built with `target_user_id=user_id`, `requester_user_id=current_user["id"]`, `post_id=id`.
- [ ] `UpdatePostResponse` / `UpdatePostRequest` fields are unchanged from 0028.

### Cache realignment

- [ ] The `@cache` decorator reads `key_prefix="{user_id}_post_cache"` and `pattern_to_invalidate_extra=["{user_id}_posts:*"]`; `resource_id_name="id"` unchanged; no `{username}_…` key remains on this endpoint.
- [ ] These keys match what `get_post` (0054, `{user_id}_post_cache`) and `list_posts` (0042, `{user_id}_posts:*`) use, so an update invalidates the exact keys those reads populate.

### Shared modules (consumed, not modified)

- [ ] `_shared/policies.py`, `_shared/user_lookup_port.py`, and `_shared/user_lookup_adapter.py` are **not** modified by this slice (already id-based from 0055).
- [ ] `erase_post/**` is **not** modified by this slice (already adapted by 0055).

### Error handling

- [ ] No new `DomainError` subclass was added; only `NotFoundDomainError` and `ForbiddenDomainError` (existing STABLE subclasses) are raised.
- [ ] The use-case contains no `try/except`; the adapter is unchanged and has no broad `except Exception`.
- [ ] No adapter or policy logs exceptions.

### Files and headers

- [ ] Every modified `.py` file keeps its `# FEATURE: <slice> — …` header on line 1.
- [ ] No STABLE file was modified (no `bootstrap/container.py`, `bootstrap/router.py`, or `.importlinter` change was needed; confirm none was made).

### DI

- [ ] `bootstrap/container.py` `update_post_adapter`, `update_post_use_case`, and `user_lookup_adapter` providers are unchanged.
- [ ] `Container.wiring_config.modules` still includes the `update_post` router module.
- [ ] Endpoint still uses `Annotated[UpdatePostUseCase, Depends(Provide[Container.update_post_use_case])]`.

### Tests

- [ ] Use-case unit test at `tests/features/posts/0056_…/domain/test_use_case.py` passes (happy path owner, user not found, not owner, post not found; downstream ports not called on each error branch).
- [ ] Adapter unit test is **opted out** (the adapter is unchanged); the existing `0028_update_post` adapter test still applies and passes.
- [ ] Endpoint integration test at `tests/features/posts/0056_…/presentation/test_router.py` passes (200 owner, 403 non-owner, 404 unknown user, 404 unknown post, 401 unauthenticated, 422 non-integer, old route gone, cache invalidation read-after-update).
- [ ] Outside-in test `tests/features/posts/0056_…/migrate_update_post_route_username_to_user_id_outside_in_test.py` is GREEN.
- [ ] The old `tests/features/posts/0028_update_post/` tests were updated to the integer route and id-based command (or explicitly superseded) and the whole suite is green.
- [ ] Full-suite baseline before and after shows zero net-new failures (user memory `project_route_migration_downstream_tests`).
- [ ] `conftest.py` savepoint-mode rollback works; no test leaves rows in the DB.

### Quality gates

Run from project root:

```
ruff format src/app tests
ruff check src/app tests
mypy src/app
pytest                       # includes tests/smoke/test_app_starts.py
```

Plus the architecture gate (import-linter via `.importlinter`, run from `api/src` with UTF-8 / `lint-imports`).

All must pass. No `alembic` step is needed — `Post.created_by_user_id` already exists. If `tests/smoke/test_app_starts.py` fails after editing the router's relative imports, an import is using the wrong convention for its layer.
