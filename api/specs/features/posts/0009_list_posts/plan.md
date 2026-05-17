# 0009 · list_posts — Implementation plan

## 1. Header

- **Feature:** posts
- **Slice:** 0009_list_posts
- **PRD:** ./prd.md
- **Reference slice:** `../../users/0003_list_users/plan.md` — same operation shape
  (paginated GET, Query → port → Page entity); differs in JOIN query and `@cache`.
- **HTTP path:** `GET /api/v1/{username}/posts`
- **STABLE files touched:**
  - `bootstrap/container.py` — add `list_posts_adapter` and `list_posts_use_case`
    providers; approved in grill-me session.

## 2. Context summary

A client sends `GET /api/v1/{username}/posts` with optional `page` and
`items_per_page` query parameters. The presentation router converts the path and
query parameters into a `ListPostsQuery`, passes it to `ListPostsUseCase`, and
returns a `ListPostsResponse` containing a page of post items with pagination
metadata. Each post item includes the author's `username` resolved via a single
SQL JOIN between the `post` and `user` tables. An unknown or non-existent username
returns an empty paginated response (HTTP 200), not a 404. The response is cached
in Redis for 60 seconds using the existing `@cache` decorator, which stays in the
presentation layer. This slice replaces only the `read_posts` handler inside
`features/posts/router.py`, converting that file from a flat handler file into a
slice aggregator. The other five post handlers remain in `posts/router.py`
unchanged until future slices migrate them.

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

**Response body** (`ListPostsResponse`):

| Field | Type |
|---|---|
| `items` | `list[PostItemSchema]` |
| `total_count` | `int` |
| `page` | `int` |
| `items_per_page` | `int` |

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

**Status codes:**

- `200 OK` — paginated response returned (empty `items` if username not found or
  user has no posts).
- `422 Unprocessable Entity` — FastAPI/Pydantic rejects invalid query params
  (e.g. `page=0`).
- `500` — unexpected infrastructure failure; logged by global `_catch_all` handler.

No `DomainError` subclass is raised by this use case.

## 4. File structure

New files:

```
src/app/features/posts/list_posts/
├── __init__.py
├── domain/
│   ├── __init__.py
│   ├── commands.py               # ListPostsQuery
│   ├── entities.py               # PostItem, PostPage
│   ├── ports/
│   │   ├── __init__.py
│   │   └── list_posts_port.py    # ListPostsPort (Protocol)
│   └── use_case.py               # ListPostsUseCase
├── data/
│   ├── __init__.py
│   └── adapter.py                # ListPostsAdapter(ListPostsPort)
└── presentation/
    ├── __init__.py
    ├── router.py                 # GET /{username}/posts
    └── schemas.py                # PostItemSchema, ListPostsResponse
```

No new ORM model. No Alembic migration. `adapters/db/models/post.py` (`Post`) and
`adapters/db/models/user.py` (`User`) are used as-is by the adapter.

Existing files modified:

```
src/app/features/posts/router.py   # converted from flat-handler to aggregator
src/app/bootstrap/container.py     # add list_posts_adapter, list_posts_use_case
```

`bootstrap/router.py` is **not touched** — it already imports `posts_router` from
`features/posts/router.py` and the chain remains unchanged.

## 5. Implementation steps

### Step 1 — Domain: Query

**File:** `src/app/features/posts/list_posts/domain/commands.py`

Define `ListPostsQuery` as a Pydantic `BaseModel` with three fields:
- `username: str` — the author's username; used by the adapter to join with the
  `user` table.
- `page: int` — defaults to `1`.
- `items_per_page: int` — defaults to `10`.

No validation constraints here; constraints (`ge=1`, `le=100`) live in the
presentation layer. The domain command assumes valid input.

File header: `# FEATURE: list_posts — domain query.`

### Step 2 — Domain: Entities

**File:** `src/app/features/posts/list_posts/domain/entities.py`

Define two Pydantic `BaseModel` classes. `domain/` imports only stdlib and
pydantic — no SQLAlchemy, no FastAPI.

`PostItem`:
- `id: int`
- `title: str`
- `text: str`
- `media_url: str | None`
- `created_at: datetime` (import `datetime` from stdlib)
- `created_by_user_id: int`
- `username: str`

`PostPage`:
- `items: list[PostItem]`
- `total_count: int`
- `page: int`
- `items_per_page: int`

File header: `# FEATURE: list_posts — domain entities.`

### Step 3 — Domain: Port

**File:** `src/app/features/posts/list_posts/domain/ports/list_posts_port.py`

Define `ListPostsPort` as a `@runtime_checkable` `Protocol` with a single method:

```
async def list(self, query: ListPostsQuery) -> PostPage: ...
```

`@runtime_checkable` is mandatory (per `agent_docs/architecture.md` §
Terminology: port and adapter). One method per port.

Imports: `typing.Protocol`, `typing.runtime_checkable`, relative imports to
`domain/commands.py` and `domain/entities.py`.

File header: `# FEATURE: list_posts — port protocol.`

### Step 4 — Domain: Use case

**File:** `src/app/features/posts/list_posts/domain/use_case.py`

Define `ListPostsUseCase`:
- `__init__(self, port: ListPostsPort) -> None` — stores port as `self._port`.
- `async def __call__(self, query: ListPostsQuery) -> PostPage` — delegates
  entirely to `self._port.list(query)`.

No business logic, no `DomainError` raised, no `try/except`. The delegation
wrapper is intentional: it preserves the testable boundary and DI contract
between the presentation layer and the data layer.

File header: `# FEATURE: list_posts — use case.`

### Step 5 — Data: Adapter

**File:** `src/app/features/posts/list_posts/data/adapter.py`

Define `ListPostsAdapter(ListPostsPort)` — explicit inheritance from the port is
mandatory (per `agent_docs/architecture.md` § Terminology: port and adapter).

Constructor: `__init__(self, session_factory: async_sessionmaker[AsyncSession])`.

`async def list(self, query: ListPostsQuery) -> PostPage`:

1. Open a single async session via `async with self._session_factory() as session`.
2. **Count query** — `SELECT COUNT(*) FROM post JOIN user ON post.created_by_user_id = user.id WHERE user.username = :username AND user.is_deleted = false AND post.is_deleted = false`. Built with `select(func.count()).select_from(Post).join(User, Post.created_by_user_id == User.id).where(...)`. Fetch with `scalar_one()`.
3. Compute offset: `(query.page - 1) * query.items_per_page`.
4. **Row query** — same JOIN and WHERE conditions; project `Post` columns plus `User.username` column using `select(Post, User.username)`. Add `.offset(offset).limit(query.items_per_page)`. Fetch with `.all()`, which returns `(Post, str)` row tuples.
5. Map each `(post_row, username)` tuple to a `PostItem` instance.
6. Return `PostPage(items=..., total_count=..., page=query.page, items_per_page=query.items_per_page)`.

No `try/except` — this is a read-only query with no business-meaningful exception
path (per `agent_docs/error_handling.md` § Right shape: read-only query, no
catch). Infrastructure failures propagate to the global `_catch_all` handler.

Imports: `sqlalchemy` (`func`, `select`), `sqlalchemy.ext.asyncio` types,
`adapters/db/models/post.Post`, `adapters/db/models/user.User`, relative imports
to domain types and port. All imports use relative paths (per `agent_docs/architecture.md`
§ Import conventions).

File header: `# FEATURE: list_posts — data adapter.`

### Step 6 — Presentation: Schemas

**File:** `src/app/features/posts/list_posts/presentation/schemas.py`

Define two Pydantic models with `model_config = ConfigDict(from_attributes=True)`:

`PostItemSchema`:
- `id: int`
- `title: str`
- `text: str`
- `media_url: str | None`
- `created_at: datetime`
- `created_by_user_id: int`
- `username: str`

`ListPostsResponse`:
- `items: list[PostItemSchema]`
- `total_count: int`
- `page: int`
- `items_per_page: int`

`PostItemSchema` mirrors the domain `PostItem` but lives in the presentation layer
as the HTTP contract type. `from_attributes=True` enables `model_validate` from
domain entity instances.

File header: `# FEATURE: list_posts — request/response schemas.`

### Step 7 — Presentation: Router

**File:** `src/app/features/posts/list_posts/presentation/router.py`

Define `router = APIRouter(tags=["posts"])`.

Define `_get_list_posts_use_case() -> ListPostsUseCase` as a local helper that
does a deferred import of `container` from `bootstrap.container` and returns
`container.list_posts_use_case()`. This matches the lazy-import pattern used by
`list_users/presentation/router.py` in the current codebase.

Endpoint `GET /{username}/posts`:
- `request: Request` — first param, required by the `@cache` decorator.
- `username: str` — path parameter.
- `use_case: Annotated[ListPostsUseCase, Depends(_get_list_posts_use_case)]`.
- `page: int = Query(default=1, ge=1)`.
- `items_per_page: int = Query(default=10, ge=1, le=100)`.
- Response model: `ListPostsResponse`, status code: `200`.

Apply the `@cache` decorator **above** the `@router.get` decorator (i.e., written
second, applied first per Python decorator ordering):

```
@router.get("/{username}/posts", response_model=ListPostsResponse, status_code=200)
@cache(
    key_prefix="{username}_posts:page_{page}:items_per_page:{items_per_page}",
    resource_id_name="username",
    expiration=60,
)
```

The cache key prefix is identical to the one used in the old `read_posts` handler
in `posts/router.py`. This preserves compatibility with the existing cache
invalidation patterns in `patch_post` and `erase_post` (which target
`{username}_posts:*`).

Endpoint body:
1. Build `ListPostsQuery(username=username, page=page, items_per_page=items_per_page)`.
2. Await `use_case(query)`.
3. Return `ListPostsResponse(items=[PostItemSchema.model_validate(p) for p in result.items], total_count=result.total_count, page=result.page, items_per_page=result.items_per_page)`.

Imports use relative paths. Import `cache` from `adapters/cache/redis_cache`.

File header: `# FEATURE: list_posts — HTTP router.`

### Step 8 — DI wiring: Container

**File:** `src/app/bootstrap/container.py` (STABLE — approved for modification)

Add two imports at the top of the file:
- `from ..features.posts.list_posts.data.adapter import ListPostsAdapter`
- `from ..features.posts.list_posts.domain.use_case import ListPostsUseCase`

Add two new providers inside the `Container` class after the existing user-slice
providers:

```python
list_posts_adapter = providers.Factory(
    ListPostsAdapter,
    session_factory=session_factory,
)

list_posts_use_case = providers.Factory(
    ListPostsUseCase,
    port=list_posts_adapter,
)
```

No `wiring_config` is needed: the router uses the local lazy-import helper pattern
(`_get_list_posts_use_case`) consistent with all existing slice routers in the
codebase.

### Step 9 — Convert `features/posts/router.py` to aggregator

**File:** `src/app/features/posts/router.py` (FEATURE file)

Remove the `read_posts` handler and its associated imports that are no longer used:
- `PaginatedListResponse`, `compute_offset`, `paginated_response` from `fastcrud`
  (check whether any other remaining handler uses them before removing).
- The `crud_users` import and `UserRead` import (check remaining handlers first).

Add at the top of the file, alongside the other router imports:

```python
from .list_posts.presentation.router import router as list_posts_router
```

Add inside the module, after the existing `router` definition:

```python
router.include_router(list_posts_router)
```

The five remaining handlers (`write_post`, `read_post`, `patch_post`, `erase_post`,
`erase_db_post`) stay in place. `bootstrap/router.py` is **not touched**.

### Step 10 — Verify

```
ruff format src/app
ruff check src/app
mypy src/app
pytest
```

Outside-in test specifically:

```
pytest tests/features/posts/0009_list_posts/list_posts_outside_in_test.py -v
```

The slice is not done until all of the above pass, including the smoke test at
`tests/smoke/test_app_starts.py`.

## 6. Tests planned

- **Use-case unit test** —
  `tests/features/posts/0009_list_posts/domain/test_use_case.py`.
  Construct `ListPostsUseCase` with a mock `ListPostsPort`. Assert that `__call__`
  returns exactly what `port.list()` returns. One happy-path test is sufficient;
  there are no branches or `DomainError` paths.
  Prior art: `tests/features/users/0003_list_users/domain/test_use_case.py`.

- **Adapter unit test** —
  `tests/features/posts/0009_list_posts/data/test_adapter.py`.
  Run against test Postgres (real database, no mocks). Seed users and posts rows.
  Assert:
  - Returns correct `PostPage` shape including `username` from the JOIN.
  - Posts from a different user are not included.
  - `post.is_deleted=True` rows are excluded from both items and total_count.
  - Empty `PostPage` returned for a username with no posts.
  - Empty `PostPage` returned for a username that does not exist.
  - Pagination offset applied correctly (seed 15 posts, request `page=2 /
    items_per_page=5`, assert 5 items with correct offset).
  No catch path to assert — the adapter has no `try/except`.
  Prior art: `tests/features/users/0003_list_users/data/test_adapter.py`.

- **Endpoint integration test** —
  `tests/features/posts/0009_list_posts/presentation/test_router.py`.
  Use `httpx.AsyncClient` against the running app with test Postgres. Assert:
  - `GET /{username}/posts` → `200`, response matches `ListPostsResponse` schema.
  - Each item has `username` populated from the JOIN.
  - `GET /{username}/posts` for non-existent username → `200`, `items: []`,
    `total_count: 0`.
  - `GET /{username}/posts?page=0` → `422` (Pydantic `ge=1` fails).
  - Cache: a second identical request within 60 s returns a cached response.
  Prior art: `tests/features/users/0003_list_users/presentation/test_router.py`.

- **Outside-in test** —
  `tests/features/posts/0009_list_posts/list_posts_outside_in_test.py`.
  Full HTTP stack with real adapter, test Postgres, no mocks. Covers the happy
  path: seed user and posts, call endpoint, assert paginated response with correct
  `username` field in each item. This is the acceptance gate; the slice is not
  done until this test is green.

**Opt-outs:** none.

## 7. Out of scope for this slice

- Migrating any other post handler (`write_post`, `read_post`, `patch_post`,
  `erase_post`, `erase_db_post`) to the vertical slice pattern.
- Returning HTTP 404 for non-existent usernames on this endpoint.
- Adding filtering, sorting, or search.
- Cursor-based pagination.
- Authentication or authorization on `GET /{username}/posts`.

## 8. Open questions

None — all decisions were resolved in the grill-me session preceding this plan.
The container modification, JOIN strategy, empty-result behavior, cache placement,
and scope were all explicitly agreed.
