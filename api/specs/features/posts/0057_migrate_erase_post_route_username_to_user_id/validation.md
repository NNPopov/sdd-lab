# 0057 · migrate_erase_post_route_username_to_user_id — Validation

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

### S1 — Happy path: delete your own post by integer ID

**Steps:**

1. Log in as the author to obtain `$TOKEN_OWNER`. Create or note a post `$POST_ID` owned by `$USER_ID`.
2. Send:
   ```
   curl -i -X DELETE http://localhost:8000/api/v1/$USER_ID/post/$POST_ID \
     -H "Authorization: Bearer $TOKEN_OWNER"
   ```

**Expected:**

- Status 200.
- Body `{"message": "Post deleted"}`.

**Covers:** F1, F2, F13.

---

### S2 — Cache invalidation: read-after-delete returns 404

**Steps:**

1. Read the post to populate the cache:
   ```
   curl -i http://localhost:8000/api/v1/$USER_ID/post/$POST_ID \
     -H "Authorization: Bearer $TOKEN_OWNER"
   ```
2. Delete it via S1.
3. Read it again (same GET as step 1).

**Expected:**

- The second read returns 404 — the delete invalidated `{user_id}_post_cache`
  (and `{user_id}_posts`), realigning with the keys `get_post` (0054) and
  `list_posts` (0042) read from. No stale 200 from the cache.

**Covers:** F14, F15.

---

### S3 — Forbidden: delete a post under another user's ID

**Steps:**

1. As a different user (`$TOKEN_OTHER`), target the author's ID and post:
   ```
   curl -i -X DELETE http://localhost:8000/api/v1/$USER_ID/post/$POST_ID \
     -H "Authorization: Bearer $TOKEN_OTHER"
   ```

**Expected:**

- Status 403.
- Body carries no ownership-specific message (bare `ForbiddenDomainError()`).

**Covers:** F5, F16.

---

### S4 — Not found: unknown user_id → 404 (before ownership)

**Steps:**

1. Send (authenticated) to an id matching no user:
   ```
   curl -i -X DELETE http://localhost:8000/api/v1/$UNKNOWN_ID/post/$POST_ID \
     -H "Authorization: Bearer $TOKEN_OWNER"
   ```

**Expected:**

- Status 404 (returned before any ownership check).
- Body `{"error": {"code": "notfound", "message": "User not found"}}`.

**Covers:** F4, F7.

---

### S5 — Not found: unknown post → 404

**Steps:**

1. As the owner, target an unknown post id under your own user_id:
   ```
   curl -i -X DELETE http://localhost:8000/api/v1/$USER_ID/post/$UNKNOWN_POST \
     -H "Authorization: Bearer $TOKEN_OWNER"
   ```

**Expected:**

- Status 404.
- Body `{"error": {"code": "notfound", "message": "Post not found"}}` — returned
  only after the user resolves and ownership passes.

**Covers:** F6, F7, F18.

---

### S6 — Unauthenticated → 401

**Steps:**

1. Send without an `Authorization` header:
   ```
   curl -i -X DELETE http://localhost:8000/api/v1/$USER_ID/post/$POST_ID
   ```

**Expected:**

- Status 401. The use-case is never reached.

**Covers:** F3.

---

### S7 — Non-integer user_id → 422 (old string route is gone)

**Steps:**

1. Send with the author's username string instead of the ID:
   ```
   curl -i -X DELETE http://localhost:8000/api/v1/$USERNAME/post/$POST_ID \
     -H "Authorization: Bearer $TOKEN_OWNER"
   ```

**Expected:**

- Status 422.
- Body contains a `detail` array reporting that the path value is not a valid
  integer.

**Covers:** F9, F10.

---

## Code review checklist

### Architecture

- [ ] The `erase_post` slice files were modified **in place**; no new `src/app` slice folder was created for 0057.
- [ ] `ErasePostUseCase` is still a class with `__call__(command: ErasePostCommand) -> None`; only the target lookup line changed (ownership, owner-scoped post fetch, soft delete unchanged).
- [ ] `ErasePostPort` lives in `domain/ports/erase_post_port.py`, carries `@runtime_checkable`, inherits `Protocol`, and its `find_post` / `soft_delete` signatures are unchanged.
- [ ] `ErasePostAdapter` class signature is `class ErasePostAdapter(ErasePostPort):` — explicit inheritance retained; the adapter file is unchanged.
- [ ] Adapters are the only files using SQLAlchemy directly; `domain/`, `presentation/`, and `_shared/policies.py` have no ORM imports.
- [ ] Router accepts `user_id: int` and `id: int` from the path, builds `ErasePostCommand`, awaits the use-case, returns `ErasePostResponse`.
- [ ] No cross-slice imports outside `features/posts/_shared/`; `erase_post` imports `check_post_owner` and `UserLookupPort` from `posts/_shared` only.
- [ ] All imports inside `src/app/` are **relative**; no `from app…` / `from src.app…` in source.
- [ ] No `HTTPException` raised inside the use-case, adapter, or policy.

### Migration correctness

- [ ] `ErasePostCommand` has `user_id: int`, `post_id: int`, `requester_user_id: int`; the `username` field is gone. `post_id` and `requester_user_id` unchanged from 0055.
- [ ] `ErasePostAdapter` (`find_post`, `soft_delete`) is unchanged.
- [ ] Use-case calls `get_active_user_by_id(command.user_id)`, raises `NotFoundDomainError("User not found")` on `None`, then `check_post_owner(command.requester_user_id, user.id)`, then `find_post(command.post_id, owner_id=user.id)` raising `NotFoundDomainError("Post not found")` on `None`, then `soft_delete(command.post_id)` — 404(user)→403(owner)→404(post) ordering preserved.
- [ ] `get_active_user_by_username` is no longer called by `erase_post`'s use-case.
- [ ] The owner-scoped `find_post(..., owner_id=user.id)` is preserved (a post not owned by `user_id` is reported as 404).
- [ ] Router path is `"/{user_id}/post/{id}"`; command is built with `user_id=user_id`, `post_id=id`, `requester_user_id=current_user["id"]`.
- [ ] `ErasePostResponse` field (`message: str`) is unchanged from 0029.

### Cache realignment

- [ ] The `@cache` decorator reads `key_prefix="{user_id}_post_cache"` and `to_invalidate_extra={"{user_id}_posts": "{user_id}"}`; `resource_id_name="id"` unchanged; no `{username}_…` key remains on this endpoint.
- [ ] The `to_invalidate_extra` **dict** form is preserved (not switched to `pattern_to_invalidate_extra`); both the key template and the id template were repointed to `user_id`.
- [ ] These keys match what `get_post` (0054, `{user_id}_post_cache`) and `list_posts` (0042, `{user_id}_posts`) use, so a delete invalidates the exact keys those reads populate.

### Shared modules (consumed, not modified)

- [ ] `_shared/policies.py`, `_shared/user_lookup_port.py`, and `_shared/user_lookup_adapter.py` are **not** modified by this slice (already id-based from 0055).
- [ ] `get_active_user_by_username` is left intact on the port/adapter (still needed by `erase_db_post`); only `erase_post` stops calling it.

### Error handling

- [ ] No new `DomainError` subclass was added; only `NotFoundDomainError` and `ForbiddenDomainError` (existing STABLE subclasses) are raised.
- [ ] The use-case contains no `try/except`; the adapter is unchanged and has no broad `except Exception`.
- [ ] No adapter or policy logs exceptions.

### Files and headers

- [ ] Every modified `.py` file keeps its `# FEATURE: <slice> — …` header on line 1.
- [ ] No STABLE file was modified (no `bootstrap/container.py`, `bootstrap/router.py`, or `.importlinter` change was needed; confirm none was made).

### DI

- [ ] `bootstrap/container.py` `erase_post_adapter`, `erase_post_use_case`, and `user_lookup_adapter` providers are unchanged.
- [ ] `Container.wiring_config.modules` still includes the `erase_post` router module.
- [ ] Endpoint still uses `Annotated[ErasePostUseCase, Depends(Provide[Container.erase_post_use_case])]`.

### Tests

- [ ] Use-case unit test at `tests/features/posts/0057_…/domain/test_use_case.py` passes (happy path owner, user not found, not owner, post not found; downstream ports not called on each error branch).
- [ ] Adapter unit test is **opted out** (the adapter is unchanged); the existing `0029_erase_post` adapter test still applies and passes.
- [ ] Endpoint integration test at `tests/features/posts/0057_…/presentation/test_router.py` passes (200 owner, 403 non-owner, 404 unknown user, 404 unknown post, 401 unauthenticated, 422 non-integer, old route gone, cache invalidation read-after-delete).
- [ ] Outside-in test `tests/features/posts/0057_…/migrate_erase_post_route_username_to_user_id_outside_in_test.py` is GREEN.
- [ ] The old `tests/features/posts/0029_erase_post/` tests were updated to the integer route and id-based command (or explicitly superseded) and the whole suite is green.
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
