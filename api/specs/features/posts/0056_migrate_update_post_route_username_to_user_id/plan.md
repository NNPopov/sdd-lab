# 0056 · migrate_update_post_route_username_to_user_id — Implementation plan

## 1. Header

- **Feature:** posts
- **Slice:** 0056_migrate_update_post_route_username_to_user_id
- **PRD:** ./prd.md
- **Reference slices:**
  - `../0028_update_post/` — the slice this migration modifies in place; structural baseline (command, use-case, adapter, router, schemas, cache decorator).
  - `../0055_migrate_create_post_route_username_to_user_id/plan.md` — same `{username}` → `{user_id}` write-path route migration. 0056 mirrors its command-rename, router path-param retype, requester-id-from-auth-dict, and `check_post_owner` delegation mechanics. **Key difference:** the shared `posts/_shared` helpers 0055 introduced (additive `get_active_user_by_id`, id-based `check_post_owner`) already exist; 0056 **uses** them and does **not** modify `_shared` or `erase_post`. The other difference is that `update_post` carries a `@cache` decorator whose keys must be repointed (`create_post` had none).
  - `../0054_migrate_get_post_route_username_to_user_id/plan.md` — the read-path sibling that repointed the `{user_id}_post_cache` read key this slice must invalidate; relevant to the cache-realignment bug fix.
  - `users/update_user/` — the canonical id-based **resolve-then-authorize** flow (`get_*_by_id` → 404, then ownership check → 403); `update_post`'s use-case mirrors it.
- **HTTP path:** `PATCH /api/v1/{user_id}/post/{id}` (was `PATCH /api/v1/{username}/post/{id}`)
- **STABLE files touched:** none. `update_post` is already registered in `bootstrap/router.py`; the `update_post_adapter`, `update_post_use_case`, and `user_lookup_adapter` providers already exist in `bootstrap/container.py` with unchanged import paths; the `.importlinter` ignore entry for the `update_post` router already exists. No new wiring. No new `DomainError` subclass (`NotFoundDomainError` and `ForbiddenDomainError` are already in the STABLE hierarchy).

## 2. Context summary

Slice 0056 migrates the `update_post` endpoint — an authenticated partial single-post write — from keying the author on `{username}` to keying on `{user_id}` (the integer autoincrement PK of `User`). `UpdatePostCommand` fields `target_username: str` and `requester_username: str` become `target_user_id: int` and `requester_user_id: int`; `post_id` and the optional `title`/`text`/`media_url` are unchanged. The use-case keeps its four-step shape but adopts the established id-based flow: resolve the author by id (`get_active_user_by_id`) → 404 "User not found" if absent; enforce ownership via the shared `check_post_owner` policy (already id-based) → bare 403 if the requester is not that author; fetch the post by id (`get_post_by_id`) → 404 "Post not found" if absent; then `update(command)`. The router reads `user_id: int` from the path and derives the requester from `current_user["id"]`. The `@cache` decorator's keys are repointed from `{username}_…` to `{user_id}_…`, which **realigns** `update_post`'s invalidation with the keys `list_posts` (0042, `{user_id}_posts:*`) and `get_post` (0054, `{user_id}_post_cache`) already use — fixing the latent partial-migration staleness bug as a direct consequence. The request body (`UpdatePostRequest`) and response (`UpdatePostResponse` — a bare `{"message": "Post updated"}`) are unchanged. The data adapter (`UpdatePostAdapter`) is unchanged — `get_post_by_id(post_id)` and `update(command)` never referenced the renamed username fields. Unlike 0055, the shared `_shared` modules are **not** modified (already evolved by 0055), and `erase_post` is **not** touched (already adapted by 0055). The old `/{username}/post/{id}` route is removed with no compatibility shim. No ORM model change; no Alembic migration.

## 3. API contract

**Path params:**

| Param | Type | Notes |
|---|---|---|
| `user_id` | `int` | Integer primary key of the post author (was `username: str`) |
| `id` | `int` | Post id (unchanged) |

**Query params:** none.

**Request body** (`UpdatePostRequest`) — **unchanged**, `extra="forbid"` retained. All fields optional (partial update):

| Field | Type | Validation |
|---|---|---|
| `title` | `str \| None` | `min_length=2, max_length=30`, default `None` |
| `text` | `str \| None` | `min_length=1, max_length=63206`, default `None` |
| `media_url` | `str \| None` | URL pattern `^(https?\|ftp)://[^\s/$.?#].[^\s]*$`, default `None` |

**Authentication:** required (`get_current_user`). The requester must equal the target author (`requester_user_id == target_user_id`).

**Response body** (`UpdatePostResponse`, HTTP 200) — **unchanged**:

| Field | Type |
|---|---|
| `message` | `str` (`"Post updated"`) |

**Status codes:**

| Status | Condition | Source |
|---|---|---|
| `200 OK` | Post updated for the authenticated owner | success |
| `401 Unauthorized` | No / invalid credentials | `get_current_user` (auth layer) |
| `403 Forbidden` | Authenticated requester is not the target user | `check_post_owner` → `ForbiddenDomainError()` |
| `404 Not Found` | `user_id` not found / soft-deleted, **or** post not found / soft-deleted | `NotFoundDomainError("User not found")` / `NotFoundDomainError("Post not found")` |
| `422 Unprocessable Entity` | Non-integer `user_id` path segment (also covers the old `/{username}/post/{id}` URL called with a non-numeric username); invalid request body | FastAPI path/body validation |

Ordering is **404(user) → 403(owner) → 404(post)**, preserved exactly from slice 0028: the author is resolved first; ownership is only checked once the author exists; the post is fetched only after ownership passes. No new `DomainError` subclass is introduced.

**Observable behaviour change:** the previous `update_post`-specific 403 message ("You can only update your own posts") is removed; ownership now delegates to the shared `check_post_owner`, which raises a bare `ForbiddenDomainError()` (no message), unifying 403 behaviour across `create_post`, `update_post`, and `erase_post`.

## 4. File structure

No new files. All changes are in-place modifications of three existing `0028_update_post` slice files. The `_shared` modules and `erase_post` are **not** touched (already migrated by 0055).

Files **modified**:

```
src/app/features/posts/update_post/domain/commands.py
    UpdatePostCommand:
        target_username: str    → target_user_id: int
        requester_username: str → requester_user_id: int
        (post_id, title, text, media_url unchanged)

src/app/features/posts/update_post/domain/use_case.py
    lookup:     get_active_user_by_username(target_username)
                → get_active_user_by_id(target_user_id)        → 404 "User not found" if None
    ownership:  inline `if command.requester_username != author.username: raise ForbiddenDomainError("You can only update your own posts")`
                → check_post_owner(command.requester_user_id, author.id)   (bare 403)
    post fetch: get_post_by_id(command.post_id)                → 404 "Post not found" if None   (UNCHANGED)
    update:     update(command)                                (UNCHANGED)
    imports:    drop ForbiddenDomainError from `.....domain.errors` import (keep NotFoundDomainError);
                add `from ..._shared.policies import check_post_owner`.

src/app/features/posts/update_post/presentation/router.py
    path:        "/{username}/post/{id}" → "/{user_id}/post/{id}"
    path param:  username: str           → user_id: int        (id: int unchanged)
    cache:       key_prefix "{username}_post_cache"            → "{user_id}_post_cache"
                 pattern_to_invalidate_extra ["{username}_posts:*"] → ["{user_id}_posts:*"]
                 resource_id_name="id"                          (UNCHANGED)
    command build: target_username=username                    → target_user_id=user_id
                   requester_username=current_user["username"] → requester_user_id=current_user["id"]
                   (post_id=id and **body.model_dump() unchanged)
```

Files **not** changed:

```
src/app/features/posts/update_post/data/adapter.py                 # get_post_by_id(post_id: int) + update(command) read only post_id + content fields
src/app/features/posts/update_post/domain/ports/update_post_port.py # get_post_by_id / update signatures unchanged
src/app/features/posts/update_post/presentation/schemas.py          # request/response shape unchanged
src/app/features/posts/_shared/policies.py                          # check_post_owner ALREADY id-based (0055)
src/app/features/posts/_shared/user_lookup_port.py                  # get_active_user_by_id ALREADY present (0055)
src/app/features/posts/_shared/user_lookup_adapter.py               # get_active_user_by_id ALREADY implemented (0055)
src/app/features/posts/_shared/entities.py                          # UserIdentity / PostItem unchanged
src/app/features/posts/erase_post/**                                # already adapted by 0055; not touched here
bootstrap/container.py, bootstrap/router.py, .importlinter          # no wiring change
```

## 5. Implementation steps

### Step 1 — Domain: retype `UpdatePostCommand`

**File:** `src/app/features/posts/update_post/domain/commands.py`

```python
class UpdatePostCommand(BaseModel):
    target_user_id: int
    requester_user_id: int
    post_id: int
    title: str | None = None
    text: str | None = None
    media_url: str | None = None
```

Only the two author identifiers change `str` → `int`; `post_id` and the optional content fields are unchanged.

### Step 2 — Domain: realign `UpdatePostUseCase` to resolve-then-authorize

**File:** `src/app/features/posts/update_post/domain/use_case.py`

1. Imports: change `from .....domain.errors import ForbiddenDomainError, NotFoundDomainError` to import `NotFoundDomainError` only; add `from ..._shared.policies import check_post_owner`. Keep the `UserLookupPort` and command/port imports.
2. Body — keep the four-step shape, swap the lookup method and the ownership mechanism:

```python
async def __call__(self, command: UpdatePostCommand) -> None:
    author = await self._user_lookup.get_active_user_by_id(command.target_user_id)
    if author is None:
        raise NotFoundDomainError("User not found")
    check_post_owner(command.requester_user_id, author.id)
    post = await self._port.get_post_by_id(command.post_id)
    if post is None:
        raise NotFoundDomainError("Post not found")
    await self._port.update(command)
```

The previous inline username comparison and its message are removed. The 404(user)→403(owner)→404(post) ordering is preserved. The constructor signature (`port`, `user_lookup`) is unchanged, so no DI change. **Pre-existing gap preserved:** `get_post_by_id(post_id)` still fetches the post by id without an owner filter — intentionally unchanged.

### Step 3 — Presentation: update `update_post` router (path, param, cache keys, command)

**File:** `src/app/features/posts/update_post/presentation/router.py`

1. Route path: `@router.patch("/{user_id}/post/{id}", response_model=UpdatePostResponse, status_code=200)` (was `/{username}/post/{id}`).
2. Cache decorator: repoint both keys to `user_id`, leaving `resource_id_name="id"`:

```python
@cache("{user_id}_post_cache", resource_id_name="id", pattern_to_invalidate_extra=["{user_id}_posts:*"])
```

3. Endpoint signature: path param `user_id: int` replaces `username: str`; `id: int`, `body`, `current_user`, and `use_case` are unchanged.
4. Command construction:

```python
command = UpdatePostCommand(
    target_user_id=user_id,
    requester_user_id=current_user["id"],
    post_id=id,
    **body.model_dump(),
)
```

`current_user["id"]` is available — `get_current_user` returns a dict that includes `id` (verified in `src/app/shared_dependencies.py` and relied on by slices 0054/0055). Response assembly (`UpdatePostResponse(message="Post updated")`) is unchanged.

### Step 4 — Update slice 0028 integration / outside-in test URLs (acceptance-gate dependency)

Per the PRD § Further Notes, the existing `tests/features/posts/0028_update_post/` tests hit `/api/v1/{username}/post/{id}` and construct `UpdatePostCommand` with username fields; both break after this slice. Update their endpoint URLs to the integer-keyed route `/api/v1/{user_id}/post/{id}` and their command/fixtures to the id fields, or note in tests.md that they are superseded by the 0056 tests. Before and after, baseline the full suite and prove zero net-new failures (user memory `project_route_migration_downstream_tests`). Grep the repo for other callers of `/post/{id}` PATCH and `target_username`/`requester_username` on `UpdatePostCommand` to catch any downstream slice sharing this source.

### Step 5 — Verify

```
ruff format src/app tests
ruff check src/app tests
mypy src/app
pytest
```

Plus the architecture gate (import-linter, run from `api/src` with UTF-8 via `lint-imports`) and the new outside-in test:

```
pytest tests/features/posts/0056_migrate_update_post_route_username_to_user_id/migrate_update_post_route_username_to_user_id_outside_in_test.py -v
```

No `alembic` step — `Post.created_by_user_id` already exists; the post fetch/update operate on `Post.id`; no model change. The slice is not done until all checks pass, including `tests/smoke/test_app_starts.py`.

## 6. Tests planned

Four levels per `agent_docs/testing.md`, with the **adapter level opted out** (the adapter is unchanged).

- **Use-case unit test** — `tests/features/posts/0056_migrate_update_post_route_username_to_user_id/domain/test_use_case.py`.
  Mock both `UpdatePostPort` and `UserLookupPort`. Cases (per PRD § Testing Decisions):
  - **Happy path (owner):** lookup returns an author whose `id == requester_user_id`; post fetch returns a post; assert `update` is called with the command and the use-case completes.
  - **User not found:** lookup returns `None` → `NotFoundDomainError("User not found")`; assert `get_post_by_id` and `update` are never called.
  - **Not owner:** lookup returns an author whose `id != requester_user_id` → `ForbiddenDomainError`; assert `get_post_by_id` and `update` are never called.
  - **Post not found:** lookup returns the owner, `get_post_by_id` returns `None` → `NotFoundDomainError("Post not found")`; assert `update` is never called.
  Prior art: `tests/features/posts/0028_update_post/domain/test_use_case.py`.

- **Adapter unit test — opt-out.** The adapter is **not changed** by this slice (documented opt-out: the layer adds no new behaviour). The existing `0028_update_post` adapter test continues to apply unchanged.

- **Endpoint integration test** — `tests/features/posts/0056_migrate_update_post_route_username_to_user_id/presentation/test_router.py`.
  `httpx.AsyncClient` against test Postgres. Cases (per PRD § Testing Decisions):
  - **200 owner:** authenticate as the owner; `PATCH /api/v1/{user_id}/post/{id}` with a partial body; assert 200 and that a subsequent read reflects the change.
  - **403 non-owner:** authenticate as a different user; assert 403.
  - **404 unknown user:** authenticate; target an unknown `user_id`; assert 404.
  - **404 unknown post:** authenticate as the owner; target an unknown post id; assert 404.
  - **401 unauthenticated:** no credentials; assert 401.
  - **422 non-integer `user_id`:** `PATCH /api/v1/not-an-integer/post/1`; assert 422.
  - **Old route gone:** `PATCH /api/v1/{username}/post/{id}` with a string username; assert 422/404.
  - **Cache invalidation:** read the post (populating `{user_id}_post_cache`), update it, read again; assert the updated content is returned (no stale read) — proves cache realignment with `get_post`.
  Prior art: `tests/features/posts/0028_update_post/presentation/test_router.py`.

- **Outside-in test** — `tests/features/posts/0056_migrate_update_post_route_username_to_user_id/migrate_update_post_route_username_to_user_id_outside_in_test.py`.
  Full HTTP stack, real adapter, test Postgres. Acceptance gate. Scenarios per tests.md:
  1. Create a user via `POST /api/v1/users/` (capture `id`); authenticate.
  2. Create a post for that user (capture post `id`).
  3. `PATCH /api/v1/{user_id}/post/{id}` with a new `title` → 200.
  4. `GET /api/v1/{user_id}/post/{id}` → returned post shows the updated title (proves cache invalidation realignment with `get_post`).
  5. As a different user, `PATCH /api/v1/{user_id}/post/{id}` → 403.
  6. `PATCH /api/v1/{username}/post/{id}` with the string username → 422 (old route gone).

**Opt-outs:** adapter unit test only (adapter unchanged — see above). All other levels apply. No shared-adapter test is added here: `get_active_user_by_id` and the id-based `check_post_owner` were introduced and covered by slice 0055 (and slice 0032 for the shared adapter); 0056 only consumes them.

## 7. Out of scope for this slice

- `erase_post` (route), `erase_db_post` — separate migration slices. `erase_post`'s ownership call site was already adapted by 0055; nothing in `erase_post` is touched here.
- The shared `posts/_shared` helpers — already evolved by 0055 (`get_active_user_by_id` additive, `check_post_owner` id-based). Used, not modified, here. Removing `get_active_user_by_username` remains the final cleanup slice's job.
- Adding an owner filter to `get_post_by_id` — the pre-existing no-owner-filter gap is intentionally preserved (behaviour stays identical).
- `get_post` (0054), `create_post` (0055), `list_posts` (0042) — already migrated.
- Adding a user-facing 403 message — `check_post_owner` raises a bare `ForbiddenDomainError()`; a message can be added in a follow-up without affecting this migration.
- Changing the post `id` to a UUID — frozen; the integer `id` is retained.
- No ORM model change and no Alembic migration — `Post.created_by_user_id` already exists.
- The Flutter client (separate working dir) — its calls to the old route break; handled in the Flutter spec slices.

## 8. Open questions

None. The migration mirrors slice 0055's already-implemented write-path mechanism and the `update_user` resolve-then-authorize flow. The shared `check_post_owner` (id-based) and `UserLookupPort.get_active_user_by_id` already exist (verified in `src/app/features/posts/_shared/`), so no `_shared` change and no cross-slice `erase_post` change are required this time. `get_current_user` already exposes the `id` key (verified in `src/app/shared_dependencies.py`); no auth-layer change is needed; no new `DomainError` subclass is introduced. The only behavioural risk — repointing the `@cache` keys — is the intended bug fix and is exercised by the integration cache-invalidation case and the outside-in read-after-update step.
