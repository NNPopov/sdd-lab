# 0042 · migrate_list_posts_route_username_to_user_id — Validation

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

- `$USER_ID` — integer primary key of the author whose posts you list.
- `$USERNAME` — that author's `username` string (used only to demonstrate the
  old route is gone).
- `$TOKEN_OWNER` — JWT for the author (`$USER_ID`).
- `$TOKEN_OTHER` — JWT for a different, already-registered user.

---

## Manual scenarios

### S1 — Happy path: list a user's posts by integer ID (unauthenticated, public view)

**Steps:**

1. Ensure `$USER_ID` has one `approved` and one `pending` post.
2. Send:
   ```
   curl http://localhost:8000/api/v1/$USER_ID/posts
   ```

**Expected:**

- Status 200.
- Body has keys `items`, `total_count`, `page`, `items_per_page`.
- Only the `approved` post appears; `total_count == 1`.
- Each item includes `username` equal to the author's handle (from the JOIN),
  and `created_by_user_id == $USER_ID`.

**Covers:** F1, F3, F8, F18.

---

### S2 — Author view: owner sees non-approved posts

**Steps:**

1. Log in as the author to obtain `$TOKEN_OWNER`.
2. Send:
   ```
   curl http://localhost:8000/api/v1/$USER_ID/posts \
     -H "Authorization: Bearer $TOKEN_OWNER"
   ```

**Expected:**

- Status 200.
- Both the `approved` and the `pending` post appear; `total_count == 2`.

**Covers:** F4, F15, F16.

---

### S3 — Non-author authenticated view: only approved posts

**Steps:**

1. Log in as a different user to obtain `$TOKEN_OTHER`.
2. Send:
   ```
   curl http://localhost:8000/api/v1/$USER_ID/posts \
     -H "Authorization: Bearer $TOKEN_OTHER"
   ```

**Expected:**

- Status 200.
- Only the `approved` post appears; `total_count == 1` (same as the public view).

**Covers:** F5, F15.

---

### S4 — Empty result for an existing user with no visible posts

**Steps:**

1. Pick a `$USER_ID` that has no posts (or whose only posts are non-approved,
   called unauthenticated).
2. Send:
   ```
   curl http://localhost:8000/api/v1/$USER_ID/posts
   ```

**Expected:**

- Status 200.
- Body: `items == []`, `total_count == 0`, `page == 1`, `items_per_page == 10`.

**Covers:** F6.

---

### S5 — Unknown user_id returns empty list, not 404

**Steps:**

1. Send with an integer ID that does not exist (e.g. 999999):
   ```
   curl http://localhost:8000/api/v1/999999/posts
   ```

**Expected:**

- Status 200.
- Body: `items == []`, `total_count == 0`.

**Covers:** F7.

---

### S6 — Non-integer user_id → 422 (old string route is gone)

**Steps:**

1. Send with the author's username string instead of the ID:
   ```
   curl -i http://localhost:8000/api/v1/$USERNAME/posts
   ```

**Expected:**

- Status 422.
- Body contains a `detail` array reporting that the path value is not a valid
  integer.

**Covers:** F2, F10.

---

### S7 — Pagination

**Steps:**

1. Ensure `$USER_ID` has at least 3 approved posts.
2. Send:
   ```
   curl "http://localhost:8000/api/v1/$USER_ID/posts?page=1&items_per_page=2"
   curl "http://localhost:8000/api/v1/$USER_ID/posts?page=2&items_per_page=2"
   ```

**Expected:**

- Page 1: `len(items) == 2`, `page == 1`, `items_per_page == 2`,
  `total_count == 3`.
- Page 2: `len(items) == 1`, `page == 2`.

**Covers:** F9.

---

### S8 — Cache key keyed by user_id

**Steps:**

1. Send S1 twice in quick succession (within the 60s TTL).
2. (Optional) Inspect Redis keys: `redis-cli KEYS "$USER_ID_posts:*"`.

**Expected:**

- Second response is served identically (cache hit), under a key beginning with
  `$USER_ID_posts:`. No key beginning with `$USERNAME_posts:` is written.

**Covers:** F17.

---

## Code review checklist

### Architecture

- [ ] `list_posts` slice files were modified **in place**; no new `src/app` slice folder was created for 0042.
- [ ] `ListPostsUseCase` is still a class with `__call__(query: ListPostsQuery) -> PostPage` and remains a pure pass-through (no username/user_id logic leaked into it).
- [ ] `ListPostsPort` lives in `domain/ports/list_posts_port.py`, carries `@runtime_checkable`, inherits `Protocol`, and its `list(query: ListPostsQuery)` signature is unchanged.
- [ ] `ListPostsAdapter` class signature is `class ListPostsAdapter(ListPostsPort):` — explicit inheritance retained.
- [ ] `ListPostsAdapter` is the only file using SQLAlchemy directly; `domain/` and `presentation/` have no ORM imports.
- [ ] Router accepts `user_id: int` from the path, builds `ListPostsQuery`, awaits the use-case, returns `ListPostsResponse`.
- [ ] No cross-slice imports outside `features/posts/_shared/`.
- [ ] All imports inside `src/app/` are **relative**; no `from app…` / `from src.app…` in source.
- [ ] No `HTTPException` raised inside the use-case or adapter.

### Migration correctness

- [ ] `ListPostsQuery` has `user_id: int` and `requester_user_id: int | None`; `username` and `requester_username` are gone.
- [ ] Adapter filters on `Post.created_by_user_id == query.user_id` in both the count and rows statements — no `User.username == …` filter remains.
- [ ] `is_author = query.requester_user_id == query.user_id`.
- [ ] The `Post → User` JOIN and `User.is_deleted == False` guard are retained in both statements (count and rows stay consistent); each `PostItem.username` comes from the JOIN.
- [ ] Router path is `"/{user_id}/posts"`; `_get_view` compares `optional_user.get("id") == user_id`.
- [ ] Cache `key_prefix` is `"{user_id}_posts:…"` and `resource_id_name="user_id"`.
- [ ] `requester_user_id = user_id if view == "author" else None` in the endpoint.
- [ ] `ListPostsResponse` / `PostItemSchema` fields are unchanged from 0009.

### Error handling

- [ ] `ListPostsAdapter.list` has **no `try/except`** (read-only query; nothing business-meaningful to translate).
- [ ] No new `DomainError` subclass was added.
- [ ] Adapter does **not** log.

### Files and headers

- [ ] Every modified `.py` file keeps its `# FEATURE: list_posts — …` header on line 1.
- [ ] No STABLE file was modified (no `bootstrap/container.py` or `bootstrap/router.py` change was needed; confirm none was made).

### DI

- [ ] `bootstrap/container.py` `list_posts_adapter` / `list_posts_use_case` providers are unchanged.
- [ ] `Container.wiring_config.modules` still includes the `list_posts` router module.
- [ ] Endpoint still uses `Annotated[ListPostsUseCase, Depends(Provide[Container.list_posts_use_case])]`.

### Tests

- [ ] Use-case unit test at `tests/features/posts/0042_…/domain/test_use_case.py` passes (author vs public query, pass-through).
- [ ] Adapter unit test at `tests/features/posts/0042_…/data/test_adapter.py` passes (public/author/empty/unknown, username from JOIN).
- [ ] Endpoint integration test at `tests/features/posts/0042_…/presentation/test_router.py` passes (200 views, 422, empty, pagination).
- [ ] Outside-in test `tests/features/posts/0042_…/migrate_list_posts_route_username_to_user_id_outside_in_test.py` is GREEN.
- [ ] The old `tests/features/posts/0009_list_posts/list_posts_outside_in_test.py` was updated to the integer route (or explicitly superseded) and the whole suite is green.
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
