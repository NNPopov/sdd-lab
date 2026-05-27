# 0057 · migrate_erase_post_route_username_to_user_id — Implementation plan

## 1. Header

- **Feature:** posts
- **Slice:** 0057_migrate_erase_post_route_username_to_user_id
- **PRD:** ./prd.md
- **Reference slices:**
  - `../0029_erase_post/` — the slice this migration modifies in place; structural baseline (command, use-case, adapter, port, router, schemas, cache decorator).
  - `../0056_migrate_update_post_route_username_to_user_id/plan.md` — the immediately-preceding same-shape write-path route migration. 0057 mirrors its command-retype, router path-param retype, requester-id-from-auth-dict, and cache-key repointing. **Key difference:** `update_post` had only the *target* identifier left to migrate (its requester was migrated in 0055); `erase_post` is in the same position — only the *target* `username` and the cache keys remain, because 0055 already pre-migrated `erase_post`'s `requester_user_id`, router requester wiring, and the id-based `check_post_owner` call site. A second difference: `erase_post`'s ownership check **already raises a bare `ForbiddenDomainError`** (since 0055), so — unlike 0056 — there is **no 403 message change** in this slice. A third difference: `erase_post`'s cache invalidation uses `to_invalidate_extra={...}` (a dict mapping key-template → id-template), not `pattern_to_invalidate_extra=[...]` (a glob list); both halves are repointed.
  - `../0054_migrate_get_post_route_username_to_user_id/plan.md` — the read-path sibling that repointed the `{user_id}_post_cache` read key this slice must invalidate; relevant to the cache-realignment bug fix.
- **HTTP path:** `DELETE /api/v1/{user_id}/post/{id}` (was `DELETE /api/v1/{username}/post/{id}`)
- **STABLE files touched:** none. `erase_post` is already registered in `bootstrap/router.py`; the `erase_post_adapter`, `erase_post_use_case`, and `user_lookup_adapter` providers already exist in `bootstrap/container.py` with unchanged import paths; the `.importlinter` ignore entry for the `erase_post` router already exists. No new wiring. No new `DomainError` subclass (`NotFoundDomainError` and `ForbiddenDomainError` are already in the STABLE hierarchy).

## 2. Context summary

Slice 0057 migrates the `erase_post` endpoint — an authenticated single-post soft delete — from keying the *target author* on `{username}` to keying on `{user_id}` (the integer autoincrement PK of `User`). `ErasePostCommand.username: str` becomes `user_id: int`; `requester_user_id: int` and `post_id: int` are unchanged (the requester was already migrated by 0055). The use-case keeps its four-step shape and swaps only the target lookup: resolve the author by id (`get_active_user_by_id`) → 404 "User not found" if absent; enforce ownership via the shared `check_post_owner` policy (already id-based, bare 403); fetch the owner-scoped post (`find_post(post_id, owner_id=user.id)`) → 404 "Post not found" if absent; then `soft_delete(post_id)`. The router reads `user_id: int` from the path and derives the requester from `current_user["id"]` (unchanged). The `@cache` decorator's keys are repointed from `{username}_…` to `{user_id}_…`, which **realigns** `erase_post`'s invalidation with the keys `list_posts` (0042, `{user_id}_posts`) and `get_post` (0054, `{user_id}_post_cache`) already use — fixing the latent partial-migration staleness bug as a direct consequence. The response (`ErasePostResponse` — a bare `{"message": "Post deleted"}`) is unchanged. The data adapter (`ErasePostAdapter`) and its port are unchanged — `find_post(post_id, owner_id)` and `soft_delete(post_id)` never referenced `username`. The shared `_shared` modules are **not** modified (already evolved by 0055). The old `/{username}/post/{id}` route is removed with no compatibility shim. No ORM model change; no Alembic migration.

## 3. API contract

**Path params:**

| Param | Type | Notes |
|---|---|---|
| `user_id` | `int` | Integer primary key of the post author (was `username: str`) |
| `id` | `int` | Post id (unchanged) |

**Query params:** none.

**Request body:** none (DELETE).

**Authentication:** required (`get_current_user`). The requester must equal the target author (`requester_user_id == user_id`).

**Response body** (`ErasePostResponse`, HTTP 200) — **unchanged**:

| Field | Type |
|---|---|
| `message` | `str` (`"Post deleted"`) |

**Status codes:**

| Status | Condition | Source |
|---|---|---|
| `200 OK` | Post soft-deleted for the authenticated owner | success |
| `401 Unauthorized` | No / invalid credentials | `get_current_user` (auth layer) |
| `403 Forbidden` | Authenticated requester is not the target user | `check_post_owner` → `ForbiddenDomainError()` |
| `404 Not Found` | `user_id` not found / soft-deleted, **or** post not found / not owned by `user_id` | `NotFoundDomainError("User not found")` / `NotFoundDomainError("Post not found")` |
| `422 Unprocessable Entity` | Non-integer `user_id` path segment (also covers the old `/{username}/post/{id}` URL called with a non-numeric username) | FastAPI path validation |

Ordering is **404(user) → 403(owner) → 404(post)**, preserved exactly from slice 0029: the author is resolved first; ownership is only checked once the author exists; the post is fetched only after ownership passes. No new `DomainError` subclass is introduced. **No 403 message change** — `check_post_owner` already raises a bare `ForbiddenDomainError()` (since 0055).

## 4. File structure

No new files. All changes are in-place modifications of two existing `0029_erase_post` slice files (command + router). The use-case is **not** changed except for the single lookup-method swap (one line). The `_shared` modules, the adapter, and the port are **not** touched.

Files **modified**:

```
src/app/features/posts/erase_post/domain/commands.py
    ErasePostCommand:
        username: str   → user_id: int
        (post_id: int, requester_user_id: int unchanged)

src/app/features/posts/erase_post/domain/use_case.py
    lookup: get_active_user_by_username(command.username)
            → get_active_user_by_id(command.user_id)   → 404 "User not found" if None
    (ownership check_post_owner, find_post owner-scoped fetch, soft_delete — UNCHANGED;
     imports already correct: NotFoundDomainError, check_post_owner, UserLookupPort)

src/app/features/posts/erase_post/presentation/router.py
    path:        "/{username}/post/{id}" → "/{user_id}/post/{id}"
    path param:  username: str           → user_id: int        (id: int unchanged)
    cache:       key_prefix "{username}_post_cache"               → "{user_id}_post_cache"
                 to_invalidate_extra {"{username}_posts": "{username}"} → {"{user_id}_posts": "{user_id}"}
                 resource_id_name="id"                            (UNCHANGED)
    command build: username=username                             → user_id=user_id
                   requester_user_id=current_user["id"]          (UNCHANGED)
                   post_id=id                                    (UNCHANGED)
```

Files **not** changed:

```
src/app/features/posts/erase_post/data/adapter.py                  # find_post(post_id, owner_id) + soft_delete(post_id) read only post_id + integer owner_id
src/app/features/posts/erase_post/domain/ports/erase_post_port.py  # find_post / soft_delete signatures unchanged
src/app/features/posts/erase_post/presentation/schemas.py          # response shape unchanged
src/app/features/posts/_shared/policies.py                         # check_post_owner ALREADY id-based (0055)
src/app/features/posts/_shared/user_lookup_port.py                 # get_active_user_by_id ALREADY present (0055)
src/app/features/posts/_shared/user_lookup_adapter.py              # get_active_user_by_id ALREADY implemented (0055)
bootstrap/container.py, bootstrap/router.py, .importlinter         # no wiring change
```

## 5. Implementation steps

### Step 1 — Domain: retype `ErasePostCommand`

**File:** `src/app/features/posts/erase_post/domain/commands.py`

```python
class ErasePostCommand(BaseModel):
    user_id: int
    post_id: int
    requester_user_id: int
```

Only the target author identifier changes `username: str` → `user_id: int`; `post_id` and `requester_user_id` are unchanged (requester migrated in 0055).

### Step 2 — Domain: swap the target lookup in `ErasePostUseCase`

**File:** `src/app/features/posts/erase_post/domain/use_case.py`

The imports are already correct (`NotFoundDomainError`, `check_post_owner`, `UserLookupPort` — all from 0055). Change only the lookup call and the field it reads:

```python
async def __call__(self, command: ErasePostCommand) -> None:
    user = await self._user_lookup.get_active_user_by_id(command.user_id)
    if user is None:
        raise NotFoundDomainError("User not found")
    check_post_owner(command.requester_user_id, user.id)
    post = await self._port.find_post(command.post_id, owner_id=user.id)
    if post is None:
        raise NotFoundDomainError("Post not found")
    await self._port.soft_delete(command.post_id)
```

The ownership check, the owner-scoped `find_post`, and `soft_delete` are unchanged. The 404(user)→403(owner)→404(post) ordering is preserved. The constructor signature (`port`, `user_lookup`) is unchanged, so no DI change.

### Step 3 — Presentation: update `erase_post` router (path, param, cache keys, command)

**File:** `src/app/features/posts/erase_post/presentation/router.py`

1. Route path: `@router.delete("/{user_id}/post/{id}", response_model=ErasePostResponse, status_code=200)` (was `/{username}/post/{id}`).
2. Cache decorator: repoint **both** halves to `user_id`, leaving `resource_id_name="id"`:

```python
@cache(
    "{user_id}_post_cache",
    resource_id_name="id",
    to_invalidate_extra={"{user_id}_posts": "{user_id}"},
)
```

Note `erase_post` uses `to_invalidate_extra` (a dict), not `pattern_to_invalidate_extra` (a list) — preserve the dict form, repoint both the key template and the id template.

3. Endpoint signature: path param `user_id: int` replaces `username: str`; `id: int`, `request`, `current_user`, and `use_case` are unchanged.
4. Command construction:

```python
command = ErasePostCommand(
    user_id=user_id,
    post_id=id,
    requester_user_id=current_user["id"],
)
```

`current_user["id"]` is available — `get_current_user` returns a dict that includes `id` (verified in `src/app/shared_dependencies.py`, already relied on by `erase_post` for `requester_user_id` since 0055). Response assembly (`ErasePostResponse(message="Post deleted")`) is unchanged.

### Step 4 — Update slice 0029 integration / outside-in test URLs (acceptance-gate dependency)

Per the PRD § Further Notes, the existing `tests/features/posts/0029_erase_post/` tests hit `/api/v1/{username}/post/{id}` and construct `ErasePostCommand` with a `username` field; both break after this slice. Update their endpoint URLs to the integer-keyed route `/api/v1/{user_id}/post/{id}` and their command/fixtures to `user_id`, or note in tests.md that they are superseded by the 0057 tests. Before and after, baseline the full suite and prove zero net-new failures (user memory `project_route_migration_downstream_tests`). Grep the repo for other callers of the `DELETE /post/{id}` route and for `ErasePostCommand(... username=`/`.username` on `ErasePostCommand` to catch any downstream slice sharing this source.

### Step 5 — Verify

```
ruff format src/app tests
ruff check src/app tests
mypy src/app
pytest
```

Plus the architecture gate (import-linter, run from `api/src` with UTF-8 via `lint-imports`) and the new outside-in test:

```
pytest tests/features/posts/0057_migrate_erase_post_route_username_to_user_id/migrate_erase_post_route_username_to_user_id_outside_in_test.py -v
```

No `alembic` step — `Post.created_by_user_id` already exists; `find_post`/`soft_delete` operate on `Post.id` / `Post.created_by_user_id`; no model change. The slice is not done until all checks pass, including `tests/smoke/test_app_starts.py`.

## 6. Tests planned

Four levels per `agent_docs/testing.md`, with the **adapter level opted out** (the adapter is unchanged).

- **Use-case unit test** — `tests/features/posts/0057_migrate_erase_post_route_username_to_user_id/domain/test_use_case.py`.
  Mock both `ErasePostPort` and `UserLookupPort`. Cases (per PRD § Testing Decisions):
  - **Happy path (owner):** `get_active_user_by_id` returns an author whose `id == requester_user_id`; `find_post` returns a record; assert `soft_delete` is called with `post_id`.
  - **User not found:** `get_active_user_by_id` returns `None` → `NotFoundDomainError("User not found")`; assert `find_post` and `soft_delete` are never called.
  - **Not owner:** `get_active_user_by_id` returns an author whose `id != requester_user_id` → `ForbiddenDomainError`; assert `find_post` and `soft_delete` are never called.
  - **Post not found / not owned:** lookup returns the owner, `find_post` returns `None` → `NotFoundDomainError("Post not found")`; assert `soft_delete` is never called.
  Prior art: `tests/features/posts/0029_erase_post/domain/test_use_case.py` (already drives ownership with ids since 0055; this slice updates the target lookup from username to id).

- **Adapter unit test — opt-out.** The adapter is **not changed** by this slice (documented opt-out: the layer adds no new behaviour). The existing `0029_erase_post` adapter test continues to apply unchanged.

- **Endpoint integration test** — `tests/features/posts/0057_migrate_erase_post_route_username_to_user_id/presentation/test_router.py`.
  `httpx.AsyncClient` against test Postgres. Cases (per PRD § Testing Decisions):
  - **200 owner:** authenticate as the owner; `DELETE /api/v1/{user_id}/post/{id}`; assert 200 and that a subsequent read returns 404 (post gone).
  - **403 non-owner:** authenticate as a different user; assert 403.
  - **404 unknown user:** authenticate; target an unknown `user_id`; assert 404.
  - **404 unknown post:** authenticate as the owner; target an unknown post id; assert 404.
  - **401 unauthenticated:** no credentials; assert 401.
  - **422 non-integer `user_id`:** `DELETE /api/v1/not-an-integer/post/1`; assert 422.
  - **Old route gone:** `DELETE /api/v1/{username}/post/{id}` with a string username; assert 422/404.
  - **Cache invalidation:** read the post (populating `{user_id}_post_cache`), delete it, read again; assert the post is gone (no stale read) — proves cache realignment with `get_post`.
  Prior art: `tests/features/posts/0029_erase_post/presentation/test_router.py`.

- **Outside-in test** — `tests/features/posts/0057_migrate_erase_post_route_username_to_user_id/migrate_erase_post_route_username_to_user_id_outside_in_test.py`.
  Full HTTP stack, real adapter, test Postgres. Acceptance gate. Scenarios per tests.md:
  1. Create a user via `POST /api/v1/users/` (capture `id`); authenticate.
  2. Create a post for that user (capture post `id`).
  3. `GET /api/v1/{user_id}/post/{id}` → 200 (populates the read cache).
  4. `DELETE /api/v1/{user_id}/post/{id}` → 200.
  5. `GET /api/v1/{user_id}/post/{id}` → 404 (proves the delete invalidated the `{user_id}`-keyed read cache).
  6. As a different user, `DELETE /api/v1/{user_id}/post/{id}` on one of their posts → 403.
  7. `DELETE /api/v1/{username}/post/{id}` with the string username → 422 (old route gone).

**Opt-outs:** adapter unit test only (adapter unchanged — see above). All other levels apply. No shared-adapter test is added here: `get_active_user_by_id` and the id-based `check_post_owner` were introduced and covered by slice 0055 (and slice 0032 for the shared adapter); 0057 only consumes them.

## 7. Out of scope for this slice

- `erase_db_post` — the final route-migration slice (superuser hard delete); not changed here. It remains the only `{username}` post route and the only remaining consumer of `get_active_user_by_username` after this slice.
- The shared `posts/_shared` helpers — already evolved by 0055 (`get_active_user_by_id` additive, `check_post_owner` id-based). Used, not modified, here. Removing `get_active_user_by_username` remains the final cleanup slice's job (still needed by `erase_db_post`).
- The ownership mechanism and 403 message — already id-based and message-less since 0055; unchanged.
- `get_post` (0054), `create_post` (0055), `update_post` (0056), `list_posts` (0042) — already migrated.
- Changing the post `id` to a UUID — frozen; the integer `id` is retained.
- No ORM model change and no Alembic migration — `Post.created_by_user_id` already exists.
- The Flutter client (separate working dir) — its calls to the old route break; handled in the Flutter spec slices.

## 8. Open questions

None. The migration mirrors slice 0056's already-implemented write-path mechanism and the `update_user` resolve-then-authorize flow, and builds directly on 0055's partial pre-migration of `erase_post` (requester id, router requester wiring, id-based `check_post_owner` call site — all verified in `src/app/features/posts/erase_post/`). The shared `check_post_owner` (id-based) and `UserLookupPort.get_active_user_by_id` already exist, so no `_shared` change is required. `get_current_user` already exposes the `id` key and `erase_post` already uses it for `requester_user_id`; no auth-layer change is needed; no new `DomainError` subclass is introduced. The only behavioural risk — repointing the `@cache` keys (a `to_invalidate_extra` dict, not a `pattern_to_invalidate_extra` list) — is the intended bug fix and is exercised by the integration cache-invalidation case and the outside-in read-after-delete step.
