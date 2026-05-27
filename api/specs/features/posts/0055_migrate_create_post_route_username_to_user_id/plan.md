# 0055 · migrate_create_post_route_username_to_user_id — Implementation plan

## 1. Header

- **Feature:** posts
- **Slice:** 0055_migrate_create_post_route_username_to_user_id
- **PRD:** ./prd.md
- **Reference slices:**
  - `../0011_create_post/` — the slice this migration modifies in place; structural baseline (command, use-case, adapter, router, schemas).
  - `../0054_migrate_get_post_route_username_to_user_id/plan.md` — same operation shape (`{username}` → `{user_id}` route migration); used for the migration mechanics (command field rename, router path-param retype, requester id from the auth dict). Mirrored, with two deliberate differences: this slice is on the **write path**, so it (a) keeps an explicit user-existence lookup that returns 404, and (b) evolves the shared `posts/_shared` lookup + ownership modules rather than leaving them untouched.
  - `users/update_user/` — the canonical id-based **resolve-then-authorize** flow (`get_*_by_id` → 404, then ownership check → 403); the `create_post` use-case is realigned to mirror it.
- **HTTP path:** `POST /api/v1/{user_id}/post` (was `POST /api/v1/{username}/post`)
- **STABLE files touched:** none. `create_post` is already registered in `bootstrap/router.py`; the `create_post_adapter`, `create_post_use_case`, and `user_lookup_adapter` providers already exist in `bootstrap/container.py` and their import paths are unchanged; the `.importlinter` ignore entry for the `create_post` router already exists. No new wiring. No new `DomainError` subclass (`NotFoundDomainError` and `ForbiddenDomainError` are already in the STABLE hierarchy).

## 2. Context summary

Slice 0055 migrates the `create_post` endpoint — an authenticated single-post write — from keying the author on `{username}` to keying on `{user_id}` (the integer autoincrement PK of `User`). It is the first **write-path** route migration and therefore the first slice to evolve the shared `posts/_shared` helpers. `CreatePostCommand` fields `target_username: str` and `requester_username: str` become `target_user_id: int` and `requester_user_id: int`. The use-case is realigned to the `update_user` reference: resolve the author by id (`get_active_user_by_id`) → 404 "User not found" if absent; enforce ownership via the shared `check_post_owner` policy (now id-based) → 403 if the requester is not that author; then build `CreatePostInternalCommand(created_by_user_id=author.id, …)` and call the create port. The router reads `user_id: int` from the path and derives the requester from `current_user["id"]`. The shared `UserLookupPort`/`UserLookupAdapter` gain `get_active_user_by_id` **additively** (the username method is retained for not-yet-migrated callers); the shared `check_post_owner` policy is **converted** from username- to id-based comparison. Because `erase_post` is the only other caller of `check_post_owner`, this slice makes a contained change to `erase_post` (command field, router, use-case call site) to keep the suite green — its route, cache keys, and target lookup are explicitly **not** migrated here. The request and response body shapes (`CreatePostRequest`, `CreatePostResponse`) are unchanged. The data adapter (`CreatePostAdapter`) is unchanged. The old `/{username}/post` route is removed with no compatibility shim. No ORM model change; no Alembic migration.

## 3. API contract

**Path params:**

| Param | Type | Notes |
|---|---|---|
| `user_id` | `int` | Integer primary key of the post author (was `username: str`) |

**Query params:** none.

**Request body** (`CreatePostRequest`) — **unchanged**, `extra="forbid"` retained:

| Field | Type | Validation |
|---|---|---|
| `title` | `str` | `min_length=1, max_length=30` |
| `text` | `str` | `min_length=1, max_length=63206` |
| `media_url` | `str \| None` | optional, defaults `None` |

**Authentication:** required (`get_current_user`). The requester must equal the target author (`requester_user_id == target_user_id`).

**Response body** (`CreatePostResponse`, HTTP 201) — **unchanged shape**:

| Field | Type |
|---|---|
| `id` | `int` |
| `title` | `str` |
| `text` | `str` |
| `media_url` | `str \| None` |
| `created_by_user_id` | `int` |
| `created_at` | `datetime` |
| `status` | `str` (default `pending_review`) |
| `post_uuid` | `uuid.UUID` |

Note: `create_post` has no `username` field in its response (only `created_by_user_id`); unchanged.

**Status codes:**

| Status | Condition | Source |
|---|---|---|
| `201 Created` | Post created for the authenticated owner | success |
| `401 Unauthorized` | No / invalid credentials | `get_current_user` (auth layer) |
| `403 Forbidden` | Authenticated requester is not the target user | `check_post_owner` → `ForbiddenDomainError()` |
| `404 Not Found` | `user_id` does not exist or is soft-deleted | `NotFoundDomainError("User not found")` |
| `422 Unprocessable Entity` | Non-integer `user_id` path segment (also covers the old `/{username}/post` URL called with a non-numeric username); invalid request body | FastAPI path/body validation |

Ordering is **404-before-403**: the author is resolved first; ownership is only checked once the author exists. No new `DomainError` subclass is introduced — `NotFoundDomainError` and `ForbiddenDomainError` are already part of the STABLE error hierarchy.

**Observable behaviour change:** the previous `create_post`-specific 403 message ("You can only post under your own username") is removed; ownership now delegates to the shared `check_post_owner`, which raises a bare `ForbiddenDomainError()` (no message), matching `erase_post`.

## 4. File structure

No new files. All changes are in-place modifications of the existing `0011_create_post` slice files plus the feature's `_shared` modules and a contained `erase_post` adaptation.

Files **modified**:

```
src/app/features/posts/create_post/domain/commands.py
    CreatePostCommand:
        target_username: str    → target_user_id: int
        requester_username: str → requester_user_id: int
        (title, text, media_url unchanged)
    CreatePostInternalCommand   (unchanged — already carries created_by_user_id: int)

src/app/features/posts/create_post/domain/use_case.py
    lookup:     get_active_user_by_username(target_username)
                → get_active_user_by_id(target_user_id)   → 404 "User not found" if None
    ownership:  inline `if command.requester_username != author.username: raise ForbiddenDomainError("…")`
                → check_post_owner(command.requester_user_id, author.id)   (bare 403)
    internal:   CreatePostInternalCommand(created_by_user_id=author.id, …)  (unchanged shape)
    imports:    drop ForbiddenDomainError (now raised inside check_post_owner);
                add `from ..._shared.policies import check_post_owner`;
                keep NotFoundDomainError.

src/app/features/posts/create_post/presentation/router.py
    path:          "/{username}/post" → "/{user_id}/post"
    path param:    username: str      → user_id: int
    command build: target_username=username                 → target_user_id=user_id
                   requester_username=current_user["username"] → requester_user_id=current_user["id"]

src/app/features/posts/_shared/user_lookup_port.py
    ADD: async def get_active_user_by_id(self, user_id: int) -> UserIdentity | None: ...
         (get_active_user_by_username retained)

src/app/features/posts/_shared/user_lookup_adapter.py
    ADD: get_active_user_by_id — select(User).where(User.id == user_id, User.is_deleted.is_(False)),
         scalar_one_or_none(), map to UserIdentity (mirrors get_active_user_by_username)
         (get_active_user_by_username retained)

src/app/features/posts/_shared/policies.py
    check_post_owner(requester_username: str, owner_username: str)
        → check_post_owner(requester_user_id: int, owner_user_id: int)
    (still raises a bare ForbiddenDomainError(); only the compared values change str → int)

src/app/features/posts/erase_post/domain/commands.py        # cross-slice, kept green
    ErasePostCommand: requester_username: str → requester_user_id: int
    (username, post_id unchanged)

src/app/features/posts/erase_post/domain/use_case.py        # cross-slice, kept green
    check_post_owner(command.requester_username, user.username)
        → check_post_owner(command.requester_user_id, user.id)

src/app/features/posts/erase_post/presentation/router.py    # cross-slice, kept green
    requester_username=current_user["username"] → requester_user_id=current_user["id"]
```

Files **not** changed:

```
src/app/features/posts/create_post/data/adapter.py             # operates on created_by_user_id (int) already
src/app/features/posts/create_post/domain/ports/create_post_port.py  # create(internal) signature unchanged
src/app/features/posts/create_post/domain/entities.py          # CreatedPost unchanged
src/app/features/posts/create_post/presentation/schemas.py     # request/response shape unchanged
src/app/features/posts/_shared/entities.py                     # UserIdentity already has id + username
src/app/features/posts/erase_post/data/adapter.py              # erase_post route/lookup NOT migrated here
src/app/features/posts/erase_post/domain/ports/erase_post_port.py
src/app/features/posts/erase_post/presentation/schemas.py
src/app/features/posts/erase_post  (route path, cache keys, get_active_user_by_username target lookup)
bootstrap/container.py, bootstrap/router.py, .importlinter     # no wiring change
```

## 5. Implementation steps

### Step 1 — Shared: add id lookup to `UserLookupPort`

**File:** `src/app/features/posts/_shared/user_lookup_port.py`

Add a second method to the Protocol, leaving the existing one in place:

```python
@runtime_checkable
class UserLookupPort(Protocol):
    async def get_active_user_by_username(self, username: str) -> UserIdentity | None: ...
    async def get_active_user_by_id(self, user_id: int) -> UserIdentity | None: ...
```

### Step 2 — Shared: implement `get_active_user_by_id` on `UserLookupAdapter`

**File:** `src/app/features/posts/_shared/user_lookup_adapter.py`

Add the method mirroring `get_active_user_by_username`, filtering on the id and the soft-delete guard:

```python
async def get_active_user_by_id(self, user_id: int) -> UserIdentity | None:
    async with self._session_factory() as session:
        result = await session.execute(select(User).where(User.id == user_id, User.is_deleted.is_(False)))
        user = result.scalar_one_or_none()
        if user is None:
            return None
        return UserIdentity.model_validate(user)
```

The existing `get_active_user_by_username` is retained unchanged. (mypy strict will confirm the adapter still satisfies the widened port.)

### Step 3 — Shared: convert `check_post_owner` to id comparison

**File:** `src/app/features/posts/_shared/policies.py`

```python
def check_post_owner(requester_user_id: int, owner_user_id: int) -> None:
    if requester_user_id != owner_user_id:
        raise ForbiddenDomainError()
```

Only the parameter names/types and the compared values change (str → int). It still raises a bare `ForbiddenDomainError()` with no message, exactly as today.

### Step 4 — Domain: retype `CreatePostCommand`

**File:** `src/app/features/posts/create_post/domain/commands.py`

```python
class CreatePostCommand(BaseModel):
    target_user_id: int
    requester_user_id: int
    title: str
    text: str
    media_url: str | None
```

`CreatePostInternalCommand` is unchanged (it already carries `created_by_user_id: int`).

### Step 5 — Domain: realign `CreatePostUseCase` to resolve-then-authorize

**File:** `src/app/features/posts/create_post/domain/use_case.py`

1. Imports: drop `ForbiddenDomainError` from the `....domain.errors` import (keep `NotFoundDomainError`); add `from ..._shared.policies import check_post_owner`.
2. Body:

```python
async def __call__(self, command: CreatePostCommand) -> CreatedPost:
    author = await self._user_lookup.get_active_user_by_id(command.target_user_id)
    if author is None:
        raise NotFoundDomainError("User not found")
    check_post_owner(command.requester_user_id, author.id)
    internal = CreatePostInternalCommand(
        created_by_user_id=author.id,
        title=command.title,
        text=command.text,
        media_url=command.media_url,
    )
    return await self._port.create(internal)
```

The previous inline username comparison and its message are removed. The 404-before-403 ordering is preserved (lookup first, ownership second). The constructor signature (`port`, `user_lookup`) is unchanged, so no DI change.

### Step 6 — Presentation: update `create_post` router

**File:** `src/app/features/posts/create_post/presentation/router.py`

1. Route path: `@router.post("/{user_id}/post", …)` (was `/{username}/post`).
2. Endpoint signature: path param `user_id: int` replaces `username: str`. `request`, `current_user`, and `use_case` parameters are unchanged. No `@cache` decorator exists today and none is added.
3. Command construction:

```python
command = CreatePostCommand(
    target_user_id=user_id,
    requester_user_id=current_user["id"],
    title=request.title,
    text=request.text,
    media_url=request.media_url,
)
```

`current_user["id"]` is available — `get_current_user` returns a dict that includes `id` (verified in `src/app/shared_dependencies.py`). Response assembly (`CreatePostResponse.model_validate(result)`) is unchanged.

### Step 7 — Cross-slice: keep `erase_post` green (route NOT migrated)

`erase_post` is the only other caller of `check_post_owner`. Converting the policy forces a contained change so the suite stays green:

1. **File:** `erase_post/domain/commands.py` — `requester_username: str` → `requester_user_id: int` (`username`, `post_id` unchanged).
2. **File:** `erase_post/domain/use_case.py` — `check_post_owner(command.requester_username, user.username)` → `check_post_owner(command.requester_user_id, user.id)`.
3. **File:** `erase_post/presentation/router.py` — pass `requester_user_id=current_user["id"]` instead of `requester_username=current_user["username"]`.

**Explicitly NOT changed in `erase_post`:** its route stays `DELETE /{username}/post/{id}`; its `get_active_user_by_username(command.username)` target lookup stays; its cache keys stay `{username}_…`. The full `erase_post` route migration remains its own later slice.

### Step 8 — Update slice 0011 integration / outside-in test URLs (acceptance-gate dependency)

Per the PRD § Further Notes, the existing `tests/features/posts/0011_create_post/` tests hit `/api/v1/{username}/post`, which no longer exists after this slice, and construct `CreatePostCommand` with username fields. Update their endpoint URLs to the integer-keyed route `/api/v1/{user_id}/post` and their command/fixtures to the id fields, or note in tests.md that they are superseded by the 0055 tests. Before and after, baseline the full suite and prove zero net-new failures (user memory `project_route_migration_downstream_tests`).

### Step 9 — Verify

```
ruff format src/app tests
ruff check src/app tests
mypy src/app
pytest
```

Plus the architecture gate (import-linter, run from `api/src` with UTF-8) and the new outside-in test:

```
pytest tests/features/posts/0055_migrate_create_post_route_username_to_user_id/migrate_create_post_route_username_to_user_id_outside_in_test.py -v
```

No `alembic` step — `Post.created_by_user_id` already exists; no model change. The slice is not done until all checks pass, including `tests/smoke/test_app_starts.py`.

## 6. Tests planned

Four levels, per `agent_docs/testing.md`, plus targeted shared-adapter coverage and one cross-slice unit-test update.

- **Use-case unit test** — `tests/features/posts/0055_migrate_create_post_route_username_to_user_id/domain/test_use_case.py`.
  Mock both `CreatePostPort` and `UserLookupPort`. Cases (per PRD § Testing Decisions):
  - Happy path (owner): lookup returns an author whose `id == requester_user_id`; assert the create port receives a `CreatePostInternalCommand` with `created_by_user_id == target_user_id`, and the use-case returns the created post.
  - User not found: lookup returns `None` → `NotFoundDomainError("User not found")`; the create port is never called.
  - Not owner: lookup returns an author whose `id != requester_user_id` → `ForbiddenDomainError`; the create port is never called.
  Prior art: `tests/features/posts/0011_create_post/` use-case unit test.

- **Shared adapter unit test** — added alongside the existing username tests in `tests/features/posts/0032_extract_user_lookup/` (the `get_active_user_by_id` method lives in `_shared`, owned by slice 0032). Real async session against the test Postgres:
  - Found: create an active user; `get_active_user_by_id(id)` returns a matching `UserIdentity`.
  - Unknown id → `None`.
  - Soft-deleted user → `None`.
  The existing `get_active_user_by_username` tests remain (the method is retained).

- **Endpoint integration test** — `tests/features/posts/0055_migrate_create_post_route_username_to_user_id/presentation/test_router.py`.
  `httpx.AsyncClient` against test Postgres. Cases (per PRD § Testing Decisions):
  - 201 owner: authenticate as the user; `POST /api/v1/{user_id}/post`; assert 201 and the response fields including default `status` (`pending_review`).
  - 403 non-owner: authenticate as user A; `POST /api/v1/{userB_id}/post`; assert 403.
  - 404 unknown user: authenticate; `POST /api/v1/{unknown_id}/post`; assert 404.
  - 401 unauthenticated: no credentials; assert 401.
  - 422 non-integer `user_id`: `POST /api/v1/not-an-integer/post`; assert 422.
  - Old route gone: `POST /api/v1/{username}/post` with a string username; assert 422/404.
  Prior art: `tests/features/posts/0011_create_post/presentation/`.

- **Outside-in test** — `tests/features/posts/0055_migrate_create_post_route_username_to_user_id/migrate_create_post_route_username_to_user_id_outside_in_test.py`.
  Full HTTP stack, real adapter, test Postgres. Acceptance gate. Scenarios per tests.md: create a user via `POST /api/v1/users/` (capture `id`), authenticate, `POST /api/v1/{user_id}/post` → 201; same user `POST /api/v1/{otherUser_id}/post` → 403; `POST /api/v1/{username}/post` with the string username → 422 (old route gone).

- **Cross-slice regression (`erase_post`)** — update the existing `erase_post` use-case unit test to drive `check_post_owner` with `requester_user_id` / `user.id` instead of usernames. The `erase_post` endpoint and outside-in tests are unchanged (its route and behaviour are unchanged). Baseline the full suite before and after; prove zero net-new failures.

**Opt-outs:** none — all four levels apply for `create_post` (per PRD § Testing Decisions). The adapter level for `create_post` itself is unchanged and needs no new test; the shared adapter change is covered under slice 0032's adapter tests.

## 7. Out of scope for this slice

- `update_post`, `erase_post` (route), `erase_db_post` — separate migration slices. Only `erase_post`'s **ownership-check call site** (command field, use-case call, router) is touched here, and only to keep the suite green; its route, cache keys, and target lookup are unchanged.
- Removing `get_active_user_by_username` from `UserLookupPort`/`UserLookupAdapter` — deferred to the final cleanup slice; retained here for the unmigrated callers.
- `get_post` (slice 0054) and `list_posts` (slice 0042) — already migrated.
- Adding a `username` field to the `create_post` response — it never had one; not added.
- Adding/altering cache on `create_post` — it has no `@cache` decorator and gains none.
- Adding a user-facing 403 message — `check_post_owner` raises a bare `ForbiddenDomainError()`; a message can be added in a follow-up without affecting this migration.
- Changing the post `id` to a UUID — frozen; the integer `id` is retained.
- No ORM model change and no Alembic migration — `Post.created_by_user_id` already exists.
- The Flutter client (separate working dir) — its calls to the old route break; handled in the Flutter spec slices.

## 8. Open questions

None. The migration mirrors slice 0054's already-implemented route mechanism and the `update_user` resolve-then-authorize flow. `get_current_user` already exposes the `id` key (verified in `src/app/shared_dependencies.py`), so no auth-layer change is required; no new `DomainError` subclass is introduced. The only cross-cutting risk — converting the shared `check_post_owner` — is contained by the simultaneous `erase_post` call-site update and the before/after suite baseline (user memory `project_route_migration_downstream_tests`).
