# 0054 · migrate_get_post_route_username_to_user_id — Implementation plan

## 1. Header

- **Feature:** posts
- **Slice:** 0054_migrate_get_post_route_username_to_user_id
- **PRD:** ./prd.md
- **Reference slices:**
  - `../0026_get_post/` — the slice this migration modifies in place; structural baseline.
  - `../0042_migrate_list_posts_route_username_to_user_id/plan.md` — same operation shape (`{username}` → `{user_id}` route migration); used for the migration pattern (command field rename, adapter filter swap, router path-param retype, cache-key repoint). Mirrored exactly, with one deliberate difference: `get_post` adds **no** user-existence lookup.
- **HTTP path:** `GET /api/v1/{user_id}/post/{id}` (was `GET /api/v1/{username}/post/{id}`)
- **STABLE files touched:** none. The `get_post` router is already registered in `bootstrap/router.py`; the `get_post_adapter` / `get_post_use_case` providers already exist in `bootstrap/container.py` and their import paths are unchanged. No new wiring.

## 2. Context summary

Slice 0054 migrates the `get_post` endpoint — a public single-post read — from keying the author on `{username}` to keying on `{user_id}` (the integer autoincrement PK of `User`). `GetPostQuery` fields `username: str` and `requester_username: str | None` become `user_id: int` and `requester_user_id: int | None`. The use-case's non-approved-post visibility branch changes its author comparison from `requester_username == username` to `requester_user_id == user_id`; the anonymous (`None` requester) case and the privileged-viewer bypass (superuser/moderator) keep their current semantics. The adapter filters directly on `Post.created_by_user_id == query.user_id` instead of joining `User` on a mutable `username` string; the JOIN to `User` is retained only to populate the display `username` on the returned `PostItem`. The router reads `user_id: int` from the path, derives the requester's identity from `optional_user["id"]`, and uses `{user_id}_post_cache` as the cache key prefix. The response body shape (`GetPostResponse`) is unchanged. No explicit user-existence lookup is added — a missing or mismatched author still yields a generic 404. The old `/{username}/post/{id}` route is removed with no compatibility shim. No ORM model change; no Alembic migration.

## 3. API contract

**Path params:**

| Param | Type | Notes |
|---|---|---|
| `user_id` | `int` | Integer primary key of the post author (was `username: str`) |
| `id` | `int` | Post primary key — unchanged |

**Query params:** none.

**Authentication:** optional (`get_optional_user`). For an approved post, any caller (including unauthenticated) receives it. For a non-approved post, only the author (`optional_user["id"] == user_id`) or a privileged viewer (superuser/moderator) receives it; everyone else gets 404.

**Response body** (`GetPostResponse`) — unchanged shape:

| Field | Type |
|---|---|
| `id` | `int` |
| `title` | `str` |
| `text` | `str` |
| `media_url` | `str \| None` |
| `created_at` | `datetime` |
| `created_by_user_id` | `int` |
| `username` | `str` (populated from the `User` JOIN) |
| `status` | `str` |
| `post_uuid` | `uuid.UUID` |

**Status codes:**

- `200 OK` — post exists, belongs to `user_id`, and is visible to the requester.
- `404 Not Found` (`NotFoundDomainError("Post not found")`) — post does not exist, does not belong to `user_id`, or is non-approved and the requester is neither author nor privileged; also when `user_id` matches no user (no distinct "user not found" — avoids leaking which IDs exist).
- `422 Unprocessable Entity` — `user_id` (or `id`) path segment is not a valid integer. This also covers the old `/{username}/post/{id}` URL called with a non-numeric username string.

No 403/409 domain-error codes apply: the only domain error this slice raises is `NotFoundDomainError`, already part of the STABLE error hierarchy — no new subclass is introduced.

## 4. File structure

No new files. All changes are in-place modifications of the existing `0026_get_post` slice files (located at `src/app/features/posts/get_post/`).

Files modified:

```
src/app/features/posts/get_post/domain/commands.py
    username: str                  → user_id: int
    requester_username: str | None → requester_user_id: int | None

src/app/features/posts/get_post/domain/use_case.py
    visibility branch author check:
        query.requester_username == query.username
        → query.requester_user_id == query.user_id

src/app/features/posts/get_post/data/adapter.py
    WHERE filter:  User.username == query.username
                   → Post.created_by_user_id == query.user_id
    (JOIN to User retained in the rows query to SELECT User.username;
     Post.id pin, soft-delete guards, and one_or_none() → None behaviour unchanged)

src/app/features/posts/get_post/presentation/router.py
    path:             "/{username}/post/{id}" → "/{user_id}/post/{id}"
    path param:       username: str           → user_id: int
    requester id:     optional_user["username"] → optional_user["id"]
    cache key_prefix: "{username}_post_cache"   → "{user_id}_post_cache"
    query build:      requester_username/username → requester_user_id/user_id
```

Files **not** changed:

```
src/app/features/posts/get_post/domain/ports/get_post_port.py  # signature is get(query: GetPostQuery); unchanged
src/app/features/posts/get_post/presentation/schemas.py        # response shape unchanged
src/app/features/posts/_shared/entities.py                     # PostItem unchanged
src/app/features/posts/_shared/user_lookup_port.py
src/app/features/posts/_shared/user_lookup_adapter.py
src/app/features/posts/_shared/policies.py                     # check_post_owner — get_post does not use it
bootstrap/container.py, bootstrap/router.py                    # no wiring change
```

## 5. Implementation steps

### Step 1 — Domain: rename `GetPostQuery` fields

**File:** `src/app/features/posts/get_post/domain/commands.py`

Replace:
- `username: str` → `user_id: int`
- `requester_username: str | None = None` → `requester_user_id: int | None = None`

`post_id: int` and `requester_is_privileged: bool = False` are unchanged. Final shape:

```python
class GetPostQuery(BaseModel):
    user_id: int
    post_id: int
    requester_user_id: int | None = None
    requester_is_privileged: bool = False
```

### Step 2 — Domain: update `GetPostUseCase` visibility branch

**File:** `src/app/features/posts/get_post/domain/use_case.py`

Only the author comparison inside the non-approved branch changes:

- `if query.requester_username == query.username:` → `if query.requester_user_id == query.user_id:`

Everything else is unchanged: the `post is None` → `NotFoundDomainError("Post not found")` guard, the privileged-viewer bypass (`if query.requester_is_privileged: return post`), the final `raise NotFoundDomainError("Post not found")` for a non-author non-privileged viewer, and returning an approved post unconditionally. Note `requester_user_id` is `int | None`; for an anonymous requester it is `None`, and `None == <int>` is `False`, so anonymous viewers correctly fail the author check and fall through to the 404. No user-existence check is added.

### Step 3 — Data: update `GetPostAdapter.get` filter

**File:** `src/app/features/posts/get_post/data/adapter.py`

1. **Filter:** replace `.where(User.username == query.username)` with `.where(Post.created_by_user_id == query.user_id)`.
2. **JOIN retained:** keep `.join(User, Post.created_by_user_id == User.id)` so the statement can still `select(Post, User.username)` and populate the display `username`.
3. **Unchanged:** the `Post.id == query.post_id` pin, the `User.is_deleted == False` and `Post.is_deleted == False` soft-delete guards, the `one_or_none()` → `None` behaviour (which the use-case maps to 404), and the `PostItem` construction.

### Step 4 — Presentation: update router

**File:** `src/app/features/posts/get_post/presentation/router.py`

1. **Route path:** `@router.get("/{user_id}/post/{id}", response_model=GetPostResponse, status_code=200)` (was `/{username}/post/{id}`).
2. **Cache decorator:** `@cache(key_prefix="{user_id}_post_cache", resource_id_name="id")`. `resource_id_name` continues to reference the post `id`; no extra invalidation pattern (read endpoint).
3. **Endpoint signature:** path param `user_id: int` replaces `username: str`. `id: int`, `request: Request`, `optional_user`, and `use_case` parameters are unchanged.
4. **Requester resolution:** `requester_is_privileged` derivation (superuser or moderator) is unchanged. Replace `requester_username = optional_user["username"] if optional_user else None` with `requester_user_id = optional_user["id"] if optional_user else None`.
5. **Query construction:**
   ```python
   query = GetPostQuery(
       user_id=user_id,
       post_id=id,
       requester_user_id=requester_user_id,
       requester_is_privileged=requester_is_privileged,
   )
   ```
6. Response assembly (`GetPostResponse.model_validate(post)`) is unchanged.

### Step 5 — Update slice 0026 outside-in / integration test URLs (acceptance-gate dependency)

Per the PRD § Further Notes, the existing `tests/features/posts/0026_get_post/` tests hit `/api/v1/{username}/post/{id}`, which no longer exists after this slice. Update their endpoint URLs (and any author-identity fixtures keyed on username) to the integer-keyed route `/api/v1/{user_id}/post/{id}`, or note in tests.md that they are superseded by the 0054 tests. Before and after, baseline the full suite and prove zero net-new failures (user memory `project_route_migration_downstream_tests`).

### Step 6 — Verify

```
ruff format src/app tests
ruff check src/app tests
mypy src/app
pytest
```

Plus the architecture gate (import-linter) and the new outside-in test:

```
pytest tests/features/posts/0054_migrate_get_post_route_username_to_user_id/migrate_get_post_route_username_to_user_id_outside_in_test.py -v
```

The slice is not done until all checks pass, including `tests/smoke/test_app_starts.py`.

## 6. Tests planned

Four levels, per `agent_docs/testing.md`. Existing 0026 tests are migrated/duplicated into the 0054 test folder (or updated in place) to reflect the integer-keyed query and route.

- **Use-case unit test** — `tests/features/posts/0054_migrate_get_post_route_username_to_user_id/domain/test_use_case.py`.
  Mock `GetPostPort`. Cases (per PRD § Testing Decisions):
  - Approved post → returned unchanged regardless of requester.
  - Non-approved, author view (`requester_user_id == user_id`) → returned.
  - Non-approved, privileged view (`requester_user_id != user_id`, `requester_is_privileged=True`) → returned.
  - Non-approved, non-author non-privileged → `NotFoundDomainError("Post not found")`.
  - Post missing (port returns `None`) → `NotFoundDomainError`.

- **Adapter unit test** — `tests/features/posts/0054_migrate_get_post_route_username_to_user_id/data/test_adapter.py`.
  Real async session against the test Postgres. Cases:
  - Found by id: create a user and an approved post; call with the matching `user_id` and `post_id` → `PostItem` returned with `username` populated from the JOIN.
  - Wrong author: call with a different `user_id` → `None`.
  - Missing post: call with a non-existent `post_id` → `None`.
  - Soft-deleted post → `None`.
  - Soft-deleted author → `None`.

- **Endpoint integration test** — `tests/features/posts/0054_migrate_get_post_route_username_to_user_id/presentation/test_router.py`.
  `httpx.AsyncClient` against test Postgres. Cases:
  - 200 approved, unauthenticated → post returned with expected fields including `username`.
  - 200 non-approved, author (`get_optional_user` overridden to return `{"id": user_id, ...}`) → returned.
  - 200 non-approved, privileged (superuser/moderator) → returned.
  - 404 non-approved, non-author non-privileged → HTTP 404.
  - 404 unknown post (non-existent `post_id`) → HTTP 404.
  - 422 non-integer `user_id`: `GET /api/v1/not-an-integer/post/1`.
  - Old route gone: call with a string username → 422/404 (the int-typed route does not match a string).

- **Outside-in test** — `tests/features/posts/0054_migrate_get_post_route_username_to_user_id/migrate_get_post_route_username_to_user_id_outside_in_test.py`.
  Full HTTP stack, real adapter, test Postgres. Acceptance gate. Scenarios per tests.md (create user + approved post → 200 by integer ID with `username`; create non-approved post + author auth → 200; old string-username route → 422).

**Opt-outs:** none — all four levels apply (per PRD § Testing Decisions).

## 7. Out of scope for this slice

- `create_post`, `update_post`, `erase_post`, `erase_db_post` — separate migration slices in the same initiative; not changed here.
- `list_posts` (`GET /{user_id}/posts`) — already migrated in slice 0042.
- `posts/_shared` user-lookup port/adapter and the `check_post_owner` policy — not used by `get_post`; must not be touched.
- Adding a distinct "user not found" (404) — `get_post` intentionally keeps its no-user-lookup behaviour to avoid leaking which user IDs exist.
- Removing `username` from `GetPostResponse` — retained for backwards compatibility.
- Changing the post `id` to a UUID — frozen; the integer `id` is retained.
- Explicit cache flush of stale `{username}_post_cache:...` keys — they expire via the existing TTL.
- The Flutter client (separate working dir) — its calls to the old route break; handled in the Flutter spec slices.

## 8. Open questions

None. The migration mirrors slice 0042's already-implemented mechanism; `get_optional_user` already exposes the `id` key (verified in `src/app/shared_dependencies.py`), so no auth-layer change is required, and no new `DomainError` subclass is introduced.
