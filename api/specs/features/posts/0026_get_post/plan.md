# 0026 · get_post — Implementation plan

## 1. Header

- **Feature:** posts
- **Slice:** 0026_get_post
- **PRD:** ./prd.md
- **Reference slice (shape match):** `../../users/0004_get_user_by_username/plan.md` —
  same single-entity GET-by-key shape; differs in JOIN query, optional auth,
  and access-control logic in the use case.
- **HTTP path:** `GET /api/v1/{username}/post/{id}`
- **STABLE files touched:**
  - `bootstrap/container.py` — add `get_post_adapter` and `get_post_use_case`
    providers (permitted modification per `agent_docs/stable_vs_feature.md` §
    The one exception).
  - `bootstrap/router.py` — no change needed; `features/posts/router.py` is the
    aggregator already registered there.

## 2. Context summary

A client sends `GET /api/v1/{username}/post/{id}`. This slice extracts the
existing `read_post` flat function from `features/posts/router.py` into a proper
vertical slice. The presentation router resolves the optional caller via
`get_optional_user`, computes a privilege flag from `is_moderator` /
`is_superuser`, constructs a `GetPostQuery`, and awaits `GetPostUseCase`. The
use case applies two-stage access control: (a) if the adapter returns `None`, it
raises `NotFoundDomainError`; (b) if the post status is not `approved`, it checks
whether the requester is the author or a privileged user, raising
`NotFoundDomainError` on failure. The adapter issues a single `SELECT … JOIN`
on `Post` and `User` with no status filter; it returns a `PostItem` (from
`posts/_shared/entities.py`) with `username` populated from the joined row, or
`None` when no matching row exists. The response gains `username` and `status`
fields compared to the legacy `PostRead`. The `@cache` key contract
`{username}_post_cache` / `resource_id_name="id"` is preserved unchanged so
that `patch_post` and `erase_post` invalidation continues to work.

## 3. API contract

**Request body:** none (GET endpoint).

**Path parameters:**

| Param | Type | Validation |
|---|---|---|
| `username` | `str` | required; identifies resource owner |
| `id` | `int` | required; post primary key |

**Response body** (`GetPostResponse`):

| Field | Type | Source |
|---|---|---|
| `id` | `int` | `post.id` |
| `title` | `str` | `post.title` |
| `text` | `str` | `post.text` |
| `media_url` | `str \| None` | `post.media_url` |
| `created_at` | `datetime` | `post.created_at` |
| `created_by_user_id` | `int` | `post.created_by_user_id` |
| `username` | `str` | `user.username` (via JOIN) |
| `status` | `str` | `post.status` |
| `post_uuid` | `uuid.UUID` | `post.uuid` |

**Status codes:**

- `200 OK` — post found, visible to caller; body is `GetPostResponse`.
- `404 Not Found` — post/user does not exist, is soft-deleted, or exists but is
  not `approved` and the caller has no bypass right; raised as
  `NotFoundDomainError("Post not found")`, translated by the global `DomainError`
  handler.
- `500 Internal Server Error` — unexpected adapter/infrastructure failure; caught
  and logged by global `_catch_all` handler.

## 4. File structure

New files:

```
src/app/features/posts/get_post/
├── __init__.py
├── domain/
│   ├── __init__.py
│   ├── commands.py               # GetPostQuery
│   ├── ports/
│   │   ├── __init__.py
│   │   └── get_post_port.py      # GetPostPort (Protocol)
│   └── use_case.py               # GetPostUseCase
├── data/
│   ├── __init__.py
│   └── adapter.py                # GetPostAdapter(GetPostPort)
└── presentation/
    ├── __init__.py
    ├── router.py                 # GET /{username}/post/{id}
    └── schemas.py                # GetPostResponse
```

No new ORM model. No Alembic migration. `adapters/db/models/post.py` (`Post`) and
`adapters/db/models/user.py` (`User`) are used as-is.

`PostItem` from `features/posts/_shared/entities.py` is reused as the use-case
return type and as the adapter return type. No new entity is introduced.

Existing files modified:

```
src/app/features/posts/router.py    # remove read_post; add include_router(get_post_router)
src/app/bootstrap/container.py      # add get_post_adapter, get_post_use_case providers
```

`bootstrap/router.py` is **not touched** — it already includes
`features/posts/router.py` and the chain is unchanged.

## 5. Implementation steps

### Step 1 — Domain: Query

**File:** `src/app/features/posts/get_post/domain/commands.py`

Define `GetPostQuery` as a Pydantic `BaseModel` with four fields:

- `username: str` — path parameter; identifies the resource owner.
- `post_id: int` — path parameter; post primary key.
- `requester_username: str | None = None` — `None` for unauthenticated callers;
  caller's username otherwise. Used by the use case for the resource-based check.
- `requester_is_privileged: bool = False` — `True` when the caller is a moderator
  or superuser. Computed by the router; separates role-based from resource-based
  policy.

No field-level Pydantic constraints here; validation lives in the presentation
layer. The domain command assumes valid input.

File header: `# FEATURE: get_post — domain query.`

### Step 2 — Domain: Port

**File:** `src/app/features/posts/get_post/domain/ports/get_post_port.py`

Define `GetPostPort` as a `@runtime_checkable` `Protocol` with a single method:

```python
async def get(self, query: GetPostQuery) -> PostItem | None: ...
```

`@runtime_checkable` is mandatory (per `agent_docs/architecture.md` §
Terminology: port and adapter). The `None` return means the user or post does not
exist; the use case decides the domain semantics. The port performs no status
filtering.

Relative imports: `typing.Protocol`, `typing.runtime_checkable`, `..commands`,
and `...._shared.entities.PostItem`.

File header: `# FEATURE: get_post — port protocol.`

### Step 3 — Domain: Use case

**File:** `src/app/features/posts/get_post/domain/use_case.py`

Define `GetPostUseCase`:

- `__init__(self, port: GetPostPort) -> None` — stores port as `self._port`.
- `async def __call__(self, query: GetPostQuery) -> PostItem`:
  1. `post = await self._port.get(query)`.
  2. If `post is None`: raise `NotFoundDomainError("Post not found")`.
  3. If `post.status != "approved"`:
     - If `query.requester_username == query.username` → author bypass, continue.
     - Elif `query.requester_is_privileged` → moderator/superuser bypass, continue.
     - Else: raise `NotFoundDomainError("Post not found")`.
  4. Return `post`.

No `try/except`. `NotFoundDomainError` is re-used for both "does not exist" and
"exists but not visible" to prevent status enumeration (per PRD § Implementation
Decisions). Raises only `DomainError` subclasses; never `HTTPException` (per
CLAUDE.md rule 1 and `agent_docs/error_handling.md` § Use-case: raises, does
not catch).

Relative import of `NotFoundDomainError` via `......domain.errors`.

File header: `# FEATURE: get_post — use case.`

### Step 4 — Data: Adapter

**File:** `src/app/features/posts/get_post/data/adapter.py`

Define `GetPostAdapter(GetPostPort)` — explicit inheritance from the port is
mandatory (per `agent_docs/architecture.md` § Terminology: port and adapter).

Constructor: `__init__(self, session_factory: async_sessionmaker[AsyncSession])`.

`async def get(self, query: GetPostQuery) -> PostItem | None`:

1. Open session via `async with self._session_factory() as session`.
2. Execute:
   ```python
   select(Post, User.username)
   .join(User, Post.created_by_user_id == User.id)
   .where(User.username == query.username)
   .where(Post.id == query.post_id)
   .where(User.is_deleted == False)   # noqa: E712
   .where(Post.is_deleted == False)   # noqa: E712
   ```
   Fetch with `.one_or_none()`.
3. If `None`, return `None`.
4. Map result to `PostItem`:
   ```python
   PostItem(
       id=post.id,
       title=post.title,
       text=post.text,
       media_url=post.media_url,
       created_at=post.created_at,
       created_by_user_id=post.created_by_user_id,
       username=username,
       status=post.status,
       post_uuid=post.uuid,
   )
   ```
   Note: ORM column is `Post.uuid`; `PostItem` field is `post_uuid` (matches
   `_shared/entities.py`). No status filter — that decision belongs to the
   use case.
5. Return `PostItem`.

No `try/except` — read-only query has no business-meaningful exception to translate
(per `agent_docs/error_handling.md` § Right shape: read-only query, no catch).
Infrastructure failures propagate to the global `_catch_all` handler.

File header: `# FEATURE: get_post — data adapter.`

### Step 5 — Presentation: Schemas

**File:** `src/app/features/posts/get_post/presentation/schemas.py`

Define `GetPostResponse` as a Pydantic `BaseModel` with
`model_config = ConfigDict(from_attributes=True)`:

- `id: int`
- `title: str`
- `text: str`
- `media_url: str | None`
- `created_at: datetime`
- `created_by_user_id: int`
- `username: str`
- `status: str`
- `post_uuid: uuid.UUID`

No request schema — all inputs are path parameters resolved in the router.

File header: `# FEATURE: get_post — request/response schemas.`

### Step 6 — Presentation: Router

**File:** `src/app/features/posts/get_post/presentation/router.py`

Define `router = APIRouter(tags=["posts"])`.

Define the lazy-import helper (matching the pattern of all existing post slice
routers):

```python
def _get_get_post_use_case() -> GetPostUseCase:
    from .....bootstrap.container import container  # noqa: PLC0415
    return container.get_post_use_case()
```

Endpoint `GET /{username}/post/{id}`:

- `request: Request` — first param, required by `@cache` decorator.
- `username: str` — path param.
- `id: int` — path param (kept as `id` to match existing URL and cache key).
- `optional_user: Annotated[dict | None, Depends(get_optional_user)]`.
- `use_case: Annotated[GetPostUseCase, Depends(_get_get_post_use_case)]`.

Endpoint body:
1. Compute `requester_is_privileged = bool(optional_user and (optional_user["is_superuser"] or optional_user["is_moderator"]))`.
2. Compute `requester_username = optional_user["username"] if optional_user else None`.
3. Build `GetPostQuery(username=username, post_id=id, requester_username=requester_username, requester_is_privileged=requester_is_privileged)`.
4. `post = await use_case(query)`.
5. Return `GetPostResponse.model_validate(post)`.

Apply `@cache` decorator to preserve the existing cache key contract:

```python
@router.get("/{username}/post/{id}", response_model=GetPostResponse, status_code=200)
@cache(key_prefix="{username}_post_cache", resource_id_name="id")
async def get_post_endpoint(request: Request, username: str, id: int, ...) -> GetPostResponse:
```

This is intentional: `patch_post` and `erase_post` in the flat `router.py`
invalidate `{username}_post_cache` keyed on `id`; changing the key would break
their invalidation without touching those endpoints (per PRD § Implementation
Decisions).

Import `get_optional_user` from `shared_dependencies` via five-dot relative path.
Import `cache` from `adapters.cache.redis_cache`.

File header: `# FEATURE: get_post — HTTP router.`

### Step 7 — DI wiring: Container

**File:** `src/app/bootstrap/container.py` (STABLE — permitted modification)

Add two imports alongside the other posts-slice imports:

```python
from ..features.posts.get_post.data.adapter import GetPostAdapter
from ..features.posts.get_post.domain.use_case import GetPostUseCase
```

Add two providers after the existing posts-slice providers:

```python
get_post_adapter = providers.Factory(
    GetPostAdapter,
    session_factory=session_factory,
)

get_post_use_case = providers.Factory(
    GetPostUseCase,
    port=get_post_adapter,
)
```

No `wiring_config` entry needed — the router uses the lazy-import pattern.

### Step 8 — Flat router cleanup

**File:** `src/app/features/posts/router.py` (FEATURE file)

Remove:
- The `read_post` endpoint function and its `@router.get` / `@cache` decorators.
- Imports no longer used after the removal: check whether `Request`, `Any`,
  `async_get_db`, `AsyncSession`, `UserRead`, `crud_users`, `PostRead` are still
  needed by `patch_post`, `erase_post`, or `erase_db_post` before removing.

Add alongside the other slice router imports:

```python
from .get_post.presentation.router import router as get_post_router
```

Add after the existing `include_router` calls:

```python
router.include_router(get_post_router)
```

`bootstrap/router.py` is **not touched**.

### Step 9 — Verify

```
ruff format src/app
ruff check src/app
mypy src/app
pytest
```

Outside-in test specifically:

```
pytest tests/features/posts/0026_get_post/get_post_outside_in_test.py -v
```

The slice is not done until all of the above pass, including the smoke test at
`tests/smoke/test_app_starts.py`.

## 6. Tests planned

- **Use-case unit test** —
  `tests/features/posts/0026_get_post/domain/test_use_case.py`.
  Construct `GetPostUseCase` with a mock `GetPostPort`. Assert all branches:
  - Port returns `None` → `NotFoundDomainError` raised.
  - Port returns `approved` post, no auth → post returned.
  - Port returns `pending_review` post, requester is author → post returned.
  - Port returns `pending_review` post, requester is privileged → post returned.
  - Port returns `pending_review` post, requester is neither author nor privileged
    → `NotFoundDomainError` raised.
  - Port returns `changes_requested` post, same matrix (author / privileged /
    neither).
  Prior art: `tests/features/posts/0017_moderate_post/domain/test_use_case.py`,
  `tests/features/posts/0018_revise_post/domain/test_use_case.py`.

- **Adapter unit test** —
  `tests/features/posts/0026_get_post/data/test_adapter.py`.
  Run against test Postgres (real database, per PRD § Testing Decisions). Seed
  rows and assert:
  - User and post both exist, not deleted → `PostItem` returned with all fields
    including `username` and `post_uuid`.
  - User does not exist → `None` returned.
  - Post does not exist for that user → `None` returned.
  - Post exists but `is_deleted = True` → `None` returned.
  - Post with `status = pending_review` → `PostItem` returned (adapter does not
    filter by status).
  No catch path to assert — the adapter has no `try/except`.
  Prior art: `tests/features/posts/0009_list_posts/data/test_adapter.py`.

- **Endpoint integration test** —
  `tests/features/posts/0026_get_post/presentation/test_router.py`.
  `httpx.AsyncClient` against the running app with test Postgres. Assert:
  - Approved post, unauthenticated → HTTP 200, body includes `username` and
    `status`.
  - Pending post, unauthenticated → HTTP 404.
  - Pending post, author authenticated → HTTP 200.
  - Pending post, moderator authenticated → HTTP 200.
  - Pending post, superuser authenticated → HTTP 200.
  - Pending post, different authenticated user → HTTP 404.
  - Unknown username → HTTP 404.
  - Unknown post id → HTTP 404.
  - Post id belongs to different user → HTTP 404.
  Prior art: `tests/features/posts/0009_list_posts/presentation/test_router.py`.

- **Outside-in test** —
  `tests/features/posts/0026_get_post/get_post_outside_in_test.py`.
  Full HTTP stack with real adapter and test Postgres, no mocks. Covers:
  1. Register `alice` and `bob`; promote `carol` to moderator.
  2. Alice creates a post (defaults to `pending_review`).
  3. Unauthenticated `GET /users/alice/post/{id}` → HTTP 404.
  4. Authenticated as `bob` → HTTP 404.
  5. Authenticated as `alice` (author) → HTTP 200, `status = "pending_review"`,
     `username = "alice"`.
  6. Authenticated as `carol` (moderator) → HTTP 200.
  7. Directly set `post.status = "approved"` in DB via test session.
  8. Unauthenticated `GET /users/alice/post/{id}` → HTTP 200, `status = "approved"`.
  9. `GET /users/unknown/post/{id}` → HTTP 404.
  10. `GET /users/alice/post/99999` → HTTP 404.
  This test is the acceptance gate; the slice is not done until it is green and
  all pre-existing outside-in tests remain green.

**Opt-outs:** none.

## 7. Out of scope for this slice

- Refactoring `patch_post`, `erase_post`, and `erase_db_post` — these remain as
  flat functions in `posts/router.py` and are separate future slices.
- Cache key rotation or invalidation strategy changes — the existing key contract
  is preserved deliberately.
- Soft-delete visibility rules — any post with `is_deleted = True` is treated as
  non-existent (404) for all callers.
- Rate-limit configuration — handled cross-cuttingly by the existing middleware.
- Adding pagination or filtering — this endpoint returns exactly one post.

## 8. Open questions

None — all decisions are resolved in the PRD.
