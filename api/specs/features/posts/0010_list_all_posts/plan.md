# 0010 · list_all_posts — Implementation plan

## 1. Header

- **Feature:** posts
- **Slice:** 0010_list_all_posts
- **PRD:** ./prd.md
- **Reference slice:** `../0009_list_posts/plan.md` — same operation shape
  (paginated GET, Query → port → Page entity, `@cache`); differs in username
  filter removal, ORDER BY, and shared-entity extraction.
- **HTTP path:** `GET /api/v1/posts`
- **STABLE files touched:**
  - `bootstrap/container.py` — add `list_all_posts_adapter` and
    `list_all_posts_use_case` providers.

## 2. Context summary

A client sends `GET /api/v1/posts` with optional `page` and `items_per_page`
query parameters. No authentication is required. The presentation router
converts the query parameters into a `ListAllPostsQuery`, passes it to
`ListAllPostsUseCase`, and returns a `ListAllPostsResponse` containing a page
of post items sorted newest-first, with pagination metadata. Each post item
includes the author's `username` resolved via a SQL JOIN on the `user` table.
Soft-deleted posts and posts from soft-deleted users are excluded. When no
posts exist, an empty paginated response is returned (HTTP 200). The response
is cached in Redis for 60 seconds; write-side invalidation is not implemented
for this endpoint. This slice also atomically extracts the `PostItem` and
`PostPage` domain entities from `list_posts/domain/entities.py` into
`features/posts/_shared/entities.py`, updating `list_posts` imports in the
same change.

## 3. API contract

**Request body:** none (GET endpoint).

**Path parameters:** none.

**Query parameters:**

| Param | Type | Default | Validation |
|---|---|---|---|
| `page` | `int` | `1` | `ge=1` |
| `items_per_page` | `int` | `10` | `ge=1`, `le=100` |

**Response body** (`ListAllPostsResponse`):

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

- `200 OK` — paginated response returned (empty `items` when no posts exist).
- `422 Unprocessable Entity` — FastAPI/Pydantic rejects invalid query params
  (e.g. `page=0`, `items_per_page=200`).
- `500` — unexpected infrastructure failure; logged by global `_catch_all` handler.

No `DomainError` subclass is raised by this use-case.

## 4. File structure

New files:

```
src/app/features/posts/_shared/
├── __init__.py
└── entities.py               # PostItem, PostPage (moved from list_posts)

src/app/features/posts/list_all_posts/
├── __init__.py
├── domain/
│   ├── __init__.py
│   ├── commands.py                    # ListAllPostsQuery
│   ├── ports/
│   │   ├── __init__.py
│   │   └── list_all_posts_port.py    # ListAllPostsPort (Protocol)
│   └── use_case.py                   # ListAllPostsUseCase
├── data/
│   ├── __init__.py
│   └── adapter.py                    # ListAllPostsAdapter(ListAllPostsPort)
└── presentation/
    ├── __init__.py
    ├── router.py                     # GET /posts
    └── schemas.py                    # PostItemSchema, ListAllPostsResponse
```

Existing files modified:

```
src/app/features/posts/list_posts/domain/entities.py   # deleted; replaced by _shared/entities.py
src/app/features/posts/list_posts/domain/ports/list_posts_port.py  # update import to _shared
src/app/features/posts/list_posts/domain/use_case.py               # update import to _shared
src/app/features/posts/list_posts/data/adapter.py                  # update import to _shared
src/app/features/posts/router.py                                   # include list_all_posts router
src/app/bootstrap/container.py                                     # add list_all_posts providers
```

No new ORM model. No Alembic migration. `adapters/db/models/post.py` (`Post`)
and `adapters/db/models/user.py` (`User`) are used as-is.

## 5. Implementation steps

### Step 1 — Extract shared entities

**Files:**
- Create `src/app/features/posts/_shared/__init__.py` (empty).
- Create `src/app/features/posts/_shared/entities.py`.

Move `PostItem` and `PostPage` verbatim from
`list_posts/domain/entities.py` into `_shared/entities.py`. Content is
identical; only the file location changes.

`PostItem` fields: `id: int`, `title: str`, `text: str`,
`media_url: str | None`, `created_at: datetime`, `created_by_user_id: int`,
`username: str`.

`PostPage` fields: `items: list[PostItem]`, `total_count: int`, `page: int`,
`items_per_page: int`.

Both are plain Pydantic `BaseModel` — stdlib and pydantic only (per layer
rules in `agent_docs/architecture.md`).

File header: `# FEATURE: posts._shared — PostItem and PostPage domain entities.`

### Step 2 — Update `list_posts` to import from `_shared`

**Files modified:**

- Delete `src/app/features/posts/list_posts/domain/entities.py`.
- In `list_posts/domain/ports/list_posts_port.py`: replace the import of
  `PostPage` from `..entities` with `from ....._shared.entities import PostPage`.
  (Five dots: ports → domain → list_posts → posts → up one more to reach
  `features/posts`; then into `_shared`.)
- In `list_posts/domain/use_case.py`: replace the import of `PostPage` from
  `.entities` with `from ..._shared.entities import PostPage`.
  (Three dots: domain → list_posts → posts; then into `_shared`.)
- In `list_posts/data/adapter.py`: replace imports of `PostItem` and `PostPage`
  from `..domain.entities` with `from ..._shared.entities import PostItem, PostPage`.
  (Three dots: data → list_posts → posts; then into `_shared`.)

All other `list_posts` files (`commands.py`, `presentation/schemas.py`,
`presentation/router.py`) do not import from `entities.py` and need no change.

Verify: `ruff check src/app && mypy src/app` must pass after this step before
continuing.

### Step 3 — Domain: Query

**File:** `src/app/features/posts/list_all_posts/domain/commands.py`

Define `ListAllPostsQuery` as a Pydantic `BaseModel` with two fields:
- `page: int` — defaults to `1`.
- `items_per_page: int` — defaults to `10`.

No username field; the adapter queries all posts. No validation constraints
here; constraints live in the presentation layer.

File header: `# FEATURE: list_all_posts — domain query.`

### Step 4 — Domain: Port

**File:** `src/app/features/posts/list_all_posts/domain/ports/list_all_posts_port.py`

Define `ListAllPostsPort` as a `@runtime_checkable` `Protocol` with a single
method:

```
async def list(self, query: ListAllPostsQuery) -> PostPage: ...
```

Import `PostPage` from `....._shared.entities` (five dots from `ports/`).
`@runtime_checkable` is mandatory per `agent_docs/architecture.md` §
Terminology: port and adapter.

File header: `# FEATURE: list_all_posts — port protocol.`

### Step 5 — Domain: Use case

**File:** `src/app/features/posts/list_all_posts/domain/use_case.py`

Define `ListAllPostsUseCase`:
- `__init__(self, port: ListAllPostsPort) -> None` — stores port as `self._port`.
- `async def __call__(self, query: ListAllPostsQuery) -> PostPage` — delegates
  entirely to `self._port.list(query)`.

No business logic, no `DomainError` raised, no `try/except`. Pure delegation
wrapper that maintains the testable boundary between presentation and data.

Import `PostPage` from `..._shared.entities` (three dots from `domain/`).

File header: `# FEATURE: list_all_posts — use case.`

### Step 6 — Data: Adapter

**File:** `src/app/features/posts/list_all_posts/data/adapter.py`

Define `ListAllPostsAdapter(ListAllPostsPort)` — explicit inheritance from the
port is mandatory per `agent_docs/architecture.md` § Terminology: port and
adapter.

Constructor: `__init__(self, session_factory: async_sessionmaker[AsyncSession])`.

`async def list(self, query: ListAllPostsQuery) -> PostPage`:

1. Open a single async session via `async with self._session_factory() as session`.
2. **Count query** — `SELECT COUNT(*) FROM post JOIN user ON
   post.created_by_user_id = user.id WHERE user.is_deleted = false AND
   post.is_deleted = false`. Built with
   `select(func.count()).select_from(Post).join(User, Post.created_by_user_id == User.id).where(User.is_deleted == False).where(Post.is_deleted == False)`.
   Fetch with `scalar_one()`.
3. Compute offset: `(query.page - 1) * query.items_per_page`.
4. **Row query** — same JOIN and WHERE conditions; project `Post` columns plus
   `User.username` using `select(Post, User.username)`. Add
   `.order_by(Post.created_at.desc()).offset(offset).limit(query.items_per_page)`.
   Fetch with `.all()`, which returns `(Post, str)` row tuples.
5. Map each `(post_row, username)` tuple to a `PostItem` instance.
6. Return `PostPage(items=..., total_count=..., page=query.page, items_per_page=query.items_per_page)`.

No `try/except` — read-only query with no business-meaningful exception path
per `agent_docs/error_handling.md` § Right shape: read-only query, no catch.
Infrastructure failures propagate to the global `_catch_all` handler.

Import `PostItem` and `PostPage` from `..._shared.entities` (three dots from
`data/`). All imports use relative paths per `agent_docs/architecture.md` §
Import conventions.

File header: `# FEATURE: list_all_posts — data adapter.`

### Step 7 — Presentation: Schemas

**File:** `src/app/features/posts/list_all_posts/presentation/schemas.py`

Define two Pydantic models with `model_config = ConfigDict(from_attributes=True)`:

`PostItemSchema`:
- `id: int`
- `title: str`
- `text: str`
- `media_url: str | None`
- `created_at: datetime`
- `created_by_user_id: int`
- `username: str`

`ListAllPostsResponse`:
- `items: list[PostItemSchema]`
- `total_count: int`
- `page: int`
- `items_per_page: int`

HTTP request/response schemas are per-slice and are not shared from `_shared/`
per `agent_docs/architecture.md` § `_shared/` rules. The structural duplication
with `list_posts/presentation/schemas.py` is intentional.

File header: `# FEATURE: list_all_posts — request/response schemas.`

### Step 8 — Presentation: Router

**File:** `src/app/features/posts/list_all_posts/presentation/router.py`

Define `router = APIRouter(tags=["posts"])`.

Define `_get_list_all_posts_use_case() -> ListAllPostsUseCase` as a local
lazy-import helper that imports `container` from `bootstrap.container` and
returns `container.list_all_posts_use_case()`. This matches the pattern used by
`list_posts/presentation/router.py`.

Endpoint `GET /posts`:
- `request: Request` — first param, required by the `@cache` decorator (per
  `agent_docs/entry_points/fastapi.md` § Caching, common mistake: forgetting
  `request: Request`).
- `use_case: Annotated[ListAllPostsUseCase, Depends(_get_list_all_posts_use_case)]`.
- `page: int = Query(default=1, ge=1)`.
- `items_per_page: int = Query(default=10, ge=1, le=100)`.
- Response model: `ListAllPostsResponse`, status code: `200`.

Apply the `@cache` decorator:

```
@router.get("/posts", response_model=ListAllPostsResponse, status_code=200)
@cache(
    key_prefix="all_posts:page_{page}:items_per_page:{items_per_page}",
    expiration=60,
)
```

No `resource_id_name` — the cache key has no user-specific component.

Endpoint body:
1. Build `ListAllPostsQuery(page=page, items_per_page=items_per_page)`.
2. Await `use_case(query)`.
3. Return `ListAllPostsResponse(items=[PostItemSchema.model_validate(p) for p in result.items], total_count=result.total_count, page=result.page, items_per_page=result.items_per_page)`.

File header: `# FEATURE: list_all_posts — HTTP router.`

### Step 9 — DI wiring: Container

**File:** `src/app/bootstrap/container.py` (STABLE — permitted addition)

Add two imports:
- `from ..features.posts.list_all_posts.data.adapter import ListAllPostsAdapter`
- `from ..features.posts.list_all_posts.domain.use_case import ListAllPostsUseCase`

Add two new providers after the existing `list_posts` providers:

```python
list_all_posts_adapter = providers.Factory(
    ListAllPostsAdapter,
    session_factory=session_factory,
)

list_all_posts_use_case = providers.Factory(
    ListAllPostsUseCase,
    port=list_all_posts_adapter,
)
```

No `wiring_config` entry needed — the router uses the lazy-import helper
pattern consistent with `list_posts`.

### Step 10 — Register router in the posts aggregator

**File:** `src/app/features/posts/router.py` (FEATURE file)

Add one import alongside the existing `list_posts_router` import:

```python
from .list_all_posts.presentation.router import router as list_all_posts_router
```

Add one include call:

```python
router.include_router(list_all_posts_router)
```

`bootstrap/router.py` is **not touched** — it already imports `posts_router`
from `features/posts/router.py` and that chain remains unchanged.

### Step 11 — Verify

```
ruff format src/app
ruff check src/app
mypy src/app
pytest
```

Outside-in test specifically:

```
pytest tests/features/posts/0010_list_all_posts/list_all_posts_outside_in_test.py -v
```

The slice is not done until all of the above pass, including the smoke test at
`tests/smoke/test_app_starts.py`.

## 6. Tests planned

- **Use-case unit test** —
  `tests/features/posts/0010_list_all_posts/domain/test_use_case.py`.
  Construct `ListAllPostsUseCase` with a mock `ListAllPostsPort`. Assert that
  `__call__` returns exactly what `port.list()` returns. One happy-path test is
  sufficient; there are no branches or `DomainError` paths.
  Prior art: `tests/features/posts/0009_list_posts/domain/test_use_case.py`.

- **Adapter unit test** —
  `tests/features/posts/0010_list_all_posts/data/test_adapter.py`.
  Run against test Postgres (real database, no mocks). Seed multiple users and
  posts. Assert:
  - Returns correct `PostPage` shape including `username` from the JOIN.
  - Posts from all non-deleted users are included.
  - `post.is_deleted=True` rows are excluded from both items and `total_count`.
  - Posts from users with `is_deleted=True` are excluded.
  - Results are ordered `created_at DESC` (newest first).
  - Pagination offset applied correctly (seed 15 posts across multiple users,
    request `page=2, items_per_page=5`, assert 5 items with correct IDs).
  - Empty `PostPage` returned when no posts exist.
  No catch path to assert — the adapter has no `try/except`.
  Prior art: `tests/features/posts/0009_list_posts/data/test_adapter.py`.

- **Endpoint integration test** —
  `tests/features/posts/0010_list_all_posts/presentation/test_router.py`.
  Use `httpx.AsyncClient` against the running app with test Postgres. Assert:
  - `GET /posts` → `200`, response matches `ListAllPostsResponse` schema.
  - Each item has `username` populated from the JOIN.
  - Results are ordered newest-first.
  - `GET /posts` with no posts seeded → `200`, `items: []`, `total_count: 0`.
  - `GET /posts?page=0` → `422`.
  - `GET /posts?items_per_page=101` → `422`.
  Prior art: `tests/features/posts/0009_list_posts/presentation/test_router.py`.

- **Outside-in test** —
  `tests/features/posts/0010_list_all_posts/list_all_posts_outside_in_test.py`.
  Full HTTP stack with real adapter, test Postgres, no mocks. Seeds multiple
  users with posts, calls `GET /posts`, asserts paginated response with correct
  `username` fields, correct `total_count`, and newest-first ordering. This is
  the acceptance gate; the slice is not done until this test is green.

**Opt-outs:** none.

## 7. Out of scope for this slice

- Write-side cache invalidation for the `all_posts:*` cache key.
- Filtering by any field other than the implicit soft-delete filter.
- Sorting options other than `created_at DESC`.
- Cursor-based pagination.
- Authentication or authorization.
- Adding `ORDER BY` to the existing `list_posts` endpoint.
- Migrating any other post handler to the vertical slice pattern.

## 8. Open questions

None — all decisions were resolved in the grill-me session preceding this plan.
