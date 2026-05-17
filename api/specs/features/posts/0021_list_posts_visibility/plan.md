# 0021 · list_posts_visibility — Implementation plan

## 1. Header

- **Feature:** posts
- **Slice:** 0021_list_posts_visibility
- **PRD:** ./prd.md
- **Reference slice:** `../0009_list_posts/plan.md` — this slice modifies the files
  introduced by 0009; the 0009 plan is the primary structural reference.
- **HTTP path:** `GET /api/v1/{username}/posts` (same endpoint, changed behaviour)
- **STABLE files touched:** None.
  - `bootstrap/container.py` — not modified; existing `list_posts_adapter` and
    `list_posts_use_case` providers absorb `ListPostsQuery`'s new optional field
    transparently. No new providers are needed.
  - `adapters/db/models/post.py` — not modified; `Post.status` column already
    exists from slice 0013.

## 2. Context summary

`GET /api/v1/{username}/posts` currently returns every non-deleted post for a
user regardless of moderation status. This slice adds visibility filtering:
unauthenticated callers and authenticated callers who are not the post author
receive only posts with `status = 'approved'`; the post author receives all posts
regardless of status. The filtering decision is made entirely in the adapter based
on the `requester_username` field added to `ListPostsQuery`. The router resolves
the optional caller identity via the existing `get_optional_user` dependency and
injects a `view` parameter (`"author"` or `"public"`) that both drives the cache
key split and informs the query command. `status` is added to the shared `PostItem`
entity and to both slices' `PostItemSchema` so callers can see moderation state.
No new use-case, port, adapter class, DI provider, or migration is introduced —
all changes are modifications to existing files.

## 3. API contract

**Request body:** none (GET endpoint).

**Path parameters:**

| Param | Type | Notes |
|---|---|---|
| `username` | `str` | Author's username; non-existent returns empty list |

**Query parameters:**

| Param | Type | Default | Validation |
|---|---|---|---|
| `page` | `int` | `1` | `ge=1` |
| `items_per_page` | `int` | `10` | `ge=1`, `le=100` |

**Authentication:** Optional Bearer token (resolved by `get_optional_user`).

**Response body** (`ListPostsResponse`) — unchanged except for new `status` field on each item:

Each `PostItemSchema`:

| Field | Type | Source |
|---|---|---|
| `id` | `int` | `post.id` |
| `title` | `str` | `post.title` |
| `text` | `str` | `post.text` |
| `media_url` | `str \| None` | `post.media_url` |
| `created_at` | `datetime` | `post.created_at` |
| `created_by_user_id` | `int` | `post.created_by_user_id` |
| `username` | `str` | `user.username` (via JOIN) |
| `status` | `str` | `post.status` (**new**) |

**Status codes:** unchanged — `200 OK` for all visibility scenarios (including
empty result when there are no approved posts). No new `DomainError` is raised.

## 4. File structure

This slice modifies existing files only. No new files are created inside
`list_posts/`.

Files modified in `list_posts/`:

```
src/app/features/posts/list_posts/
├── domain/
│   └── commands.py          # add requester_username: str | None = None
├── data/
│   └── adapter.py           # conditional WHERE status = 'approved'; map status field
└── presentation/
    ├── schemas.py            # add status: str to PostItemSchema
    └── router.py            # add _get_view, get_optional_user; update cache key
```

Files modified in the shared `posts/_shared/` entity and in the sibling
`list_all_posts/` slice (required: adding `status` to the shared entity would
break `list_all_posts` adapter without this update):

```
src/app/features/posts/
├── _shared/
│   └── entities.py                          # add status: str to PostItem
└── list_all_posts/
    ├── data/
    │   └── adapter.py                       # add status=post.status to PostItem mapping
    └── presentation/
        └── schemas.py                       # add status: str to PostItemSchema
```

Pre-existing test file updated (pre-condition for implementation):

```
tests/features/posts/0009_list_posts/
└── list_posts_outside_in_test.py            # seed posts with status='approved'
```

## 5. Implementation steps

### Step 0 — Pre-condition: update 0009 outside-in test

**File:** `tests/features/posts/0009_list_posts/list_posts_outside_in_test.py`

The 0009 outside-in test seeds posts without setting `status`, so they default to
`pending_review`. After this slice, an unauthenticated caller receives only
`approved` posts — the test would see zero items and fail.

Fix: update the post-seeding step in the 0009 test to set `status='approved'` on
each post (directly via the test session factory or the fixture that creates them).
The test must remain green throughout the rest of this slice's implementation.

Audit the 0009 adapter and router tests for the same fixture dependency and update
any that also seed posts without an explicit `status`.

This step must be completed and verified **before any production code is changed**.

### Step 1 — Shared entity: add `status` to `PostItem`

**File:** `src/app/features/posts/_shared/entities.py`

Add `status: str` as a required field to `PostItem`. No default — the field is
always populated from the ORM row (`Post.status` has a DB-level default of
`'pending_review'`).

`PostPage` is unchanged.

### Step 2 — Update `list_all_posts` adapter: map `status`

**File:** `src/app/features/posts/list_all_posts/data/adapter.py`

In the `PostItem` construction inside `list()`, add `status=post.status` to each
mapped item. This is a one-line change per item in the list comprehension. No
other logic changes — `list_all_posts` retains no visibility filter in this slice
(that is slice 0022's scope).

No `try/except` is added — per `agent_docs/error_handling.md`, read-only queries
have no business-meaningful exception path.

### Step 3 — Update `list_all_posts` schemas: add `status` to `PostItemSchema`

**File:** `src/app/features/posts/list_all_posts/presentation/schemas.py`

Add `status: str` to `PostItemSchema` in the `list_all_posts` slice. This keeps
the `list_all_posts` response schema consistent with the shared entity and
prepares for slice 0022.

### Step 4 — Domain: extend `ListPostsQuery`

**File:** `src/app/features/posts/list_posts/domain/commands.py`

Add `requester_username: str | None = None` to `ListPostsQuery`. A `None` value
means the caller is unauthenticated. Any value that differs from `username` means
a different authenticated caller. A value equal to `username` means the post
author. The default of `None` preserves backward compatibility; existing callers
of the use-case that do not set this field get the public (filtered) view.

### Step 5 — Data: add visibility filter to `ListPostsAdapter`

**File:** `src/app/features/posts/list_posts/data/adapter.py`

Modify `async def list(self, query: ListPostsQuery) -> PostPage`:

1. Compute `is_author = query.requester_username == query.username` at the top of
   the method.
2. In the **count query**, add `.where(Post.status == "approved")` conditionally
   when `not is_author`.
3. In the **rows query**, add `.where(Post.status == "approved")` conditionally
   when `not is_author`.
4. In the `PostItem` construction inside the list comprehension, add
   `status=post.status`.

No `try/except` — this remains a read-only query with no business-meaningful
exception path (per `agent_docs/error_handling.md`).

Concrete conditional pattern for both queries:

```python
is_author = query.requester_username == query.username
# ... build base stmt ...
if not is_author:
    stmt = stmt.where(Post.status == "approved")
```

Both count and rows statements receive the same conditional clause so
`total_count` reflects only the visible posts.

### Step 6 — Presentation: add `status` to `PostItemSchema`

**File:** `src/app/features/posts/list_posts/presentation/schemas.py`

Add `status: str` to `PostItemSchema`. No default — the field is always present
because `PostItem.status` is always populated from the DB.

`ListPostsResponse` is unchanged.

### Step 7 — Presentation: update router

**File:** `src/app/features/posts/list_posts/presentation/router.py`

Three changes:

**a) New import:**

```python
from ....users.dependencies import get_optional_user
```

**b) New `_get_view` helper** (defined in the module, below the existing
`_get_list_posts_use_case` helper):

```python
async def _get_view(
    username: str,
    optional_user: Annotated[dict | None, Depends(get_optional_user)],
) -> str:
    if optional_user and optional_user.get("username") == username:
        return "author"
    return "public"
```

`_get_view` returns `"author"` when the resolved optional user is the post owner
and `"public"` for all other callers (unauthenticated or a different user).
FastAPI caches `get_optional_user` within the request, so the dependency is not
called twice even though `_get_view` and the endpoint both depend on it indirectly.

**c) Update the endpoint**:

- Update the `@cache` key_prefix to:
  `"{username}_posts:{view}:page_{page}:items_per_page:{items_per_page}"`
- Add `view: Annotated[str, Depends(_get_view)]` as an endpoint parameter (so the
  cache decorator can interpolate it from kwargs).
- Inside the endpoint body, derive `requester_username`:
  ```python
  requester_username = username if view == "author" else None
  ```
- Build `ListPostsQuery` with the new field:
  ```python
  query = ListPostsQuery(
      username=username,
      page=page,
      items_per_page=items_per_page,
      requester_username=requester_username,
  )
  ```

The existing `pattern_to_invalidate_extra` patterns in write/patch/delete endpoints
use `{username}_posts:*`, which still covers both `{username}_posts:author:*` and
`{username}_posts:public:*` — no changes needed in those endpoints.

### Step 8 — Verify

```
ruff format src/app
ruff check src/app
mypy src/app
pytest
```

Outside-in test for this slice:

```
pytest tests/features/posts/0021_list_posts_visibility/list_posts_visibility_outside_in_test.py -v
```

0009 outside-in test (must remain green):

```
pytest tests/features/posts/0009_list_posts/list_posts_outside_in_test.py -v
```

The slice is not done until all tests pass, including the smoke test at
`tests/smoke/test_app_starts.py`.

## 6. Tests planned

### Use-case unit test

**Opt-out.** `ListPostsUseCase` remains a thin pass-through with no branches and
no `DomainError` paths. A unit test adds no value per PRD § Testing Decisions.

### Adapter unit test

**File:** `tests/features/posts/0021_list_posts_visibility/data/test_adapter.py`

Using a real async session against the test Postgres database (no mocks), seed
users and posts with explicit `status` values, then call `ListPostsAdapter.list()`
directly. Assert:

- `requester_username == username` (author): all posts returned regardless of
  status.
- `requester_username != username` (different user): only `approved` posts
  returned.
- `requester_username is None` (unauthenticated): only `approved` posts returned.
- The `status` field is correctly populated on every returned `PostItem`.
- Empty `PostPage` (zero approved posts, non-author caller): `total_count == 0`,
  `items == []`.

No exception-path assertions — the adapter has no `try/except`.

Prior art: `tests/features/posts/0009_list_posts/data/test_adapter.py`.

### Endpoint integration test

**File:** `tests/features/posts/0021_list_posts_visibility/presentation/test_router.py`

`httpx.AsyncClient` against the running app with test Postgres. Seed one approved
post and one pending post for the same author. Assert:

- Unauthenticated `GET /{username}/posts` → HTTP 200, one item, `status == 'approved'`.
- Authenticated as a different user → HTTP 200, one item, `status == 'approved'`.
- Authenticated as the author → HTTP 200, two items (both statuses present).
- Zero approved posts → HTTP 200, `items: []`, `total_count: 0`.
- `status` field present in every response item.

Prior art: `tests/features/posts/0009_list_posts/presentation/test_router.py`.

### Outside-in test

**File:** `tests/features/posts/0021_list_posts_visibility/list_posts_visibility_outside_in_test.py`

Full HTTP stack with real adapter, test Postgres, no mocks. Scenario per PRD §
Outside-in test:

1. Register and authenticate `alice`.
2. `alice` creates three posts (all default to `pending_review`).
3. Directly update one post to `status = 'approved'` via the test session factory.
4. Unauthenticated `GET /users/alice/posts` → HTTP 200, exactly one item,
   `status == 'approved'`.
5. Authenticated `GET /users/alice/posts` as `alice` → HTTP 200, three items.
6. Register `bob`. Authenticated `GET /users/alice/posts` as `bob` → HTTP 200,
   one item, `status == 'approved'`.

This is the acceptance gate. The slice is not done until this test is green and
the 0009 outside-in test also remains green.

**Opt-outs:** none beyond the use-case unit test above.

## 7. Out of scope for this slice

- Visibility filtering on `GET /posts` (global feed) — that is slice 0022
  (`list_all_posts_visibility`).
- Moderator or superuser bypass of the `approved`-only filter on per-user profile
  feeds — moderators use `GET /posts/pending`.
- Cache invalidation when a post's status changes — existing `{username}_posts:*`
  wildcard patterns in write/patch/delete endpoints cover both the `author` and
  `public` cache keys; no additional invalidation logic is needed.
- Rate limiting on this endpoint.
- Adding `post_uuid` or `PostModerationLog` entries to the profile-feed response.

## 8. Open questions

None. All decisions resolved in the PRD:

- Author-vs-non-author is the only visibility axis (moderators use the pending queue).
- Cache key split via `_get_view` dependency injection is the chosen strategy for
  making `view` available to the `@cache` decorator.
- `list_all_posts` adapter and schemas are updated in this slice (not deferred to
  0022) because adding `status` to the shared `PostItem` entity would otherwise
  break the existing `list_all_posts` implementation at test time.
