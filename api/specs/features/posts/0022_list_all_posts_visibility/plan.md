# 0022 · list_all_posts_visibility — Implementation plan

## 1. Header

- **Feature:** posts
- **Slice:** 0022_list_all_posts_visibility
- **PRD:** ./prd.md
- **Reference slice:** `../0021_list_posts_visibility/plan.md` — same visibility-filtering
  operation shape; this slice follows the identical pattern adapted for the global feed.
- **HTTP path:** `GET /api/v1/posts` (same endpoint, changed behaviour)
- **STABLE files touched:** None.
  - `bootstrap/container.py` — not modified; existing `list_all_posts_adapter` and
    `list_all_posts_use_case` providers absorb `ListAllPostsQuery`'s new field
    transparently. No new providers are needed.
  - `adapters/db/models/post.py` — not modified; `Post.status` column already exists
    from slice 0013.

## 2. Context summary

`GET /api/v1/posts` currently returns every non-deleted post regardless of moderation
status. This slice adds visibility filtering: unauthenticated callers and authenticated
non-privileged users receive only posts with `status = 'approved'`; moderators and
superusers receive all posts regardless of status. The filtering decision is made
entirely in the adapter based on the `requester_is_privileged` field added to
`ListAllPostsQuery`. The router resolves the optional caller identity via the existing
`get_optional_user` dependency and injects a `view` parameter (`"privileged"` or
`"public"`) that drives both the cache key split and the query command. `status` and
its mapping in the adapter are already in place from slice 0021; this slice adds only
the conditional filter and the router change. No new use-case, port, adapter class,
DI provider, or migration is introduced — all changes are modifications to existing
files.

## 3. API contract

**Request body:** none (GET endpoint).

**Query parameters:**

| Param | Type | Default | Validation |
|---|---|---|---|
| `page` | `int` | `1` | `ge=1` |
| `items_per_page` | `int` | `10` | `ge=1`, `le=100` |

**Authentication:** Optional Bearer token (resolved by `get_optional_user`).

**Response body** (`ListAllPostsResponse`) — unchanged; `status` field already present
from slice 0021. Each `PostItemSchema`:

| Field | Type | Source |
|---|---|---|
| `id` | `int` | `post.id` |
| `title` | `str` | `post.title` |
| `text` | `str` | `post.text` |
| `media_url` | `str \| None` | `post.media_url` |
| `created_at` | `datetime` | `post.created_at` |
| `created_by_user_id` | `int` | `post.created_by_user_id` |
| `username` | `str` | `user.username` (via JOIN) |
| `status` | `str` | `post.status` (already mapped in 0021) |

**Status codes:** unchanged — `200 OK` for all visibility scenarios (including empty
result when there are no approved posts). No new `DomainError` is raised.

## 4. File structure

This slice modifies existing files only. No new files are created inside
`list_all_posts/`.

Files modified:

```
src/app/features/posts/list_all_posts/
├── domain/
│   └── commands.py          # add requester_is_privileged: bool = False
├── data/
│   └── adapter.py           # conditional WHERE status = 'approved'
└── presentation/
    └── router.py            # add _get_view helper, get_optional_user dep, update cache key
```

Pre-existing test file updated (pre-condition for implementation):

```
tests/features/posts/0010_list_all_posts/
└── conftest.py              # set status='approved' on seeded posts in seed_users_and_posts fixture
```

New test files:

```
tests/features/posts/0022_list_all_posts_visibility/
├── __init__.py
├── data/
│   ├── __init__.py
│   └── test_adapter.py
├── presentation/
│   ├── __init__.py
│   └── test_router.py
└── list_all_posts_visibility_outside_in_test.py
```

## 5. Implementation steps

### Step 0 — Pre-condition: update 0010 outside-in test and conftest

**File:** `tests/features/posts/0010_list_all_posts/conftest.py`

The `seed_users_and_posts` fixture creates posts without setting `status`, so they
default to `pending_review`. After this slice, an unauthenticated caller sees only
`approved` posts — the 0010 outside-in test would assert `total_count == 3` against
an actual 0.

Fix: pass `status="approved"` to each `Post(...)` constructor in the
`seed_users_and_posts` fixture. No other change to the fixture.

Also check `tests/features/posts/0010_list_all_posts/list_all_posts_outside_in_test.py`
and any other tests under that folder that rely on the fixture: if they assert on
`total_count` or item count, they must continue to pass after posts are seeded as
`approved`. The `test_list_all_posts_happy_path` test's assertions are unaffected
because the count stays at 3 (all three posts now carry `status='approved'`).

This step must be completed and verified (**run the 0010 outside-in test green**) before
any production code is changed.

### Step 1 — Domain: extend `ListAllPostsQuery`

**File:** `src/app/features/posts/list_all_posts/domain/commands.py`

Add `requester_is_privileged: bool = False` to `ListAllPostsQuery`. A `False` value
means the caller is unauthenticated or a regular user; `True` means moderator or
superuser. The default preserves backward compatibility for any caller that does not
set the field.

### Step 2 — Data: add visibility filter to `ListAllPostsAdapter`

**File:** `src/app/features/posts/list_all_posts/data/adapter.py`

Modify `async def list(self, query: ListAllPostsQuery) -> PostPage`:

1. After opening the session, derive the filter flag:
   ```python
   apply_filter = not query.requester_is_privileged
   ```
2. In the **count query**, add `.where(Post.status == "approved")` when `apply_filter`:
   ```python
   if apply_filter:
       count_stmt = count_stmt.where(Post.status == "approved")
   ```
3. In the **rows query**, add the same conditional clause:
   ```python
   if apply_filter:
       rows_stmt = rows_stmt.where(Post.status == "approved")
   ```

The `PostItem` construction already includes `status=post.status` from slice 0021;
no further changes to the mapping.

No `try/except` — this remains a read-only query with no business-meaningful exception
path (per `agent_docs/error_handling.md`).

### Step 3 — Presentation: update router

**File:** `src/app/features/posts/list_all_posts/presentation/router.py`

Three changes:

**a) New import:**

```python
from typing import Annotated
from fastapi import Depends
from .....features.users.dependencies import get_optional_user
```

Note: the `Annotated` import and `Depends` from fastapi are already present; add only
the `get_optional_user` import using the correct relative path from
`list_all_posts/presentation/router.py`:
`from .....features.users.dependencies import get_optional_user`

**b) New `_get_view` helper** (defined in the module, below
`_get_list_all_posts_use_case`):

```python
async def _get_view(
    optional_user: Annotated[dict | None, Depends(get_optional_user)],
) -> str:
    if optional_user and (
        optional_user.get("is_moderator") or optional_user.get("is_superuser")
    ):
        return "privileged"
    return "public"
```

`_get_view` returns `"privileged"` when the caller is a moderator or superuser, and
`"public"` for all other callers. FastAPI caches `get_optional_user` within the
request, so the dependency is not called twice.

**c) Update the endpoint**:

- Update the `@cache` key_prefix to:
  `"all_posts:{view}:page_{page}:items_per_page:{items_per_page}"`
- Add `view: Annotated[str, Depends(_get_view)]` as an endpoint parameter (the cache
  decorator interpolates `view` from kwargs).
- Inside the endpoint body, derive `requester_is_privileged` from `view` and build the
  query:
  ```python
  query = ListAllPostsQuery(
      page=page,
      items_per_page=items_per_page,
      requester_is_privileged=(view == "privileged"),
  )
  ```

The existing `pattern_to_invalidate_extra` patterns on write/patch/delete endpoints
(if any) use `all_posts:*`, which covers both `all_posts:privileged:*` and
`all_posts:public:*` — no changes needed there.

### Step 4 — Verify

```
ruff format src/app
ruff check src/app
mypy src/app
pytest
```

Outside-in test for this slice:

```
pytest tests/features/posts/0022_list_all_posts_visibility/list_all_posts_visibility_outside_in_test.py -v
```

0010 outside-in test (must remain green throughout):

```
pytest tests/features/posts/0010_list_all_posts/list_all_posts_outside_in_test.py -v
```

The slice is not done until all tests pass, including the smoke test at
`tests/smoke/test_app_starts.py`.

## 6. Tests planned

### Use-case unit test

**Opt-out.** `ListAllPostsUseCase` remains a thin pass-through with no branches and no
`DomainError` paths. A unit test adds no value per PRD § Testing Decisions.

### Adapter unit test

**File:** `tests/features/posts/0022_list_all_posts_visibility/data/test_adapter.py`

Using a real async session against the test Postgres database (no mocks), seed users
and posts with explicit `status` values, then call `ListAllPostsAdapter.list()` directly.
Assert:

- `requester_is_privileged = False` (unauthenticated / regular user): only posts with
  `status = 'approved'` are returned; `total_count` reflects filtered count.
- `requester_is_privileged = True` (moderator or superuser): all posts regardless of
  status are returned; `total_count` reflects unfiltered count.
- The `status` field is correctly populated on every returned `PostItem`.
- Empty `PostPage` (zero approved posts, non-privileged query): `total_count == 0`,
  `items == []`.

No exception-path assertions — the adapter has no `try/except`.

Prior art: `tests/features/posts/0021_list_posts_visibility/data/test_adapter.py` (same
real-session pattern) and `tests/features/posts/0009_list_posts/data/test_adapter.py`.

### Endpoint integration test

**File:** `tests/features/posts/0022_list_all_posts_visibility/presentation/test_router.py`

`httpx.AsyncClient` against the running app with test Postgres. Seed one approved post
and one pending post. Assert:

- Unauthenticated `GET /api/v1/posts` → HTTP 200, one item, `status == 'approved'`.
- Authenticated as a regular user → HTTP 200, one item, `status == 'approved'`.
- Authenticated as a moderator → HTTP 200, two items (both statuses present).
- Authenticated as a superuser → HTTP 200, two items (both statuses present).
- Zero approved posts (unauthenticated) → HTTP 200, `items: []`, `total_count: 0`.
- `status` field present in every response item.

Prior art: `tests/features/posts/0010_list_all_posts/` integration test (if present);
`tests/features/posts/0021_list_posts_visibility/presentation/test_router.py`.

### Outside-in test

**File:**
`tests/features/posts/0022_list_all_posts_visibility/list_all_posts_visibility_outside_in_test.py`

Full HTTP stack with real adapter, test Postgres, no mocks. Scenario per PRD §
Outside-in test:

1. Register and authenticate `alice`.
2. `alice` creates three posts (all default to `pending_review`).
3. Directly update one post to `status = 'approved'` via the test session factory.
4. Register a moderator (`mod`) — requires a seeded superuser; use the assign-moderator
   endpoint (`POST /api/v1/users/{username}/moderator`).
5. Unauthenticated `GET /api/v1/posts` → HTTP 200, exactly one item,
   `status == 'approved'`.
6. Authenticated `GET /api/v1/posts` as `alice` (regular user) → HTTP 200, exactly
   one item, `status == 'approved'`.
7. Authenticated `GET /api/v1/posts` as `mod` (moderator) → HTTP 200, all three items
   regardless of status.

This is the acceptance gate. The slice is not done until this test is green and the
0010 outside-in test also remains green.

**Opt-outs:** use-case unit test only (justified above).

## 7. Out of scope for this slice

- Visibility filtering on `GET /api/v1/{username}/posts` — that was slice 0021.
- Exposing the full `PostModerationLog` on global feed items — available through the
  pending-posts queue (slice 0019).
- Adding `post_uuid` to global feed response items.
- Cache invalidation when a post's status changes — existing `all_posts:*` wildcard
  patterns cover both the `privileged` and `public` cache segments automatically.
- Rate limiting beyond what already exists on the endpoint.
- Pagination or filtering beyond `page` / `items_per_page`.

## 8. Open questions

None. All decisions resolved in the PRD:

- Privileged = `is_moderator or is_superuser`; no other role grants full visibility.
- Cache key split via `_get_view` dependency injection is the chosen strategy (mirrors
  the 0021 approach for per-user feeds).
- `status` field and its mapping are already in place from slice 0021; this slice adds
  only the filter and the router change.
- 0010 conftest update (set `status='approved'`) is the mandatory first step before
  any production code change.
