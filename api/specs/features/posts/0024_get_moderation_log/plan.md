# 0024 · get_moderation_log — Implementation plan

## 1. Header

- **Feature:** posts
- **Slice:** 0024_get_moderation_log
- **PRD:** ./prd.md
- **Reference slice:** `../0019_list_pending_posts/plan.md` — same response shape (log
  entries returned in a list wrapper), same JOIN on `User` for actor username, same
  read-only adapter with no `try/except`.
- **HTTP path:** `GET /api/v1/posts/{post_uuid}/moderation-log`
- **STABLE files touched:**
  - `bootstrap/container.py` — add `get_moderation_log_adapter` and
    `get_moderation_log_use_case` providers plus their imports.

## 2. Context summary

An authenticated user calls `GET /posts/{post_uuid}/moderation-log`. The router
resolves the caller via `get_current_user` and builds a `GetModerationLogQuery`
carrying the post UUID and the requester's identity fields. `GetModerationLogUseCase`
first fetches the post by UUID (raising `NotFoundDomainError` for soft-deleted or
missing posts), then enforces multi-condition authorisation: the requester must be the
post's author, a moderator, or a superuser — failing all three raises
`ForbiddenDomainError`. On success the use-case delegates to the adapter to retrieve
all `PostModerationLog` rows for the post, joined with the `User` table to resolve
`actor_username`, ordered by `created_at` ascending. An empty list is a valid result
(newly created post with no moderation history). The router converts the domain entity
to `GetModerationLogResponse` (HTTP 200). No ORM changes and no migration are required —
all tables exist from slice 0013.

## 3. API contract

**Request body:** none (GET endpoint).

**Path parameters:**

| Param | Type | Validation |
|---|---|---|
| `post_uuid` | `UUID` | FastAPI path param; validated at schema boundary |

**Query parameters:** none.

**Response body** (`GetModerationLogResponse`):

| Field | Type |
|---|---|
| `items` | `list[ModerationLogEntrySchema]` |

Each `ModerationLogEntrySchema`:

| Field | Type | Source |
|---|---|---|
| `id` | `int` | `post_moderation_log.id` |
| `event_type` | `str` | `post_moderation_log.event_type` |
| `action` | `str \| None` | `post_moderation_log.action` |
| `message` | `str \| None` | `post_moderation_log.message` |
| `created_at` | `datetime` | `post_moderation_log.created_at` |
| `actor_user_id` | `int` | `post_moderation_log.user_id` |
| `actor_username` | `str` | `user.username` (via JOIN) |

Items are ordered ascending by `created_at` (chronological, oldest first).

**Status codes:**

- `200 OK` — `items` list returned; may be empty.
- `401 Unauthorized` — missing or invalid Bearer token (raised by `get_current_user`
  before use case is reached).
- `403 Forbidden` — authenticated but not author, moderator, or superuser
  (`ForbiddenDomainError` → HTTP 403).
- `404 Not Found` — post with this UUID does not exist or `is_deleted = True`
  (`NotFoundDomainError` → HTTP 404).

## 4. File structure

All new files:

```
src/app/features/posts/get_moderation_log/
├── __init__.py
├── domain/
│   ├── __init__.py
│   ├── commands.py                              # GetModerationLogQuery
│   ├── entities.py                              # PostForModerationLog,
│   │                                            # ModerationLogEntry,
│   │                                            # ModerationLog
│   ├── ports/
│   │   ├── __init__.py
│   │   └── get_moderation_log_port.py           # GetModerationLogPort (Protocol)
│   └── use_case.py                              # GetModerationLogUseCase
├── data/
│   ├── __init__.py
│   └── adapter.py                               # GetModerationLogAdapter(GetModerationLogPort)
└── presentation/
    ├── __init__.py
    ├── router.py                                # GET /posts/{post_uuid}/moderation-log
    └── schemas.py                               # ModerationLogEntrySchema,
                                                 # GetModerationLogResponse
```

Existing FEATURE file modified:

```
src/app/features/posts/router.py           # include_router(get_moderation_log_router)
```

Existing STABLE file modified (minimal addition only):

```
src/app/bootstrap/container.py             # two providers + two imports
```

No new ORM model. No Alembic migration.

## 5. Implementation steps

### Step 1 — Domain: Query

**File:** `src/app/features/posts/get_moderation_log/domain/commands.py`

Header: `# FEATURE: get_moderation_log — domain query.`

```python
class GetModerationLogQuery(BaseModel):
    post_uuid: UUID
    requester_user_id: int
    requester_is_moderator: bool
    requester_is_superuser: bool
```

All fields required; no defaults. The router always supplies them from the resolved
`current_user` dict. `requester_is_moderator` and `requester_is_superuser` carry the
privilege flags for the multi-condition auth check in the use case.

### Step 2 — Domain: Entities

**File:** `src/app/features/posts/get_moderation_log/domain/entities.py`

Header: `# FEATURE: get_moderation_log — domain entities.`

Three plain Pydantic `BaseModel` classes (stdlib and pydantic only — per layer rules
in `agent_docs/architecture.md`):

```python
class PostForModerationLog(BaseModel):
    id: int
    created_by_user_id: int

class ModerationLogEntry(BaseModel):
    id: int
    event_type: str
    action: str | None
    message: str | None
    created_at: datetime
    actor_user_id: int
    actor_username: str

class ModerationLog(BaseModel):
    items: list[ModerationLogEntry]
```

`PostForModerationLog` is the lightweight read model used for the existence check and
the authorship comparison. It must not be imported from another slice; it is defined
fresh here per `agent_docs/architecture.md` § Layer rules. `ModerationLogEntry` includes
`actor_user_id` and `actor_username` (resolved by a JOIN in the adapter), which
distinguishes it from the `PendingModerationLogEntry` in slice 0019.

### Step 3 — Domain: Port

**File:** `src/app/features/posts/get_moderation_log/domain/ports/get_moderation_log_port.py`

Header: `# FEATURE: get_moderation_log — port protocol.`

```python
@runtime_checkable
class GetModerationLogPort(Protocol):
    async def get_post_by_uuid(self, post_uuid: UUID) -> PostForModerationLog | None: ...
    async def get_log(self, post_id: int) -> list[ModerationLogEntry]: ...
```

`@runtime_checkable` is mandatory per `agent_docs/architecture.md` § Terminology: port
and adapter. Two narrow methods: one read for the existence/authorship check, one read
for the log entries. `get_log` returns an empty list (not `None`) when no entries exist.

### Step 4 — Domain: Use case

**File:** `src/app/features/posts/get_moderation_log/domain/use_case.py`

Header: `# FEATURE: get_moderation_log — use case.`

`class GetModerationLogUseCase`:
- `__init__(self, port: GetModerationLogPort) -> None` — stores port as `self._port`.
- `async def __call__(self, query: GetModerationLogQuery) -> ModerationLog`:
  1. `post = await self._port.get_post_by_uuid(query.post_uuid)`.
  2. If `post is None` → raise `NotFoundDomainError("Post not found")`.
  3. If none of these hold:
     - `query.requester_user_id == post.created_by_user_id`
     - `query.requester_is_moderator`
     - `query.requester_is_superuser`
     → raise `ForbiddenDomainError("Access to moderation log requires being the author, a moderator, or a superuser")`.
  4. `entries = await self._port.get_log(post.id)`.
  5. Return `ModerationLog(items=entries)`.

Import `NotFoundDomainError` and `ForbiddenDomainError` from `app.domain.errors` via
relative path (five dots from `get_moderation_log/domain/use_case.py`). Never raises
`HTTPException`. Never catches.

### Step 5 — Data: Adapter

**File:** `src/app/features/posts/get_moderation_log/data/adapter.py`

Header: `# FEATURE: get_moderation_log — data adapter.`

`class GetModerationLogAdapter(GetModerationLogPort)` — explicit inheritance from the
port is mandatory per `agent_docs/architecture.md` § Adapter pattern (canonical).

Constructor: `__init__(self, session_factory: async_sessionmaker[AsyncSession])`.

**`get_post_by_uuid(post_uuid)`:**

```python
async with self._session_factory() as session:
    stmt = (
        select(Post.id, Post.created_by_user_id)
        .where(Post.uuid == post_uuid)
        .where(Post.is_deleted == False)
    )
    row = (await session.execute(stmt)).one_or_none()
    if row is None:
        return None
    return PostForModerationLog(id=row.id, created_by_user_id=row.created_by_user_id)
```

No `try/except` — read-only query with no business-meaningful exception path per
`agent_docs/error_handling.md` § Right shape: read-only query, no catch.

**`get_log(post_id)`:**

```python
async with self._session_factory() as session:
    stmt = (
        select(PostModerationLog, User.username)
        .join(User, PostModerationLog.user_id == User.id)
        .where(PostModerationLog.post_id == post_id)
        .order_by(PostModerationLog.created_at.asc())
    )
    rows = (await session.execute(stmt)).all()
    return [
        ModerationLogEntry(
            id=row.PostModerationLog.id,
            event_type=row.PostModerationLog.event_type,
            action=row.PostModerationLog.action,
            message=row.PostModerationLog.message,
            created_at=row.PostModerationLog.created_at,
            actor_user_id=row.PostModerationLog.user_id,
            actor_username=row.username,
        )
        for row in rows
    ]
```

Returns an empty list when no log entries exist — the use-case treats this as valid.
No `try/except` — read-only queries with no business-meaningful exception path.

Import `Post` from `.....adapters.db.models.post`, `User` from
`.....adapters.db.models.user`, `PostModerationLog` from
`.....adapters.db.models.post_moderation_log` (five dots from `data/` up to `app/`).
Import entities and port from `..domain.*`. All relative imports.

### Step 6 — Presentation: Schemas

**File:** `src/app/features/posts/get_moderation_log/presentation/schemas.py`

Header: `# FEATURE: get_moderation_log — request/response schemas.`

```python
class ModerationLogEntrySchema(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    event_type: str
    action: str | None
    message: str | None
    created_at: datetime
    actor_user_id: int
    actor_username: str

class GetModerationLogResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    items: list[ModerationLogEntrySchema]
```

HTTP request/response schemas are per-slice and not shared from `_shared/` per
`agent_docs/architecture.md` § `_shared/` rules. No request body schema is needed —
this is a GET endpoint with a path param only.

### Step 7 — Presentation: Router

**File:** `src/app/features/posts/get_moderation_log/presentation/router.py`

Header: `# FEATURE: get_moderation_log — HTTP router.`

Use the lazy-container-import pattern established in `moderate_post` and `list_pending_posts`:

```python
def _get_get_moderation_log_use_case() -> GetModerationLogUseCase:
    from .....bootstrap.container import container  # noqa: PLC0415
    return container.get_moderation_log_use_case()
```

Endpoint:

```python
router = APIRouter()

@router.get(
    "/posts/{post_uuid}/moderation-log",
    response_model=GetModerationLogResponse,
    status_code=status.HTTP_200_OK,
)
async def get_moderation_log_endpoint(
    post_uuid: UUID,
    use_case: Annotated[GetModerationLogUseCase, Depends(_get_get_moderation_log_use_case)],
    current_user: Annotated[dict, Depends(get_current_user)],
) -> GetModerationLogResponse:
    query = GetModerationLogQuery(
        post_uuid=post_uuid,
        requester_user_id=current_user["id"],
        requester_is_moderator=bool(current_user.get("is_moderator")),
        requester_is_superuser=bool(current_user.get("is_superuser")),
    )
    result = await use_case(query)
    return GetModerationLogResponse(
        items=[
            ModerationLogEntrySchema(
                id=e.id,
                event_type=e.event_type,
                action=e.action,
                message=e.message,
                created_at=e.created_at,
                actor_user_id=e.actor_user_id,
                actor_username=e.actor_username,
            )
            for e in result.items
        ]
    )
```

This endpoint uses `get_current_user` (not `get_current_moderator_or_superuser`) because
authors — who are ordinary users — must also be able to call it. The multi-condition
authorisation check (`author OR moderator OR superuser`) lives in the use case.

Import `get_current_user` from `....users.dependencies` (four dots: `presentation` →
`get_moderation_log` → `posts` → `features`, then `users.dependencies`). No caching —
the moderation log is security-sensitive audit data per `agent_docs/entry_points/fastapi.md`
§ Caching. No `try/except`. No business logic.

### Step 8 — DI wiring: Container

**File:** `src/app/bootstrap/container.py` (STABLE — permitted addition)

Add two imports alongside existing feature imports:

```python
from ..features.posts.get_moderation_log.data.adapter import GetModerationLogAdapter
from ..features.posts.get_moderation_log.domain.use_case import GetModerationLogUseCase
```

Add two providers after the existing `list_all_posts_visibility` providers:

```python
get_moderation_log_adapter = providers.Factory(
    GetModerationLogAdapter,
    session_factory=session_factory,
)

get_moderation_log_use_case = providers.Factory(
    GetModerationLogUseCase,
    port=get_moderation_log_adapter,
)
```

No `wiring_config` entry needed — the router uses the lazy-import helper pattern,
consistent with `moderate_post`, `revise_post`, and `list_pending_posts`.

### Step 9 — Router registration

**File:** `src/app/features/posts/router.py` (FEATURE file)

Add one import alongside the existing slice router imports:

```python
from .get_moderation_log.presentation.router import router as get_moderation_log_router
```

Add one include call:

```python
router.include_router(get_moderation_log_router)
```

`bootstrap/router.py` is **not touched** — it already imports `posts_router` from
`features/posts/router.py` and that chain remains unchanged.

### Step 10 — Verify

```
ruff format src/app
ruff check src/app
mypy src/app
pytest
```

Outside-in test specifically:

```
pytest tests/features/posts/0024_get_moderation_log/get_moderation_log_outside_in_test.py -v
```

The slice is not done until all of the above pass, including the smoke test at
`tests/smoke/test_app_starts.py`.

## 6. Tests planned

- **Use-case unit test** —
  `tests/features/posts/0024_get_moderation_log/domain/test_use_case.py`.
  Mock `GetModerationLogPort`. Nine cases:
  - `get_post_by_uuid` returns `None` → `NotFoundDomainError`; assert `get_log` never called.
  - Post exists; requester is not author, not moderator, not superuser →
    `ForbiddenDomainError`; assert `get_log` never called.
  - Requester is the post author → `ModerationLog` returned; assert `get_log` called.
  - Requester is a moderator (not author) → `ModerationLog` returned.
  - Requester is a superuser (not author) → `ModerationLog` returned.
  - Requester is both author and moderator → `ModerationLog` returned (no conflict).
  - Log is empty → `ModerationLog(items=[])` returned.
  - Log entries returned in the order the port returns them (ordering is adapter's
    responsibility; use-case passes through unchanged).
  Prior art: `tests/features/posts/0017_moderate_post/domain/test_use_case.py`.

- **Adapter unit test** —
  `tests/features/posts/0024_get_moderation_log/data/test_adapter.py`.
  Uses a real async session against the test Postgres database. Cases:
  - `get_post_by_uuid` — UUID not found: assert `None` returned.
  - `get_post_by_uuid` — soft-deleted post (`is_deleted=True`): assert `None` returned.
  - `get_post_by_uuid` — found: assert returned `PostForModerationLog` fields match row.
  - `get_log` — no entries: assert empty list returned.
  - `get_log` — entries present: assert `actor_username` is resolved from the joined
    `User` row and entries are ordered ascending by `created_at`.
  - `get_log` — entries from other posts excluded.
  No `try/except` catch paths to assert.
  Prior art: `tests/features/posts/0019_list_pending_posts/data/test_adapter.py`.

- **Endpoint integration test** —
  `tests/features/posts/0024_get_moderation_log/presentation/test_router.py`.
  `httpx.AsyncClient` against the running app with test Postgres. Cases:
  - No Authorization header → 401.
  - Valid token, user is not author / not moderator / not superuser → 403.
  - Valid token, non-existent post UUID → 404.
  - Valid token, soft-deleted post UUID → 404.
  - Author token, newly created post (no log entries) → 200 with `{ "items": [] }`.
  - Author token, post with log entries → 200 with correct entries and `actor_username`.
  - Moderator token (not author) → 200.
  - Superuser token (not author) → 200.
  Prior art: `tests/features/posts/0019_list_pending_posts/presentation/test_router.py`.

- **Outside-in test** —
  `tests/features/posts/0024_get_moderation_log/get_moderation_log_outside_in_test.py`.
  Full HTTP stack, real adapter, test Postgres, no mocks.
  Scenario: create a post → moderate (`changes_requested`) → revise → call log endpoint
  as author → assert two entries present with correct `event_type`, `action`, `message`,
  and `actor_username`.
  Prior art: `tests/features/posts/0019_list_pending_posts/list_pending_posts_outside_in_test.py`
  for scenario shape.

**Opt-outs:** none — all four test levels apply.

## 7. Out of scope for this slice

- Pagination or filtering of the moderation log.
- Filtering entries by `event_type`, `action`, or date range.
- Exposing the log to unauthenticated users, even for approved posts.
- A notification or badge system to alert authors when new log entries appear.
- Caching the moderation log — security-sensitive audit data; per
  `agent_docs/entry_points/fastapi.md` § Caching.

## 8. Open questions

None — all decisions resolved in the PRD.
