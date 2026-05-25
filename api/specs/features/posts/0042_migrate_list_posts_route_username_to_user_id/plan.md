# 0042 · migrate_list_posts_route_username_to_user_id — Implementation plan

## 1. Header

- **Feature:** posts
- **Slice:** 0042_migrate_list_posts_route_username_to_user_id
- **PRD:** ./prd.md
- **Reference slices:**
  - `../0009_list_posts/` — the slice this migration modifies in place; structural baseline.
  - `../../users/0043_update_user_route_to_user_id/plan.md` — same operation shape (`{username}` → `{user_id}` route migration); used for the migration pattern (command field rename, adapter filter swap, router path-param retype).
- **HTTP path:** `GET /api/v1/{user_id}/posts` (was `GET /api/v1/{username}/posts`)
- **STABLE files touched:** none. The `list_posts` router is already registered in `bootstrap/router.py`; the `list_posts_adapter` / `list_posts_use_case` providers already exist in `bootstrap/container.py` and their import paths are unchanged. No new wiring.

## 2. Context summary

Slice 0042 migrates the only Posts API route that still keys on `{username}` to key on `{user_id}` (the integer autoincrement PK of `User`). The target author is identified by integer ID. `ListPostsQuery` fields `username: str` and `requester_username: str | None` become `user_id: int` and `requester_user_id: int | None`. The adapter filters posts directly on `Post.created_by_user_id == query.user_id` instead of joining `User` on a mutable `username` string; the JOIN to `User` is retained only to populate the `username` field on each `PostItem` in the response body. The router reads `user_id: int` from the path, derives author identity from `optional_user["id"]`, and uses `{user_id}_posts:...` as the cache key prefix. The response body shape (`ListPostsResponse` / `PostItemSchema`) is unchanged. The old `/{username}/posts` route is removed with no compatibility shim. No ORM model change; no Alembic migration.

## 3. API contract

**Path params:**

| Param | Type | Notes |
|---|---|---|
| `user_id` | `int` | Integer primary key of the post author (was `username: str`) |

**Query params** — unchanged:

| Param | Type | Validation |
|---|---|---|
| `page` | `int` | `Query(default=1, ge=1)` |
| `items_per_page` | `int` | `Query(default=10, ge=1, le=100)` |

**Authentication:** optional. An authenticated owner (`optional_user["id"] == user_id`) gets the *author* view (all non-deleted posts regardless of status); everyone else gets the *public* view (`status == "approved"` only).

**Response body** (`ListPostsResponse`) — unchanged shape:

| Field | Type |
|---|---|
| `items` | `list[PostItemSchema]` |
| `total_count` | `int` |
| `page` | `int` |
| `items_per_page` | `int` |

`PostItemSchema` — unchanged: `id: int`, `title: str`, `text: str`, `media_url: str | None`, `created_at: datetime`, `created_by_user_id: int`, `username: str`, `status: str`, `post_uuid: uuid.UUID`.

**Status codes:**

- `200 OK` — always returned for a valid integer `user_id`, whether or not the user exists and whether or not they have posts (empty `items` list when none are visible).
- `422 Unprocessable Entity` — `user_id` path segment is not a valid integer (this also covers the old `/{username}/posts` URL called with a non-numeric string).

No domain-error status codes (404/403/409) apply: the use-case does not check user existence and performs no authorization beyond the view split.

## 4. File structure

No new files. All changes are in-place modifications of the existing `0009_list_posts` slice files.

Files modified:

```
src/app/features/posts/list_posts/domain/commands.py
    username: str               → user_id: int
    requester_username: str|None → requester_user_id: int | None

src/app/features/posts/list_posts/data/adapter.py
    is_author check:  query.requester_username == query.username
                      → query.requester_user_id == query.user_id
    WHERE filter:     User.username == query.username
                      → Post.created_by_user_id == query.user_id
    (JOIN to User retained in the rows query to SELECT User.username)

src/app/features/posts/list_posts/presentation/router.py
    path:             "/{username}/posts" → "/{user_id}/posts"
    path param:       username: str       → user_id: int
    _get_view:        optional_user["username"] == username
                      → optional_user["id"] == user_id
    cache key_prefix: "{username}_posts:..." → "{user_id}_posts:..."
    resource_id_name: "username"            → "user_id"
    query build:      requester_username/username → requester_user_id/user_id
```

Files **not** changed:

```
src/app/features/posts/list_posts/domain/use_case.py          # pure pass-through; no username reference
src/app/features/posts/list_posts/domain/ports/list_posts_port.py  # signature is list(query: ListPostsQuery); unchanged
src/app/features/posts/list_posts/presentation/schemas.py     # response shape unchanged
src/app/features/posts/_shared/entities.py                    # PostItem / PostPage unchanged
bootstrap/container.py, bootstrap/router.py                   # no wiring change
```

## 5. Implementation steps

### Step 1 — Domain: rename `ListPostsQuery` fields

**File:** `src/app/features/posts/list_posts/domain/commands.py`

Replace:
- `username: str` → `user_id: int`
- `requester_username: str | None = None` → `requester_user_id: int | None = None`

`page: int = 1` and `items_per_page: int = 10` are unchanged. Final shape:

```python
class ListPostsQuery(BaseModel):
    user_id: int
    page: int = 1
    items_per_page: int = 10
    requester_user_id: int | None = None
```

### Step 2 — Data: update `ListPostsAdapter.list`

**File:** `src/app/features/posts/list_posts/data/adapter.py`

1. **`is_author`:** `is_author = query.requester_user_id == query.user_id`. Both sides are `int | None` / `int`; `None == <int>` is `False`, so an unauthenticated or non-owner request correctly resolves to the public view.
2. **Filter (count and rows):** replace `.where(User.username == query.username)` with `.where(Post.created_by_user_id == query.user_id)`.
3. **JOIN:** keep the JOIN `Post → User` on `Post.created_by_user_id == User.id` in **both** the count and the rows statements, and keep `.where(User.is_deleted == False)` in both. The rows query needs the JOIN to `SELECT User.username` for each `PostItem`; the count query keeps it so the `User.is_deleted` guard is applied identically (see Open questions for why the count JOIN is retained rather than dropped). `.where(Post.is_deleted == False)` and the `Post.status == "approved"` branch for non-authors are unchanged.
4. The `PostItem` construction loop and `PostPage` assembly are unchanged.

### Step 3 — Presentation: update router

**File:** `src/app/features/posts/list_posts/presentation/router.py`

1. **`_get_view` helper:** signature `username: str` → `user_id: int`; body `optional_user.get("username") == username` → `optional_user.get("id") == user_id`.
2. **Route path:** `@router.get("/{user_id}/posts", ...)` (was `/{username}/posts`).
3. **Cache decorator:**
   - `key_prefix="{user_id}_posts:{view}:page_{page}:items_per_page:{items_per_page}"`.
   - `resource_id_name="user_id"`.
   - `expiration=60` unchanged.
4. **Endpoint signature:** path param `user_id: int` replaces `username: str`. `request: Request`, `use_case`, `view`, `page`, `items_per_page` parameters are unchanged.
5. **Query construction:**
   ```python
   requester_user_id = user_id if view == "author" else None
   query = ListPostsQuery(
       user_id=user_id,
       page=page,
       items_per_page=items_per_page,
       requester_user_id=requester_user_id,
   )
   ```
6. Response assembly (`ListPostsResponse(items=[PostItemSchema.model_validate(p) ...], ...)`) is unchanged.

### Step 4 — Update slice 0009 outside-in test URL (acceptance-gate dependency)

Per the PRD § Further Notes, the existing `tests/features/posts/0009_list_posts/list_posts_outside_in_test.py` hits `/api/v1/{username}/posts`, which no longer exists after this slice. Update its `_ENDPOINT` and seeding assertions to the integer-keyed route (or note in tests.md that it is superseded by the 0042 outside-in test). This is the one cross-slice test edit required to keep the suite green.

### Step 5 — Verify

```
ruff format src/app tests
ruff check src/app tests
mypy src/app
pytest
```

Plus the architecture gate (import-linter) and the new outside-in test:

```
pytest tests/features/posts/0042_migrate_list_posts_route_username_to_user_id/migrate_list_posts_route_username_to_user_id_outside_in_test.py -v
```

The slice is not done until all checks pass, including `tests/smoke/test_app_starts.py`.

## 6. Tests planned

Four levels, per `agent_docs/testing.md`. Existing 0009 tests are migrated/duplicated into the 0042 test folder (or updated in place) to reflect the integer-keyed query and route.

- **Use-case unit test** — `tests/features/posts/0042_migrate_list_posts_route_username_to_user_id/domain/test_use_case.py`.
  Mock `ListPostsPort`. Cases:
  - Author view: command carries `requester_user_id == user_id`; assert the port receives a `ListPostsQuery` with `requester_user_id` equal to `user_id`.
  - Public view: command carries `requester_user_id is None`; assert the port receives a query with `requester_user_id is None`.
  - Happy path: port returns a `PostPage`; use-case returns it unchanged.

- **Adapter unit test** — `tests/features/posts/0042_migrate_list_posts_route_username_to_user_id/data/test_adapter.py`.
  Real async session against the test Postgres. Cases:
  - Public view (non-author `requester_user_id`): a user with one `approved` and one `pending` post → only the approved post returned, `total_count == 1`.
  - Author view (`requester_user_id == user_id`): both posts returned, `total_count == 2`.
  - Empty result: a `user_id` that owns no posts → `items == []`, `total_count == 0`.
  - Non-existent `user_id`: → empty `PostPage`, no exception.
  - `username` on each returned `PostItem` is populated from the JOIN.

- **Endpoint integration test** — `tests/features/posts/0042_migrate_list_posts_route_username_to_user_id/presentation/test_router.py`.
  `httpx.AsyncClient` against test Postgres. Cases:
  - 200 public view (unauthenticated): only approved posts visible.
  - 200 author view (`get_optional_user` overridden to return `{"id": user_id, ...}`): approved + non-approved visible.
  - 200 non-author authenticated view: only approved posts.
  - 200 empty: valid `user_id` with no posts → `items: []`, `total_count: 0`.
  - 422: `GET /api/v1/not-an-integer/posts`.
  - Pagination: `page`/`items_per_page` honoured.

- **Outside-in test** — `tests/features/posts/0042_migrate_list_posts_route_username_to_user_id/migrate_list_posts_route_username_to_user_id_outside_in_test.py`.
  Full HTTP stack, real adapter, test Postgres. Acceptance gate. Scenarios per tests.md (happy path by integer ID + old string route now 422).

**Opt-outs:** none — all four levels apply (per PRD § Testing Decisions).

## 7. Out of scope for this slice

- `create_post`, `get_post`, `update_post`, `erase_post`, `erase_db_post` — use other identifiers; not part of this migration.
- `UserLookupPort` / `UserLookupAdapter` in `posts/_shared/` — must not be touched.
- `list_all_posts` (`GET /posts/`) and `list_pending_posts` — no `{username}` path param; unaffected.
- Removing `username` from `PostItem` / `PostItemSchema` — retained for backwards compatibility.
- Returning 404 for an unknown `user_id` — behaviour stays "200 with empty list".
- Explicit cache flush of stale `{username}_posts:...` keys — they expire via the existing TTL.
- Admin UI (CRUDAdmin) changes.

## 8. Open questions

1. **Count-query JOIN.** The PRD § Implementation Decisions suggests the count statement can drop the `User` JOIN entirely (filtering only on `Post.created_by_user_id == query.user_id`). However, the current 0009 count statement also applies `User.is_deleted == False`, which the rows statement keeps via its retained JOIN. Dropping the JOIN from the count alone would make `total_count` include posts of a soft-deleted author while `items` excludes them — an internal inconsistency that is observable as `total_count > len(items)` for a soft-deleted author. This plan therefore **retains the JOIN + `User.is_deleted == False` guard in both statements** to preserve the exact 0009 behaviour. Confirm this is acceptable, or confirm the PRD intends the soft-deleted-author behaviour to change (in which case the rows query must also drop the guard, and requirements.md/tests.md must capture the new behaviour).
