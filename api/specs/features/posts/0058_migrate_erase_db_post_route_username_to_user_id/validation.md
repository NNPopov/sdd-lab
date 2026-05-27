# 0058 · migrate_erase_db_post_route_username_to_user_id — Validation

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md
- Requirements: ./requirements.md

## Prerequisites

- App running locally (`uvicorn app.main:app --reload` from `src/`).
- Test Postgres running (`docker compose up test-db -d`) and Redis running (the
  endpoint carries a `@cache` decorator; without Redis the cache scenarios cannot
  be exercised).
- The scripts `create_first_superuser` and `create_first_tier` must have been run
  once. At least one regular (non-superuser) user and one author whose integer
  `id` you know, with at least one post owned by that author.
- A valid Bearer token for the superuser and for a regular user, obtained via
  `POST /api/v1/login`.

Placeholders used below:

- `$USER_ID` — integer primary key of the post author.
- `$USERNAME` — that author's `username` string (used only to demonstrate the
  old route is gone).
- `$POST_ID` — id of a post owned by `$USER_ID`.
- `$TOKEN_SUPER` — JWT for a superuser.
- `$TOKEN_REGULAR` — JWT for a non-superuser user.
- `$UNKNOWN_ID` — an integer matching no user (e.g. `999999`).
- `$UNKNOWN_POST` — an integer matching no post (e.g. `999999`).

---

## Manual scenarios

### S1 — Happy path: superuser hard-deletes a post by integer ID

**Steps:**

1. Note a post `$POST_ID` owned by `$USER_ID`.
2. Send:
   ```
   curl -i -X DELETE http://localhost:8000/api/v1/$USER_ID/db_post/$POST_ID \
     -H "Authorization: Bearer $TOKEN_SUPER"
   ```

**Expected:**

- Status 200.
- Body `{"message": "Post deleted from the database"}`.

**Covers:** F1, F2, F13, F16, F18.

---

### S2 — Cache invalidation: read-after-delete returns 404

**Steps:**

1. Read the post to populate the cache:
   ```
   curl -i http://localhost:8000/api/v1/$USER_ID/post/$POST_ID \
     -H "Authorization: Bearer $TOKEN_SUPER"
   ```
2. Hard-delete it via S1.
3. Read it again (same GET as step 1).

**Expected:**

- The first read returns 200; the second read returns **404** — the hard delete
  invalidated `{user_id}_post_cache` (and `{user_id}_posts`), realigning with the
  keys `get_post` (0054) and `list_posts` (0042) read from. No stale read of the
  destroyed post.

**Covers:** F14, F15.

---

### S3 — Forbidden: non-superuser is rejected

**Steps:**

1. As a regular user (`$TOKEN_REGULAR`), target the author's ID and post:
   ```
   curl -i -X DELETE http://localhost:8000/api/v1/$USER_ID/db_post/$POST_ID \
     -H "Authorization: Bearer $TOKEN_REGULAR"
   ```

**Expected:**

- Status 403 (from the `get_current_superuser` gate; the use-case is never
  reached).

**Covers:** F4.

---

### S4 — Not found: unknown user_id → 404

**Steps:**

1. As a superuser, target an id matching no user:
   ```
   curl -i -X DELETE http://localhost:8000/api/v1/$UNKNOWN_ID/db_post/$POST_ID \
     -H "Authorization: Bearer $TOKEN_SUPER"
   ```

**Expected:**

- Status 404 (returned before the post lookup).
- Body `{"error": {"code": "notfound", "message": "User not found"}}`.

**Covers:** F5, F7.

---

### S5 — Not found: unknown post → 404

**Steps:**

1. As a superuser, target an unknown post id under a valid user_id:
   ```
   curl -i -X DELETE http://localhost:8000/api/v1/$USER_ID/db_post/$UNKNOWN_POST \
     -H "Authorization: Bearer $TOKEN_SUPER"
   ```

**Expected:**

- Status 404.
- Body `{"error": {"code": "notfound", "message": "Post not found"}}` — returned
  only after the user resolves.

**Covers:** F6, F7.

---

### S6 — Unauthenticated → 401

**Steps:**

1. Send without an `Authorization` header:
   ```
   curl -i -X DELETE http://localhost:8000/api/v1/$USER_ID/db_post/$POST_ID
   ```

**Expected:**

- Status 401. The use-case is never reached.

**Covers:** F3.

---

### S7 — Non-integer user_id → 422 (old string route is gone)

**Steps:**

1. Send with the author's username string instead of the ID:
   ```
   curl -i -X DELETE http://localhost:8000/api/v1/$USERNAME/db_post/$POST_ID \
     -H "Authorization: Bearer $TOKEN_SUPER"
   ```

**Expected:**

- Status 422.
- Body contains a `detail` array reporting that the path value is not a valid
  integer.

**Covers:** F9, F10.

---

### S8 — Superuser may delete any user's post (no ownership check)

**Steps:**

1. As a superuser whose own id differs from `$USER_ID`, delete a post owned by
   `$USER_ID` (same call as S1).

**Expected:**

- Status 200 — a superuser is not restricted to their own posts; there is no
  per-post ownership check.

**Covers:** F16.

---

## Code review checklist

### Architecture

- [ ] The `erase_db_post` slice files were modified **in place**; no new `src/app` slice folder was created for 0058.
- [ ] `EraseDbPostUseCase` is still a class with `__call__(command: EraseDbPostCommand) -> None`; only the lookup method and the field it reads changed (post fetch + hard delete steps unchanged).
- [ ] `EraseDbPostPort` lives in `domain/ports/erase_db_post_port.py`, carries `@runtime_checkable`, inherits `Protocol`, and its `find_post` / `hard_delete` signatures are unchanged.
- [ ] `EraseDbPostAdapter` class signature is `class EraseDbPostAdapter(EraseDbPostPort):` — explicit inheritance retained; the adapter file is unchanged.
- [ ] Adapters are the only files using SQLAlchemy directly; `domain/` and `presentation/` have no ORM imports.
- [ ] Router accepts `user_id: int` and `id: int` from the path, builds `EraseDbPostCommand`, awaits the use-case, returns `EraseDbPostResponse`.
- [ ] No cross-slice imports outside `features/posts/_shared/`; `erase_db_post` imports `UserLookupPort` from `posts/_shared` only.
- [ ] All imports inside `src/app/` are **relative**; no `from app…` / `from src.app…` in source.
- [ ] No `HTTPException` raised inside the use-case or adapter.
- [ ] The use-case contains no `try/except`.

### Migration correctness

- [ ] `EraseDbPostCommand` has `user_id: int` and `post_id: int`; `username` is gone; there is no requester field.
- [ ] `EraseDbPostAdapter` (`find_post`, `hard_delete`) is unchanged.
- [ ] Use-case calls `get_active_user_by_id(command.user_id)`, raises `NotFoundDomainError("User not found")` on `None`, then `find_post(command.post_id, owner_id=user.id)` raising `NotFoundDomainError("Post not found")` on `None`, then `hard_delete(command.post_id)` — 404(user)→404(post) ordering preserved.
- [ ] No ownership check and no `ForbiddenDomainError` were added to the use-case; the 403 comes only from `get_current_superuser`.
- [ ] No owner filter change was made to `find_post` (its `Post.created_by_user_id == owner_id` filter is preserved as-is).
- [ ] Router path is `"/{user_id}/db_post/{id}"`; command is built with `user_id=user_id`, `post_id=id`; the auth dependency stays `get_current_superuser`.
- [ ] `EraseDbPostResponse` shape is unchanged (`{"message": "Post deleted from the database"}`).

### Cache realignment

- [ ] The `@cache` decorator reads `key_prefix="{user_id}_post_cache"` and `to_invalidate_extra={"{user_id}_posts": "{user_id}"}`; `resource_id_name="id"` unchanged; no `{username}_…` key remains on this endpoint.
- [ ] These keys match what `get_post` (0054, `{user_id}_post_cache`) and `list_posts` (0042, `{user_id}_posts`) use, so a hard delete invalidates the exact keys those reads populate.

### Shared modules (consumed, not modified)

- [ ] `_shared/user_lookup_port.py` and `_shared/user_lookup_adapter.py` are **not** modified by this slice (`get_active_user_by_id` already present from 0055).
- [ ] `get_active_user_by_username` is **not** removed by this slice (cleanup-slice job), but has no remaining caller after it.

### Error handling

- [ ] No new `DomainError` subclass was added; only `NotFoundDomainError` (an existing STABLE subclass) is raised.
- [ ] The use-case contains no `try/except`; the adapter is unchanged and has no broad `except Exception`.
- [ ] No adapter logs exceptions.

### Files and headers

- [ ] Every modified `.py` file keeps its `# FEATURE: <slice> — …` header on line 1.
- [ ] No STABLE file was modified (no `bootstrap/container.py`, `bootstrap/router.py`, or `.importlinter` change was needed; confirm none was made).

### DI

- [ ] `bootstrap/container.py` `erase_db_post_adapter`, `erase_db_post_use_case` (wired with `port` and `user_lookup`), and `user_lookup_adapter` providers are unchanged.
- [ ] `Container.wiring_config.modules` still includes the `erase_db_post` router module.
- [ ] Endpoint still uses `Annotated[EraseDbPostUseCase, Depends(Provide[Container.erase_db_post_use_case])]`.

### Tests

- [ ] Use-case unit test at `tests/features/posts/0058_…/domain/test_use_case.py` passes (happy path, user not found, post not found / not owned; downstream ports not called on each error branch).
- [ ] Adapter unit test is **opted out** (the adapter is unchanged); the existing `0030_erase_db_post` / `0031_fix_erase_db_post_cascade` adapter tests still apply and pass.
- [ ] Endpoint integration test at `tests/features/posts/0058_…/presentation/test_router.py` passes (200 superuser, 403 non-superuser, 404 unknown user, 404 unknown post, 401 unauthenticated, 422 non-integer, old route gone, cache invalidation read-after-delete).
- [ ] Outside-in test `tests/features/posts/0058_…/migrate_erase_db_post_route_username_to_user_id_outside_in_test.py` is GREEN.
- [ ] The old `tests/features/posts/0030_erase_db_post/` and `tests/features/posts/0031_fix_erase_db_post_cascade/` tests were updated to the integer route and id-based command (or explicitly superseded) and the whole suite is green.
- [ ] Full-suite baseline before and after shows zero net-new failures (user memory `project_route_migration_downstream_tests`).
- [ ] `conftest.py` savepoint-mode rollback works; no test leaves rows in the DB.

### Quality gates

Run from project root:

```
ruff format src/app tests
ruff check src/app tests
mypy src/app
pytest
```

Plus the architecture gate (import-linter via `.importlinter`, run from `api/src` with UTF-8 / `lint-imports`).

All must pass. No `alembic` step is needed — `Post.created_by_user_id` already exists. If editing the router's relative imports breaks an import-level smoke test, an import is using the wrong convention for its layer.
</content>
