# 0019 · list_pending_posts — Implementation plan

## 1. Header

- **Feature:** posts
- **Slice:** 0019_list_pending_posts
- **PRD:** ./prd.md
- **Reference slices:**
  - `../0010_list_all_posts/plan.md` — same operation shape: paginated GET with
    Query → port → Page entity, two-query adapter strategy, no caching.
  - `../0017_moderate_post/plan.md` — same auth pattern: `get_current_moderator_or_superuser`
    dependency, `requester_is_privileged` defence-in-depth guard in use case.
- **HTTP path:** `GET /api/v1/posts/pending`
- **STABLE files touched:**
  - `bootstrap/container.py` — add `list_pending_posts_adapter` and
    `list_pending_posts_use_case` providers plus their imports.

## 2. Context summary

A moderator or superuser sends `GET /api/v1/posts/pending` with optional `page`
and `items_per_page` query parameters. The router resolves the caller via the
existing `get_current_moderator_or_superuser` dependency and builds a
`ListPendingPostsQuery` carrying the pagination params and a
`requester_is_privileged` flag. `ListPendingPostsUseCase` checks the flag
(defence-in-depth) then delegates entirely to the port.
`ListPendingPostsAdapter` runs two queries in one session: a count + paginated
posts JOIN on `Post` and `User` (filtering `status IN ('pending_review',
'changes_requested')`, excluding soft-deleted posts and users, ordering by
`Post.created_at DESC`), followed by a bulk log fetch for the returned post IDs
(ordering log entries `created_at ASC`). Python merges the two result sets into
a `PendingPostPage`. The router converts the entity to `ListPendingPostsResponse`
(HTTP 200). Non-moderators receive HTTP 403 before the use case is reached;
unauthenticated callers receive HTTP 401. No ORM changes and no migration are
needed — all tables exist from slice 0013.

## 3. API contract

**Request body:** none (GET endpoint).

**Path parameters:** none.

**Query parameters:**

| Param | Type | Default | Validation |
|---|---|---|---|
| `page` | `int` | `1` | `ge=1` |
| `items_per_page` | `int` | `10` | `ge=1`, `le=100` |

**Response body** (`ListPendingPostsResponse`):

| Field | Type |
|---|---|
| `items` | `list[PendingPostItemSchema]` |
| `total_count` | `int` |
| `page` | `int` |
| `items_per_page` | `int` |

Each `PendingPostItemSchema`:

| Field | Type | Source |
|---|---|---|
| `post_uuid` | `UUID` | `post.uuid` |
| `title` | `str` | `post.title` |
| `text` | `str` | `post.text` |
| `media_url` | `str \| None` | `post.media_url` |
| `status` | `str` | `post.status` |
| `created_at` | `datetime` | `post.created_at` |
| `updated_at` | `datetime \| None` | `post.updated_at` |
| `author_username` | `str` | `user.username` (via JOIN) |
| `moderation_log` | `list[PendingModerationLogEntrySchema]` | bulk log query |

Each `PendingModerationLogEntrySchema`:

| Field | Type | Source |
|---|---|---|
| `id` | `int` | `post_moderation_log.id` |
| `event_type` | `str` | `post_moderation_log.event_type` |
| `action` | `str \| None` | `post_moderation_log.action` |
| `message` | `str \| None` | `post_moderation_log.message` |
| `created_at` | `datetime` | `post_moderation_log.created_at` |

**Status codes:**

- `200 OK` — paginated response; empty `items` with `total_count = 0` when no
  pending posts exist.
- `401 Unauthorized` — missing or invalid Bearer token (raised by
  `get_current_moderator_or_superuser` → `get_current_user` before use case).
- `403 Forbidden` — authenticated but not moderator/superuser (`ForbiddenDomainError`
  from use case if `requester_is_privileged = False`; transport-level 403 from
  the auth dependency if the dependency fires first).
- `422 Unprocessable Entity` — FastAPI/Pydantic rejects invalid query params
  (e.g. `page=0`, `items_per_page=200`).

No other `DomainError` subclass is raised by this use case.

## 4. File structure

All new files:

```
src/app/features/posts/list_pending_posts/
├── __init__.py
├── domain/
│   ├── __init__.py
│   ├── commands.py                              # ListPendingPostsQuery
│   ├── entities.py                              # PendingModerationLogEntry,
│   │                                            # PendingPostItem, PendingPostPage
│   ├── ports/
│   │   ├── __init__.py
│   │   └── list_pending_posts_port.py           # ListPendingPostsPort (Protocol)
│   └── use_case.py                              # ListPendingPostsUseCase
├── data/
│   ├── __init__.py
│   └── adapter.py                               # ListPendingPostsAdapter(ListPendingPostsPort)
└── presentation/
    ├── __init__.py
    ├── router.py                                # GET /posts/pending
    └── schemas.py                              # PendingModerationLogEntrySchema,
                                                # PendingPostItemSchema,
                                                # ListPendingPostsResponse
```

Existing FEATURE file modified:

```
src/app/features/posts/router.py           # include_router(list_pending_posts_router)
```

Existing STABLE file modified (minimal addition only):

```
src/app/bootstrap/container.py             # two providers + two imports
```

No new ORM model. No Alembic migration.

## 5. Implementation steps

### Step 1 — Domain: Query

**File:** `src/app/features/posts/list_pending_posts/domain/commands.py`

Header: `# FEATURE: list_pending_posts — domain query.`

```python
class ListPendingPostsQuery(BaseModel):
    page: int = 1
    items_per_page: int = 10
    requester_is_privileged: bool
```

No validation constraints here; constraints live in the presentation layer.
`requester_is_privileged` has no default — callers must supply it explicitly.

### Step 2 — Domain: Entities

**File:** `src/app/features/posts/list_pending_posts/domain/entities.py`

Header: `# FEATURE: list_pending_posts — domain entities.`

Three plain Pydantic `BaseModel` classes (stdlib and pydantic only — per layer
rules in `agent_docs/architecture.md`):

```python
class PendingModerationLogEntry(BaseModel):
    id: int
    event_type: str
    action: str | None
    message: str | None
    created_at: datetime

class PendingPostItem(BaseModel):
    post_uuid: UUID
    title: str
    text: str
    media_url: str | None
    status: str
    created_at: datetime
    updated_at: datetime | None
    author_username: str
    moderation_log: list[PendingModerationLogEntry]

class PendingPostPage(BaseModel):
    items: list[PendingPostItem]
    total_count: int
    page: int
    items_per_page: int
```

These entities are defined fresh in this slice's `domain/entities.py`. They must
not be imported from another slice per `agent_docs/architecture.md` § Layer rules.
`PendingModerationLogEntry` is analogous to `ModerationLogEntry` in
`moderate_post/domain/entities.py` but kept separate to avoid cross-slice imports.

### Step 3 — Domain: Port

**File:** `src/app/features/posts/list_pending_posts/domain/ports/list_pending_posts_port.py`

Header: `# FEATURE: list_pending_posts — port protocol.`

```python
@runtime_checkable
class ListPendingPostsPort(Protocol):
    async def list(self, query: ListPendingPostsQuery) -> PendingPostPage: ...
```

`@runtime_checkable` is mandatory per `agent_docs/architecture.md` §
Terminology: port and adapter. Import `ListPendingPostsQuery` from `..commands`
and `PendingPostPage` from `..entities`. All relative imports.

### Step 4 — Domain: Use case

**File:** `src/app/features/posts/list_pending_posts/domain/use_case.py`

Header: `# FEATURE: list_pending_posts — use case.`

`class ListPendingPostsUseCase`:
- `__init__(self, port: ListPendingPostsPort) -> None` — stores port as `self._port`.
- `async def __call__(self, query: ListPendingPostsQuery) -> PendingPostPage`:
  1. If `query.requester_is_privileged` is `False` → raise
     `ForbiddenDomainError("Moderator or superuser privilege required")`.
  2. Return `await self._port.list(query)`.

No other business logic. Import `ForbiddenDomainError` from `app.domain.errors`
via relative path: `from .....domain.errors import ForbiddenDomainError` (five
dots: `domain` → `list_pending_posts` → `posts` → `features` → `app`). Never
raises `HTTPException`. Never catches.

### Step 5 — Data: Adapter

**File:** `src/app/features/posts/list_pending_posts/data/adapter.py`

Header: `# FEATURE: list_pending_posts — data adapter.`

`class ListPendingPostsAdapter(ListPendingPostsPort)` — explicit inheritance from
the port is mandatory per `agent_docs/architecture.md` § Adapter pattern (canonical).

Constructor: `__init__(self, session_factory: async_sessionmaker[AsyncSession])`.

`async def list(self, query: ListPendingPostsQuery) -> PendingPostPage`:

Open one async session via `async with self._session_factory() as session`.

**Query 1 — count + paginated posts:**

```python
PENDING_STATUSES = ("pending_review", "changes_requested")

count_stmt = (
    select(func.count())
    .select_from(Post)
    .join(User, Post.created_by_user_id == User.id)
    .where(Post.status.in_(PENDING_STATUSES))
    .where(Post.is_deleted == False)
    .where(User.is_deleted == False)
)
total_count = await session.scalar(count_stmt)

offset = (query.page - 1) * query.items_per_page
rows_stmt = (
    select(Post, User.username)
    .join(User, Post.created_by_user_id == User.id)
    .where(Post.status.in_(PENDING_STATUSES))
    .where(Post.is_deleted == False)
    .where(User.is_deleted == False)
    .order_by(Post.created_at.desc())
    .offset(offset)
    .limit(query.items_per_page)
)
post_rows = (await session.execute(rows_stmt)).all()
```

**Query 2 — bulk log fetch:**

```python
post_ids = [row.Post.id for row in post_rows]
log_stmt = (
    select(PostModerationLog)
    .where(PostModerationLog.post_id.in_(post_ids))
    .order_by(PostModerationLog.created_at.asc())
)
log_rows = (await session.execute(log_stmt)).scalars().all()
```

**Python merge:** group `log_rows` by `post_id` using a `dict[int, list[PostModerationLog]]`.
For each `(post_row, username)` tuple build `PendingPostItem`, attaching the matching
log entries as `list[PendingModerationLogEntry]`.

Return `PendingPostPage(items=..., total_count=total_count, page=query.page,
items_per_page=query.items_per_page)`.

No `try/except` — read-only queries with no business-meaningful exception path per
`agent_docs/error_handling.md` § Right shape: read-only query, no catch.

Import `Post` from `.....adapters.db.models.post`, `User` from
`.....adapters.db.models.user`, `PostModerationLog` from
`.....adapters.db.models.post_moderation_log` (five dots from `data/` up to
`app/`). Import entities and port from `..domain.*`. All relative imports.

### Step 6 — Presentation: Schemas

**File:** `src/app/features/posts/list_pending_posts/presentation/schemas.py`

Header: `# FEATURE: list_pending_posts — request/response schemas.`

Three Pydantic models with `model_config = ConfigDict(from_attributes=True)`:

```python
class PendingModerationLogEntrySchema(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    event_type: str
    action: str | None
    message: str | None
    created_at: datetime

class PendingPostItemSchema(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    post_uuid: UUID
    title: str
    text: str
    media_url: str | None
    status: str
    created_at: datetime
    updated_at: datetime | None
    author_username: str
    moderation_log: list[PendingModerationLogEntrySchema]

class ListPendingPostsResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    items: list[PendingPostItemSchema]
    total_count: int
    page: int
    items_per_page: int
```

HTTP request/response schemas are per-slice and not shared from `_shared/`
per `agent_docs/architecture.md` § `_shared/` rules.

### Step 7 — Presentation: Router

**File:** `src/app/features/posts/list_pending_posts/presentation/router.py`

Header: `# FEATURE: list_pending_posts — HTTP router.`

Use the lazy-container-import pattern established in `moderate_post`:

```python
def _get_list_pending_posts_use_case() -> ListPendingPostsUseCase:
    from .....bootstrap.container import container  # noqa: PLC0415
    return container.list_pending_posts_use_case()
```

Endpoint:

```python
router = APIRouter()

@router.get(
    "/posts/pending",
    response_model=ListPendingPostsResponse,
    status_code=status.HTTP_200_OK,
)
async def list_pending_posts_endpoint(
    use_case: Annotated[ListPendingPostsUseCase, Depends(_get_list_pending_posts_use_case)],
    current_user: Annotated[dict, Depends(get_current_moderator_or_superuser)],
    page: int = Query(default=1, ge=1),
    items_per_page: int = Query(default=10, ge=1, le=100),
) -> ListPendingPostsResponse:
    query = ListPendingPostsQuery(
        page=page,
        items_per_page=items_per_page,
        requester_is_privileged=bool(
            current_user.get("is_moderator") or current_user.get("is_superuser")
        ),
    )
    result = await use_case(query)
    return ListPendingPostsResponse(
        items=[
            PendingPostItemSchema(
                post_uuid=item.post_uuid,
                title=item.title,
                text=item.text,
                media_url=item.media_url,
                status=item.status,
                created_at=item.created_at,
                updated_at=item.updated_at,
                author_username=item.author_username,
                moderation_log=[
                    PendingModerationLogEntrySchema(
                        id=e.id,
                        event_type=e.event_type,
                        action=e.action,
                        message=e.message,
                        created_at=e.created_at,
                    )
                    for e in item.moderation_log
                ],
            )
            for item in result.items
        ],
        total_count=result.total_count,
        page=result.page,
        items_per_page=result.items_per_page,
    )
```

Import `get_current_moderator_or_superuser` from `....users.dependencies`
(four dots: `presentation` → `list_pending_posts` → `posts` → `features`, then
`users.dependencies`). No caching — the pending queue changes frequently and
cache invalidation is omitted per the PRD. No `try/except`. No business logic.

### Step 8 — DI wiring: Container

**File:** `src/app/bootstrap/container.py` (STABLE — permitted addition)

Add two imports alongside existing feature imports:

```python
from ..features.posts.list_pending_posts.data.adapter import ListPendingPostsAdapter
from ..features.posts.list_pending_posts.domain.use_case import ListPendingPostsUseCase
```

Add two providers after the existing `revise_post` providers:

```python
list_pending_posts_adapter = providers.Factory(
    ListPendingPostsAdapter,
    session_factory=session_factory,
)

list_pending_posts_use_case = providers.Factory(
    ListPendingPostsUseCase,
    port=list_pending_posts_adapter,
)
```

No `wiring_config` entry needed — the router uses the lazy-import helper pattern
consistent with `moderate_post` and `revise_post`.

### Step 9 — Router registration

**File:** `src/app/features/posts/router.py` (FEATURE file)

Add one import alongside the existing slice router imports:

```python
from .list_pending_posts.presentation.router import router as list_pending_posts_router
```

Add one include call:

```python
router.include_router(list_pending_posts_router)
```

`bootstrap/router.py` is **not touched** — it already imports `posts_router`
from `features/posts/router.py` and that chain remains unchanged.

### Step 10 — Verify

```
ruff format src/app
ruff check src/app
mypy src/app
pytest
```

Outside-in test specifically:

```
pytest tests/features/posts/0019_list_pending_posts/list_pending_posts_outside_in_test.py -v
```

The slice is not done until all of the above pass, including the smoke test at
`tests/smoke/test_app_starts.py`.

## 6. Tests planned

- **Use-case unit test** —
  `tests/features/posts/0019_list_pending_posts/domain/test_use_case.py`.
  Construct `ListPendingPostsUseCase` with a mock `ListPendingPostsPort`.
  Two cases:
  - `requester_is_privileged=False` → `ForbiddenDomainError`; assert
    `port.list()` is never called.
  - Happy path: `requester_is_privileged=True`; assert `port.list()` is called
    with the query and its return value is passed through unchanged.
  Prior art: `tests/features/posts/0017_moderate_post/domain/test_use_case.py`.

- **Adapter unit test** —
  `tests/features/posts/0019_list_pending_posts/data/test_adapter.py`.
  Uses a real async session against the test Postgres database. Cases:
  - Only `pending_review` and `changes_requested` posts appear; `approved` posts
    are excluded.
  - Soft-deleted posts (`is_deleted=True`) are excluded from items and
    `total_count`.
  - Posts by soft-deleted users are excluded.
  - `moderation_log` entries are ordered chronologically (oldest first) and
    carry the correct fields.
  - Pagination (`page`, `items_per_page`, `total_count`) behaves correctly
    (seed >10 posts, request `page=2`, verify offset applied).
  - Empty queue returns `total_count=0` and `items=[]`.
  No catch path to assert — the adapter has no `try/except`.
  Prior art: `tests/features/posts/0017_moderate_post/data/test_adapter.py`.

- **Endpoint integration test** —
  `tests/features/posts/0019_list_pending_posts/presentation/test_router.py`.
  `httpx.AsyncClient` against the running app with test Postgres. Cases:
  - No Authorization header → 401.
  - Valid regular-user token (not moderator/superuser) → 403.
  - Moderator token, pending posts exist → 200 with correct `ListPendingPostsResponse`
    shape, `author_username` populated, `moderation_log` populated.
  - Superuser token → 200.
  - `approved` posts not in response.
  - No pending posts → 200 with `items=[]`, `total_count=0`.
  - `GET /posts/pending?page=0` → 422.
  - `GET /posts/pending?items_per_page=101` → 422.
  Prior art: `tests/features/posts/0017_moderate_post/presentation/test_router.py`.

- **Outside-in test** —
  `tests/features/posts/0019_list_pending_posts/list_pending_posts_outside_in_test.py`.
  Full HTTP stack, real adapter, test Postgres, no mocks.
  Five-step scenario per the PRD:
  1. Create a moderator and a regular author.
  2. Authenticate as author; create a post (enters `pending_review`).
  3. Moderator calls `POST /posts/{uuid}/moderate` with
     `action="changes_requested"` and a message — post status becomes
     `changes_requested`, log has one entry.
  4. Author calls `PATCH /posts/{uuid}/revise` — post returns to
     `pending_review`, log has two entries.
  5. Moderator calls `GET /posts/pending` — assert the post appears with
     `status="pending_review"` and `moderation_log` containing both entries in
     chronological order (oldest first).
  Acceptance gate: the slice is not done until this test is green.

**Opt-outs:** none — all four test levels apply.

## 7. Out of scope for this slice

- Filtering the queue by `status` (e.g. only `pending_review` or only
  `changes_requested`).
- Sorting options other than `created_at DESC`.
- Searching or filtering by author username.
- Pagination on the per-post moderation log within each item.
- Caching the pending queue — invalidation is complex; omitted per the PRD.
- Any changes to the `approved` terminal state.

## 8. Open questions

None — all decisions resolved in the PRD.
