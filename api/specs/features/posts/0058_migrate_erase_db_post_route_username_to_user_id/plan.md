# 0058 · migrate_erase_db_post_route_username_to_user_id — Implementation plan

## 1. Header

- **Feature:** posts
- **Slice:** 0058_migrate_erase_db_post_route_username_to_user_id
- **PRD:** ./prd.md
- **Reference slices:**
  - `../0030_erase_db_post/` and `../0031_fix_erase_db_post_cascade/` — the slices this migration modifies in place; structural baseline (command, use-case, adapter, port, router, schemas, cache decorator, moderation-log cascade).
  - `../0057_migrate_erase_post_route_username_to_user_id/plan.md` — the immediately-preceding same-shape delete-path route migration. 0058 mirrors its command-retype, router path-param retype, and cache-key repointing (`to_invalidate_extra` dict form). **Key differences:** (1) `erase_db_post` performs **no ownership check** — it is superuser-only (`get_current_superuser`), so there is **no requester field, no `check_post_owner` call, and no `ForbiddenDomainError` raised by the use-case**; the 403 comes solely from the superuser gate at the router boundary and is unchanged. (2) The use-case has a **three-step** shape (lookup → owner-scoped `find_post` → `hard_delete`), not four. (3) It calls `hard_delete` (a physical delete cascading moderation logs, per 0031), not `soft_delete`.
  - `../0054_migrate_get_post_route_username_to_user_id/plan.md` — the read-path sibling that repointed the `{user_id}_post_cache` read key this slice must invalidate; relevant to the cache-realignment bug fix.
- **HTTP path:** `DELETE /api/v1/{user_id}/db_post/{id}` (was `DELETE /api/v1/{username}/db_post/{id}`)
- **STABLE files touched:** none. `erase_db_post` is already registered in `bootstrap/router.py`; the `erase_db_post_adapter` and `erase_db_post_use_case` providers (the latter already wired with `port=erase_db_post_adapter, user_lookup=user_lookup_adapter`) exist in `bootstrap/container.py` with unchanged import paths; the `.importlinter` ignore entry for the `erase_db_post` router already exists (line 83). No new wiring. No new `DomainError` subclass (`NotFoundDomainError` is already in the STABLE hierarchy).

## 2. Context summary

Slice 0058 migrates the `erase_db_post` endpoint — a **superuser-only** single-post hard delete — from keying the target author on `{username}` to keying on `{user_id}` (the integer autoincrement PK of `User`). It is the fifth and final route-migration slice of the `{username}` → `{user_id}` initiative. `EraseDbPostCommand.username: str` becomes `user_id: int`; `post_id: int` is unchanged. There is no requester field and no ownership check — a superuser may hard-delete any user's post, gated only by `get_current_superuser` at the router. The use-case keeps its three-step shape and swaps only the target lookup: resolve the author by id (`get_active_user_by_id`) → 404 "User not found" if absent; fetch the owner-scoped post (`find_post(post_id, owner_id=user.id)`) → 404 "Post not found" if absent; then `hard_delete(post_id)` (preserving the moderation-log cascade from 0031). The router reads `user_id: int` from the path. The `@cache` decorator's keys are repointed from `{username}_…` to `{user_id}_…`, which **realigns** `erase_db_post`'s invalidation with the keys `list_posts` (0042, `{user_id}_posts`) and `get_post` (0054, `{user_id}_post_cache`) already use — fixing the latent partial-migration staleness bug as a direct consequence. The response (`EraseDbPostResponse` — a bare `{"message": "Post deleted from the database"}`) is unchanged. The data adapter (`EraseDbPostAdapter`) and its port are unchanged — `find_post(post_id, owner_id)` and `hard_delete(post_id)` never referenced `username`. The shared `_shared` modules are **not** modified (already evolved by 0055). After this slice, `get_active_user_by_username` has zero callers; removing it is the cleanup slice's job. The old `/{username}/db_post/{id}` route is removed with no compatibility shim. No ORM model change; no Alembic migration.

## 3. API contract

**Path params:**

| Param | Type | Notes |
|---|---|---|
| `user_id` | `int` | Integer primary key of the post author (was `username: str`) |
| `id` | `int` | Post id (unchanged) |

**Query params:** none.

**Request body:** none (DELETE).

**Authentication:** required, **superuser only** (`get_current_superuser`). No per-post ownership check.

**Response body** (`EraseDbPostResponse`, HTTP 200) — **unchanged**:

| Field | Type |
|---|---|
| `message` | `str` (`"Post deleted from the database"`) |

**Status codes:**

| Status | Condition | Source |
|---|---|---|
| `200 OK` | Post hard-deleted | success |
| `401 Unauthorized` | No / invalid credentials | `get_current_superuser` (auth layer) |
| `403 Forbidden` | Authenticated user is not a superuser | `get_current_superuser` (auth layer) |
| `404 Not Found` | `user_id` not found / soft-deleted, **or** post not found / not owned by `user_id` | `NotFoundDomainError("User not found")` / `NotFoundDomainError("Post not found")` |
| `422 Unprocessable Entity` | Non-integer `user_id` path segment (also covers the old `/{username}/db_post/{id}` URL called with a non-numeric username) | FastAPI path validation |

Ordering is **404(user) → 404(post)**, preserved exactly from slices 0030/0031: the author is resolved first; the owner-scoped post is fetched only after the author exists; the hard delete runs last. There is **no ownership branch** in the use-case (superuser-only). No new `DomainError` subclass is introduced. **No 403 message change** — the 403 originates from the superuser gate, not the use-case.

## 4. File structure

No new files. All changes are in-place modifications of two existing slice files (command + router). The use-case is changed only by the single lookup-method swap (one line). The `_shared` modules, the adapter, the port, and the schemas are **not** touched.

Files **modified**:

```
src/app/features/posts/erase_db_post/domain/commands.py
    EraseDbPostCommand:
        username: str   → user_id: int
        (post_id: int unchanged)

src/app/features/posts/erase_db_post/domain/use_case.py
    lookup: get_active_user_by_username(command.username)
            → get_active_user_by_id(command.user_id)   → 404 "User not found" if None
    (owner-scoped find_post fetch, hard_delete — UNCHANGED;
     imports already correct: NotFoundDomainError, UserLookupPort)

src/app/features/posts/erase_db_post/presentation/router.py
    path:        "/{username}/db_post/{id}" → "/{user_id}/db_post/{id}"
    path param:  username: str               → user_id: int        (id: int unchanged)
    cache:       key_prefix "{username}_post_cache"               → "{user_id}_post_cache"
                 to_invalidate_extra {"{username}_posts": "{username}"} → {"{user_id}_posts": "{user_id}"}
                 resource_id_name="id"                            (UNCHANGED)
    command build: username=username                             → user_id=user_id
                   post_id=id                                    (UNCHANGED)
    auth dependency: get_current_superuser                        (UNCHANGED)
```

Files **not** changed:

```
src/app/features/posts/erase_db_post/data/adapter.py                  # find_post(post_id, owner_id) + hard_delete(post_id) read only post_id + integer owner_id
src/app/features/posts/erase_db_post/domain/ports/erase_db_post_port.py # find_post / hard_delete signatures unchanged
src/app/features/posts/erase_db_post/domain/entities.py               # EraseDbPostRecord unchanged
src/app/features/posts/erase_db_post/presentation/schemas.py          # response shape unchanged
src/app/features/posts/_shared/user_lookup_port.py                    # get_active_user_by_id ALREADY present (0055)
src/app/features/posts/_shared/user_lookup_adapter.py                 # get_active_user_by_id ALREADY implemented (0055)
bootstrap/container.py, bootstrap/router.py, .importlinter            # no wiring change
```

## 5. Implementation steps

### Step 1 — Domain: retype `EraseDbPostCommand`

**File:** `src/app/features/posts/erase_db_post/domain/commands.py`

```python
class EraseDbPostCommand(BaseModel):
    user_id: int
    post_id: int
```

Only the target author identifier changes `username: str` → `user_id: int`; `post_id` is unchanged. There is no requester field (superuser-only, no ownership check).

### Step 2 — Domain: swap the target lookup in `EraseDbPostUseCase`

**File:** `src/app/features/posts/erase_db_post/domain/use_case.py`

The imports are already correct (`NotFoundDomainError`, `UserLookupPort`). Change only the lookup call and the field it reads:

```python
async def __call__(self, command: EraseDbPostCommand) -> None:
    user = await self._user_lookup.get_active_user_by_id(command.user_id)
    if user is None:
        raise NotFoundDomainError("User not found")
    post = await self._port.find_post(command.post_id, owner_id=user.id)
    if post is None:
        raise NotFoundDomainError("Post not found")
    await self._port.hard_delete(command.post_id)
```

The owner-scoped `find_post` and `hard_delete` (with its moderation-log cascade from 0031) are unchanged. The 404(user)→404(post) ordering is preserved. **No ownership check is added** — there is no `check_post_owner` call and no `ForbiddenDomainError`. The constructor signature (`port`, `user_lookup`) is unchanged, so no DI change.

### Step 3 — Presentation: update `erase_db_post` router (path, param, cache keys, command)

**File:** `src/app/features/posts/erase_db_post/presentation/router.py`

1. Route path: `@router.delete("/{user_id}/db_post/{id}", response_model=EraseDbPostResponse, status_code=200)` (was `/{username}/db_post/{id}`).
2. Cache decorator: repoint **both** halves to `user_id`, leaving `resource_id_name="id"`:

```python
@cache(
    "{user_id}_post_cache",
    resource_id_name="id",
    to_invalidate_extra={"{user_id}_posts": "{user_id}"},
)
```

Note `erase_db_post` uses `to_invalidate_extra` (a dict mapping key-template → id-template), not `pattern_to_invalidate_extra` (a glob list) — preserve the dict form, repoint both the key template and the id template (same form as `erase_post`/0057).

3. Endpoint signature: path param `user_id: int` replaces `username: str`; `id: int`, `request`, the `get_current_superuser` dependency, and `use_case` are unchanged.
4. Command construction:

```python
command = EraseDbPostCommand(user_id=user_id, post_id=id)
```

Response assembly (`EraseDbPostResponse(message="Post deleted from the database")`) is unchanged. The auth dependency stays `get_current_superuser` — no `current_user["id"]` is read because there is no requester/ownership concept here.

### Step 4 — Update slices 0030 / 0031 integration & outside-in test URLs (acceptance-gate dependency)

Per the PRD § Further Notes, the existing `tests/features/posts/0030_erase_db_post/` and `tests/features/posts/0031_fix_erase_db_post_cascade/` tests hit `/api/v1/{username}/db_post/{id}` and construct `EraseDbPostCommand` with a `username` field; both break after this slice. Update their endpoint URLs to the integer-keyed route `/api/v1/{user_id}/db_post/{id}` and their command/fixtures to `user_id`, or note in tests.md that they are superseded by the 0058 tests. Before and after, baseline the full suite and prove zero net-new failures (user memory `project_route_migration_downstream_tests`). Grep the repo for other callers of the `DELETE /db_post/{id}` route and for `EraseDbPostCommand(... username=` / `.username` on `EraseDbPostCommand` to catch any downstream slice sharing this source.

### Step 5 — Verify

```
ruff format src/app tests
ruff check src/app tests
mypy src/app
pytest
```

Plus the architecture gate (import-linter, run from `api/src` with UTF-8 via `lint-imports`) and the new outside-in test:

```
pytest tests/features/posts/0058_migrate_erase_db_post_route_username_to_user_id/migrate_erase_db_post_route_username_to_user_id_outside_in_test.py -v
```

No `alembic` step — `Post.created_by_user_id` already exists; `find_post`/`hard_delete` operate on `Post.id` / `Post.created_by_user_id`; no model change. The slice is not done until all checks pass (including the import-level smoke test if present).

## 6. Tests planned

Four levels per `agent_docs/testing.md`, with the **adapter level opted out** (the adapter is unchanged).

- **Use-case unit test** — `tests/features/posts/0058_migrate_erase_db_post_route_username_to_user_id/domain/test_use_case.py`.
  Mock both `EraseDbPostPort` and `UserLookupPort`. Cases (per PRD § Testing Decisions):
  - **Happy path:** `get_active_user_by_id` returns a user; `find_post` returns a record; assert `hard_delete` is called with `post_id`.
  - **User not found:** `get_active_user_by_id` returns `None` → `NotFoundDomainError("User not found")`; assert `find_post` and `hard_delete` are never called.
  - **Post not found / not owned:** lookup returns the user, `find_post` returns `None` → `NotFoundDomainError("Post not found")`; assert `hard_delete` is never called.
  No "not owner" case — there is no ownership check (superuser-only). Prior art: `tests/features/posts/0030_erase_db_post/domain/test_use_case.py` (currently drives the lookup by username; this slice updates it to drive the lookup by id).

- **Adapter unit test — opt-out.** The adapter is **not changed** by this slice (documented opt-out: the layer adds no new behaviour). The existing `0030_erase_db_post` / `0031_fix_erase_db_post_cascade` adapter tests (including the moderation-log cascade test) continue to apply unchanged.

- **Endpoint integration test** — `tests/features/posts/0058_migrate_erase_db_post_route_username_to_user_id/presentation/test_router.py`.
  `httpx.AsyncClient` against test Postgres. Cases (per PRD § Testing Decisions):
  - **200 superuser:** authenticate as a superuser; `DELETE /api/v1/{user_id}/db_post/{id}`; assert 200 and that a subsequent read returns 404 (post gone).
  - **403 non-superuser:** authenticate as a regular user; assert 403.
  - **404 unknown user:** authenticate as a superuser; target an unknown `user_id`; assert 404.
  - **404 unknown post:** authenticate as a superuser; target an unknown post id; assert 404.
  - **401 unauthenticated:** no credentials; assert 401.
  - **422 non-integer `user_id`:** `DELETE /api/v1/not-an-integer/db_post/1`; assert 422.
  - **Old route gone:** `DELETE /api/v1/{username}/db_post/{id}` with a string username; assert 422/404.
  - **Cache invalidation:** read the post (populating `{user_id}_post_cache`), hard-delete it, read again; assert the post is gone (no stale read) — proves cache realignment with `get_post`.
  Prior art: `tests/features/posts/0030_erase_db_post/presentation/` and `tests/features/posts/0031_fix_erase_db_post_cascade/`.

- **Outside-in test** — `tests/features/posts/0058_migrate_erase_db_post_route_username_to_user_id/migrate_erase_db_post_route_username_to_user_id_outside_in_test.py`.
  Full HTTP stack, real adapter, test Postgres. Acceptance gate. Scenarios per tests.md:
  1. Create a user via `POST /api/v1/users/` (capture `id`).
  2. Create a post for that user (capture post `id`).
  3. Authenticate as a superuser; `GET /api/v1/{user_id}/post/{id}` → 200 (populates the read cache).
  4. `DELETE /api/v1/{user_id}/db_post/{id}` → 200.
  5. `GET /api/v1/{user_id}/post/{id}` → 404 (proves the hard delete invalidated the `{user_id}`-keyed read cache and removed the row).
  6. `DELETE /api/v1/{username}/db_post/{id}` with the string username → 422 (old route gone).

**Opt-outs:** adapter unit test only (adapter unchanged — see above). All other levels apply. No shared-adapter test is added here: `get_active_user_by_id` was introduced and covered by slice 0055 (and slice 0032 for the shared adapter); 0058 only consumes it.

## 7. Out of scope for this slice

- Removing `get_active_user_by_username` from `UserLookupPort`/`UserLookupAdapter` and updating its adapter test (`tests/features/posts/0032_extract_user_lookup/`) — that is the **cleanup slice's** job. This slice removes the last *caller* but leaves the method in place.
- Adding a per-post ownership check — `erase_db_post` is superuser-only by design; no ownership check is added and no `ForbiddenDomainError` is raised by the use-case.
- The `find_post` soft-delete filter and the `hard_delete` moderation-log cascade — preserved exactly as established in slices 0030 / 0031.
- `get_post` (0054), `create_post` (0055), `update_post` (0056), `erase_post` (0057), `list_posts` (0042) — already migrated.
- Changing the post `id` to a UUID — frozen; the integer `id` is retained.
- No ORM model change and no Alembic migration — `Post.created_by_user_id` already exists.
- The Flutter client (separate working dir) — its calls to the old route break; handled in the Flutter spec slices.

## 8. Open questions

None. The migration mirrors slice 0057's already-implemented delete-path mechanism, minus the ownership concern (`erase_db_post` is superuser-only). The shared `UserLookupPort.get_active_user_by_id` already exists (verified in `src/app/features/posts/_shared/`), so no `_shared` change is required. The `erase_db_post_use_case` provider is already wired with both `port` and `user_lookup` (verified in `bootstrap/container.py`), so no DI change is needed; no auth-layer change is needed; no new `DomainError` subclass is introduced. The only behavioural risk — repointing the `@cache` keys (a `to_invalidate_extra` dict, not a `pattern_to_invalidate_extra` list) — is the intended bug fix and is exercised by the integration cache-invalidation case and the outside-in read-after-delete step.
</content>
</invoke>
