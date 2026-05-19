# 0028 · update_post — Implementation plan

## 1. Header

- **Feature:** posts
- **Slice:** 0028_update_post
- **PRD:** ./prd.md
- **Reference slice:** `../../users/0006_update_user/plan.md` — same PATCH + ownership-check shape; closest operation match in the roadmap.
- **HTTP path:** `PATCH /api/v1/{username}/post/{id}`
- **STABLE files touched:**
  - `bootstrap/container.py` — add `update_post_adapter` and `update_post_use_case` providers.
  - `bootstrap/router.py` — no change (posts are already aggregated via `features/posts/router.py`).

## 2. Context summary

An authenticated user sends `PATCH /{username}/post/{id}` with an optional partial body (`title`, `text`, `media_url`) to update their own post. The router resolves the caller's identity from the JWT token via `get_current_user`, builds an `UpdatePostCommand`, and delegates to `UpdatePostUseCase`. The use-case looks up the user by `target_username`, enforces ownership by comparing usernames, verifies the post exists, and delegates the write to `UpdatePostPort`. The adapter performs the SQL `UPDATE` (only non-`None` fields plus `updated_at`) and translates no integrity errors (a plain update of owned content cannot violate uniqueness). The response is `{"message": "Post updated"}` wrapped in `UpdatePostResponse`, following the CQRS pattern — read-back is a separate `GET` call. The old inline `patch_post` handler in `features/posts/router.py` is deleted after the new slice is in place.

## 3. API contract

**Path params:**

| Param | Type | Notes |
|---|---|---|
| `username` | `str` | Username of the post owner |
| `id` | `int` | Primary key of the post |

**Request body** (`UpdatePostRequest`):

| Field | Type | Validation |
|---|---|---|
| `title` | `str \| None` | `min_length=2`, `max_length=30`, default `None` |
| `text` | `str \| None` | `min_length=1`, `max_length=63206`, default `None` |
| `media_url` | `str \| None` | URL pattern `^(https?|ftp)://[^\s/$.?#].[^\s]*$`, default `None` |

**Response body** (`UpdatePostResponse`):

| Field | Type |
|---|---|
| `message` | `str` |

**Status codes:**

- `200 OK` — update applied; `{"message": "Post updated"}`.
- `401 Unauthorized` — token missing or invalid (from `get_current_user`).
- `403 Forbidden` — `ForbiddenDomainError`; requester does not own the target username.
- `404 Not Found` — `NotFoundDomainError`; username not found, or post not found / soft-deleted.
- `422 Unprocessable Entity` — Pydantic field-level validation failure (length, pattern).

## 4. File structure

New files:

```
src/app/features/posts/update_post/
├── __init__.py
├── domain/
│   ├── __init__.py
│   ├── commands.py              # UpdatePostCommand
│   ├── ports/
│   │   ├── __init__.py
│   │   └── update_post_port.py  # UpdatePostPort
│   └── use_case.py              # UpdatePostUseCase
├── data/
│   ├── __init__.py
│   └── adapter.py               # UpdatePostAdapter
└── presentation/
    ├── __init__.py
    ├── router.py
    └── schemas.py               # UpdatePostRequest, UpdatePostResponse
```

Files modified:

```
src/app/features/posts/_shared/entities.py   # add PostAuthor
src/app/features/posts/create_post/domain/entities.py  # replace local PostAuthor with _shared import
src/app/features/posts/router.py             # include update_post_router; remove patch_post handler
src/app/bootstrap/container.py              # add update_post_adapter, update_post_use_case providers + wiring entry
```

No new ORM model. No Alembic migration.

## 5. Implementation steps

### Step 1 — Promote `PostAuthor` to `posts/_shared/entities.py`

**File:** `src/app/features/posts/_shared/entities.py`

Header already exists: `# FEATURE: posts._shared — PostItem and PostPage domain entities.`

Add `PostAuthor(BaseModel)` with fields `id: int` and `username: str` and `model_config = ConfigDict(from_attributes=True)`. Place it before `PostItem`.

Then update `src/app/features/posts/create_post/domain/entities.py`: remove the local `PostAuthor` definition and add a relative import from `_shared`:

```python
from ..._shared.entities import PostAuthor
```

Re-export it if needed by `create_post`'s port (check all imports inside `create_post/`; replace any import of `PostAuthor` from `create_post.domain.entities` with the `_shared` source).

Verify: `ruff check` and `mypy src/app` pass. No behavior change — only import path moves.

### Step 2 — Domain: Command

**File:** `src/app/features/posts/update_post/domain/commands.py`

Header: `# FEATURE: update_post — domain command.`

```
class UpdatePostCommand(BaseModel):
    target_username: str
    requester_username: str
    post_id: int
    title: str | None = None
    text: str | None = None
    media_url: str | None = None
```

`BaseModel` only; no framework imports. All content fields are `None` by default (partial update).

### Step 3 — Domain: Port

**File:** `src/app/features/posts/update_post/domain/ports/update_post_port.py`

Header: `# FEATURE: update_post — port protocol.`

```
@runtime_checkable
class UpdatePostPort(Protocol):
    async def get_user_by_username(self, username: str) -> PostAuthor | None: ...
    async def get_post_by_id(self, post_id: int) -> PostItem | None: ...
    async def update(self, command: UpdatePostCommand) -> None: ...
```

Import `PostAuthor` from `posts/_shared/entities.py` and `PostItem` from the same module. Import `UpdatePostCommand` from `../commands`. Three methods represent the three use-case responsibilities: user lookup, post existence check, and write.

### Step 4 — Domain: Use case

**File:** `src/app/features/posts/update_post/domain/use_case.py`

Header: `# FEATURE: update_post — use case.`

`UpdatePostUseCase.__init__(self, port: UpdatePostPort)` — single dependency.

`async def __call__(self, command: UpdatePostCommand) -> None`:

1. `author = await self._port.get_user_by_username(command.target_username)` — if `None`, raise `NotFoundDomainError("User not found")`.
2. If `command.requester_username != author.username`, raise `ForbiddenDomainError()`.
3. `post = await self._port.get_post_by_id(command.post_id)` — if `None`, raise `NotFoundDomainError("Post not found")`.
4. `await self._port.update(command)`.

The use-case returns `None`; the router constructs the response. No `HTTPException`, no catching.

### Step 5 — Data: Adapter

**File:** `src/app/features/posts/update_post/data/adapter.py`

Header: `# FEATURE: update_post — data adapter.`

`class UpdatePostAdapter(UpdatePostPort)` — explicit inheritance required (per `agent_docs/architecture.md` § Terminology: port and adapter).

Constructor: `__init__(self, session_factory: async_sessionmaker[AsyncSession])`.

`get_user_by_username(username)`: `SELECT` from `User` where `username == username AND is_deleted == False`. Return `PostAuthor.model_validate(row)` if found, else `None`. No `try/except` (per `agent_docs/error_handling.md` § Right shape: read-only query, no catch).

`get_post_by_id(post_id)`: `SELECT` from `Post` where `id == post_id AND is_deleted == False`. Return `PostItem` mapped from the row if found, else `None`. No `try/except`.

`update(command)`: build a dict of non-`None` content fields from the command (`title`, `text`, `media_url`) plus `updated_at = datetime.now(UTC)`. Skip a field if its value is `None`. Execute `sqlalchemy.update(Post).where(Post.id == command.post_id).values(**update_values)`. Then `await session.commit()`. No `try/except` — a plain update of owned content cannot raise a business-meaningful integrity error; any infrastructure failure propagates to the global handler (per `agent_docs/error_handling.md`).

Import ORM models from `adapters/db/models/` via relative path; never from `features/`.

### Step 6 — Presentation: Schemas

**File:** `src/app/features/posts/update_post/presentation/schemas.py`

Header: `# FEATURE: update_post — request/response schemas.`

`UpdatePostRequest(BaseModel)`: `model_config = ConfigDict(extra="forbid")`. Fields carry the same constraints as `PostUpdate` in `features/posts/schemas.py` (independent definition, no inheritance).

`UpdatePostResponse(BaseModel)`: `model_config = ConfigDict(from_attributes=True)`. Field: `message: str`.

### Step 7 — Presentation: Router

**File:** `src/app/features/posts/update_post/presentation/router.py`

Header: `# FEATURE: update_post — HTTP router.`

```python
router = APIRouter(tags=["posts"])

@router.patch("/{username}/post/{id}", response_model=UpdatePostResponse, status_code=200)
@cache("{username}_post_cache", resource_id_name="id", pattern_to_invalidate_extra=["{username}_posts:*"])
@inject
async def update_post_endpoint(
    request: Request,
    username: str,
    id: int,
    body: UpdatePostRequest,
    current_user: Annotated[dict, Depends(get_current_user)],
    use_case: Annotated[UpdatePostUseCase, Depends(Provide[Container.update_post_use_case])],
) -> UpdatePostResponse:
```

Router body: build `UpdatePostCommand(target_username=username, requester_username=current_user["username"], post_id=id, **body.model_dump())`, await use-case, return `UpdatePostResponse(message="Post updated")`.

Decorator order: `@router.patch` → `@cache` → `@inject` (same order used in `get_post`). The `@cache` decorator requires `request: Request` as the first parameter — it is present in the signature.

Import `get_current_user` from `features/users/_shared/dependencies.py` via relative path. Import `cache` from `adapters/cache/redis_cache` via relative path.

No `try/except`. No business logic. No direct DB access.

### Step 8 — DI wiring: Container

**File:** `src/app/bootstrap/container.py` (STABLE — minimal addition only)

Add two providers after the last existing posts use-case provider (`get_post_use_case`):

```python
update_post_adapter = providers.Factory(
    UpdatePostAdapter,
    session_factory=session_factory,
)

update_post_use_case = providers.Factory(
    UpdatePostUseCase,
    port=update_post_adapter,
)
```

Add the corresponding imports at the top of the file.

Add the router module to `wiring_config.modules`:

```python
f"{_app_pkg}.features.posts.update_post.presentation.router",
```

### Step 9 — Router registration

**File:** `src/app/features/posts/router.py`

Add the import:
```python
from .update_post.presentation.router import router as update_post_router
```

Add `router.include_router(update_post_router)` alongside the other sub-routers.

Remove the `@router.patch("/{username}/post/{id}")` inline handler (lines 35–57) and its now-exclusive imports (`PostUpdate` can stay if still used by the remaining inline handlers; `PostRead` similarly — verify before removing).

`bootstrap/router.py` is **not touched** — it already aggregates `posts_router` via `features/posts/router.py`.

### Step 10 — Verify

```
ruff format src/app
ruff check src/app
mypy src/app
pytest
```

Outside-in test specifically:

```
pytest tests/features/posts/0028_update_post/update_post_outside_in_test.py -v
```

The slice is not done until all four commands pass, including the smoke test (`tests/smoke/test_app_starts.py`).

## 6. Tests planned

- **Use-case unit test** — `tests/features/posts/0028_update_post/domain/test_use_case.py`.
  Mock `UpdatePostPort`. Assert:
  - `get_user_by_username` returns `None` → raises `NotFoundDomainError("User not found")`.
  - `get_user_by_username` returns author with a different username than `requester_username` → raises `ForbiddenDomainError`.
  - `get_post_by_id` returns `None` → raises `NotFoundDomainError("Post not found")`.
  - All checks pass → `port.update` is called and returns without error.
  - Prior art: `tests/features/posts/0011_create_post/domain/test_use_case.py`.

- **Adapter unit test** — `tests/features/posts/0028_update_post/data/test_adapter.py`.
  Use a real async session against the test Postgres database (no mocks).
  - `get_user_by_username`: returns `PostAuthor` for an existing active user; `None` for soft-deleted; `None` for unknown username.
  - `get_post_by_id`: returns `PostItem` for an existing active post; `None` for soft-deleted; `None` for unknown id.
  - `update`: seed a user and post, call adapter, assert the DB row reflects updated fields and `updated_at` is set.
  - Prior art: `tests/features/posts/0011_create_post/data/test_adapter.py`.

- **Endpoint integration test** — `tests/features/posts/0028_update_post/presentation/test_router.py`.
  `httpx.AsyncClient` against the running app with test Postgres. Assert:
  - Valid token, owns the user, valid partial body → `200 {"message": "Post updated"}`.
  - Valid token, does not own the username → `403`.
  - Non-existent `{username}` in path → `404`.
  - Non-existent or soft-deleted post `{id}` → `404`.
  - Missing / invalid token → `401`.
  - Body field violates constraint (title too short) → `422`.
  - Prior art: `tests/features/posts/0011_create_post/presentation/test_router.py`.

- **Outside-in test** — `tests/features/posts/0028_update_post/update_post_outside_in_test.py`.
  Full HTTP stack, real adapter, test Postgres. Acceptance gate: authenticate as a user, PATCH their post with a new title, assert `200 {"message": "Post updated"}`, then GET the post and assert the title changed.

**Opt-outs:** none.

## 7. Out of scope for this slice

- Migrating `erase_post` or `erase_db_post` to the vertical slice pattern.
- Returning the updated post in the PATCH response — CQRS pattern; read-back is via `GET`.
- Changing the post `status` field via this endpoint — status transitions belong to the moderation flow.
- Rate limiting on this endpoint.
- Removing `PostUpdate` or `PostUpdateInternal` from `features/posts/schemas.py` — still referenced by `posts/repository.py`.

## 8. Open questions

None. All design decisions were resolved in the grill-me session and PRD.
