# 0018 · revise_post — Implementation plan

## 1. Header

- **Feature:** posts
- **Slice:** 0018_revise_post
- **PRD:** ./prd.md
- **Reference slice:** `../0017_moderate_post/plan.md` — closest operation shape: an
  author-gated mutation that checks existence, guards against wrong ownership and wrong
  status, then atomically updates the post and appends a `PostModerationLog` row.
- **HTTP path:** `PATCH /api/v1/posts/{post_uuid}/revise`
- **STABLE files touched:**
  - `bootstrap/container.py` — add `revise_post_adapter` and `revise_post_use_case`
    providers plus their imports; add router module to `wiring_config`.

## 2. Context summary

The post author calls `PATCH /posts/{post_uuid}/revise` to address moderator feedback
after their post has been moved to `changes_requested` status by slice 0017. The router
resolves the caller via `get_current_user` (any authenticated user), builds a
`RevisePostCommand` carrying the post UUID, the requester's integer PK, optional new
`title` and `text`, and an optional reply `message`. `RevisePostUseCase` enforces three
guards — existence, ownership, and status — then delegates to the port to atomically
update `Post.title`, `Post.text`, `Post.status` (reset to `pending_review`),
`Post.updated_at`, and insert a `PostModerationLog` row tagged `event_type =
"author_revision"`. The use-case returns a `RevisedPostResult`; the router converts it to
`RevisePostResponse` (HTTP 200). No migrations are needed — the `Post.status` column and
`PostModerationLog` table were added by slice 0013.

## 3. API contract

**Path params:**

| Param | Type | Notes |
|---|---|---|
| `post_uuid` | `UUID` | UUID of the post to revise |

**Request body** (`RevisePostRequest`):

| Field | Type | Required | Notes |
|---|---|---|---|
| `title` | `str \| None` | conditional | at least one of `title`/`text` must be non-null |
| `text` | `str \| None` | conditional | at least one of `title`/`text` must be non-null |
| `message` | `str \| None` | optional | author reply attached to the log entry |

**Response body** (`RevisePostResponse`):

| Field | Type | Notes |
|---|---|---|
| `post_uuid` | `UUID` | |
| `title` | `str` | post title after revision (updated or unchanged) |
| `text` | `str` | post body after revision (updated or unchanged) |
| `status` | `str` | always `"pending_review"` after a successful revision |
| `updated_at` | `datetime` | UTC timestamp of the revision |
| `log_entry.id` | `int` | PK of the inserted `PostModerationLog` row |
| `log_entry.event_type` | `str` | always `"author_revision"` |
| `log_entry.action` | `str \| None` | always `null` for author revisions |
| `log_entry.message` | `str \| None` | mirrors `message` from request |
| `log_entry.created_at` | `datetime` | UTC timestamp of the revision |

**Status codes:**

- `200 OK` — revision recorded; response body confirmed.
- `401 Unauthorized` — missing or invalid Bearer token.
- `403 Forbidden` — post does not belong to the requester (ownership check); or post is
  not in `changes_requested` status (status guard).
- `404 Not Found` — `NotFoundDomainError`; `post_uuid` does not exist.
- `422 Unprocessable Entity` — neither `title` nor `text` is provided (schema-level
  `@model_validator`).

## 4. File structure

All new files; no existing files deleted. One STABLE file and one FEATURE file receive
minimal additions.

```
src/app/features/posts/revise_post/
├── __init__.py
├── domain/
│   ├── __init__.py
│   ├── commands.py                         # RevisePostCommand
│   ├── entities.py                         # PostForRevision, RevisionLogEntry,
│   │                                       # RevisedPostResult
│   ├── ports/
│   │   ├── __init__.py
│   │   └── revise_post_port.py             # RevisePostPort
│   └── use_case.py                         # RevisePostUseCase
├── data/
│   ├── __init__.py
│   └── adapter.py                          # RevisePostAdapter(RevisePostPort)
└── presentation/
    ├── __init__.py
    ├── router.py                            # PATCH /posts/{post_uuid}/revise
    └── schemas.py                          # RevisePostRequest, RevisionLogEntrySchema,
                                            # RevisePostResponse
```

FEATURE files modified (not STABLE):

```
src/app/features/posts/router.py           # include_router(revise_post_router)
```

STABLE files modified (minimal additions only):

```
src/app/bootstrap/container.py             # two providers + two imports + one wiring entry
```

No new ORM model. No Alembic migration.

## 5. Implementation steps

### Step 1 — Domain: Command

**File:** `src/app/features/posts/revise_post/domain/commands.py`

Header: `# FEATURE: revise_post — domain command.`

```python
class RevisePostCommand(BaseModel):
    post_uuid: UUID
    requester_user_id: int
    title: str | None
    text: str | None
    message: str | None
```

`requester_user_id` is the integer PK of the authenticated author; used for the
ownership check and for writing `PostModerationLog.user_id`. All other fields are
optional; `None` means "leave unchanged" for `title`/`text`, "no reply" for `message`.

### Step 2 — Domain: Entities

**File:** `src/app/features/posts/revise_post/domain/entities.py`

Header: `# FEATURE: revise_post — domain entities.`

```python
class PostForRevision(BaseModel):
    id: int
    uuid: UUID
    status: str
    created_by_user_id: int

class RevisionLogEntry(BaseModel):
    id: int
    event_type: str
    action: str | None
    message: str | None
    created_at: datetime

class RevisedPostResult(BaseModel):
    post_uuid: UUID
    title: str
    text: str
    status: str
    updated_at: datetime
    log_entry: RevisionLogEntry
```

`PostForRevision` is the lightweight read model for business checks. Must not be imported
from another slice; defined fresh here per `agent_docs/architecture.md` § Layer rules.

### Step 3 — Domain: Port

**File:** `src/app/features/posts/revise_post/domain/ports/revise_post_port.py`

Header: `# FEATURE: revise_post — port protocol.`

```python
@runtime_checkable
class RevisePostPort(Protocol):
    async def get_post_by_uuid(self, post_uuid: UUID) -> PostForRevision | None: ...
    async def apply_revision(
        self,
        post_id: int,
        post_uuid: UUID,
        title: str | None,
        text: str | None,
        author_user_id: int,
        message: str | None,
    ) -> RevisedPostResult: ...
```

`@runtime_checkable` is mandatory per `agent_docs/architecture.md` § Terminology: port
and adapter. Two methods: a narrow read for business checks, and an atomic write that
conditionally updates the post and inserts the log row.

### Step 4 — Domain: Use case

**File:** `src/app/features/posts/revise_post/domain/use_case.py`

Header: `# FEATURE: revise_post — use case.`

`class RevisePostUseCase`:
- `__init__(self, port: RevisePostPort)`.
- `async def __call__(self, command: RevisePostCommand) -> RevisedPostResult`:
  1. `post = await self._port.get_post_by_uuid(command.post_uuid)`.
  2. If `post is None` → raise `NotFoundDomainError("Post not found")`.
  3. If `post.created_by_user_id != command.requester_user_id` → raise
     `ForbiddenDomainError("You may only revise your own posts")`.
  4. If `post.status != "changes_requested"` → raise
     `ForbiddenDomainError("Post is not in changes_requested status")`.
  5. Return `await self._port.apply_revision(post.id, post.uuid, command.title,
     command.text, command.requester_user_id, command.message)`.

Imports `ForbiddenDomainError` and `NotFoundDomainError` from `domain/errors.py` via
relative path. Never raises `HTTPException`. Never catches.

### Step 5 — Data: Adapter

**File:** `src/app/features/posts/revise_post/data/adapter.py`

Header: `# FEATURE: revise_post — data adapter.`

`class RevisePostAdapter(RevisePostPort)` — explicit inheritance mandatory per
`agent_docs/architecture.md` § Adapter pattern (canonical).

Constructor: `__init__(self, session_factory: async_sessionmaker[AsyncSession])`.

**`get_post_by_uuid(post_uuid)`** — `SELECT id, uuid, status, created_by_user_id FROM
post WHERE uuid = post_uuid`. Return a mapped `PostForRevision` if found, else `None`.
No `try/except` per `agent_docs/error_handling.md` § Right shape: read-only query, no
catch.

**`apply_revision(post_id, post_uuid, title, text, author_user_id, message)`** — within a
single session context:
1. Build an `UPDATE` statement: always sets `status = "pending_review"` and
   `updated_at = now()`; conditionally adds `title` and `text` to the SET clause only
   when non-`None`. A `None` value means "leave unchanged" — never write `None` to the
   non-nullable `title`/`text` columns.
2. Fetch the updated post row to obtain current `title`, `text`, and `updated_at` for the
   response.
3. Insert a `PostModerationLog` row: `post_id=post_id`, `user_id=author_user_id`,
   `event_type="author_revision"`, `action=None`, `message=message`. Call
   `await session.refresh(log_model)` to populate `id` and `created_at`.
4. Commit once after both operations.
5. Return `RevisedPostResult` populated from the updated post row and the log row.

No `try/except` — the UPDATE and log INSERT carry no unique constraints that would
produce a business-meaningful `IntegrityError`; any infrastructure failure propagates to
the global handler per `agent_docs/error_handling.md`.

Import `Post` from `adapters/db/models/post.py` and `PostModerationLog` from
`adapters/db/models/post_moderation_log.py` via relative imports.

### Step 6 — Presentation: Schemas

**File:** `src/app/features/posts/revise_post/presentation/schemas.py`

Header: `# FEATURE: revise_post — request/response schemas.`

```python
class RevisePostRequest(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    title: str | None = None
    text: str | None = None
    message: str | None = None

    @model_validator(mode="after")
    def at_least_one_field_required(self) -> "RevisePostRequest":
        if self.title is None and self.text is None:
            raise ValueError("At least one of title or text must be provided")
        return self

class RevisionLogEntrySchema(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    event_type: str
    action: str | None
    message: str | None
    created_at: datetime

class RevisePostResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    post_uuid: UUID
    title: str
    text: str
    status: str
    updated_at: datetime
    log_entry: RevisionLogEntrySchema
```

The `@model_validator` enforces the at-least-one-field requirement at the schema boundary
(HTTP 422) before the use-case is invoked.

### Step 7 — Presentation: Router

**File:** `src/app/features/posts/revise_post/presentation/router.py`

Header: `# FEATURE: revise_post — HTTP router.`

Use the lazy-container-import pattern established in `assign_moderator` and used in
`moderate_post`:

```python
def _get_revise_post_use_case() -> RevisePostUseCase:
    from .....bootstrap.container import container  # noqa: PLC0415
    return container.revise_post_use_case()
```

Endpoint:

```python
@router.patch(
    "/posts/{post_uuid}/revise",
    response_model=RevisePostResponse,
    status_code=status.HTTP_200_OK,
)
async def revise_post_endpoint(
    post_uuid: UUID,
    request: RevisePostRequest,
    use_case: Annotated[RevisePostUseCase, Depends(_get_revise_post_use_case)],
    current_user: Annotated[dict, Depends(get_current_user)],
) -> RevisePostResponse:
    command = RevisePostCommand(
        post_uuid=post_uuid,
        requester_user_id=current_user["id"],
        title=request.title,
        text=request.text,
        message=request.message,
    )
    result = await use_case(command)
    return RevisePostResponse(
        post_uuid=result.post_uuid,
        title=result.title,
        text=result.text,
        status=result.status,
        updated_at=result.updated_at,
        log_entry=RevisionLogEntrySchema(
            id=result.log_entry.id,
            event_type=result.log_entry.event_type,
            action=result.log_entry.action,
            message=result.log_entry.message,
            created_at=result.log_entry.created_at,
        ),
    )
```

Import `get_current_user` from `.....features.users._shared.dependencies` (relative).
No business logic. No `try/except`. No direct DB access.

### Step 8 — DI wiring: Container

**File:** `src/app/bootstrap/container.py` (STABLE — minimal additions)

Add the router module to `wiring_config.modules`:

```python
"app.features.posts.revise_post.presentation.router",
```

Add after the last existing use-case provider:

```python
revise_post_adapter = providers.Factory(
    RevisePostAdapter,
    session_factory=session_factory,
)

revise_post_use_case = providers.Factory(
    RevisePostUseCase,
    port=revise_post_adapter,
)
```

Add the two corresponding imports at the top of the file alongside existing feature
imports.

### Step 9 — Router registration

**File:** `src/app/features/posts/router.py` (FEATURE file)

Add one import and one `include_router` call following the existing pattern:

```python
from .revise_post.presentation.router import router as revise_post_router
# ...
router.include_router(revise_post_router)
```

`bootstrap/router.py` is **not touched** — it already aggregates `posts_router`, which
in turn aggregates all post slice sub-routers.

### Step 10 — Verify

```
ruff format src/app
ruff check src/app
mypy src/app
pytest
```

Outside-in test specifically:

```
pytest tests/features/posts/0018_revise_post/revise_post_outside_in_test.py -v
```

The slice is not done until all of the above pass, including the smoke test
(`tests/smoke/test_app_starts.py`).

## 6. Tests planned

- **Use-case unit test** —
  `tests/features/posts/0018_revise_post/domain/test_use_case.py`.
  Mock `RevisePostPort`. Seven cases:
  - `get_post_by_uuid` returns `None` → `NotFoundDomainError`; assert `apply_revision`
    is never called.
  - Post `created_by_user_id` differs from `command.requester_user_id` →
    `ForbiddenDomainError`; assert `apply_revision` is never called.
  - Post `status = "pending_review"` → `ForbiddenDomainError`; assert `apply_revision`
    is never called.
  - Post `status = "approved"` → `ForbiddenDomainError`; assert `apply_revision`
    is never called.
  - Happy path — title only: mock both port methods to succeed; provide `title` but
    `text=None`; assert `apply_revision` called with `title=<value>`, `text=None`;
    assert returned entity matches port's return value.
  - Happy path — text only: same with `title=None` and non-`None` `text`.
  - Happy path — both fields + message: provide both `title` and `text` and a `message`;
    assert all fields are forwarded to the port.
  Prior art: `tests/features/posts/0017_moderate_post/domain/test_use_case.py`.

- **Adapter unit test** —
  `tests/features/posts/0018_revise_post/data/test_adapter.py`.
  Uses a real async session against the test Postgres database. Six cases:
  - `get_post_by_uuid` — UUID not found: assert `None` returned.
  - `get_post_by_uuid` — UUID found: insert a post row; assert returned `PostForRevision`
    fields match the row.
  - `apply_revision` — title-only update: insert a `changes_requested` post; call
    `apply_revision(title="New Title", text=None, ...)`; assert `RevisedPostResult` has
    `title="New Title"`, original `text`, `status="pending_review"`; fetch the row and
    assert DB state matches.
  - `apply_revision` — text-only update: same, verifying only `text` changed.
  - `apply_revision` — both fields updated: provide both `title` and `text`; assert both
    are updated in the DB row.
  - `apply_revision` — log row created: after calling `apply_revision`, fetch the
    `PostModerationLog` row and assert `event_type="author_revision"`, `action=None`, and
    `message` matches the input.
  Prior art: `tests/features/posts/0017_moderate_post/data/test_adapter.py`.

- **Endpoint integration test** —
  `tests/features/posts/0018_revise_post/presentation/test_router.py`.
  `httpx.AsyncClient` against the running app with test Postgres. Eight cases:
  - No Authorization header → 401.
  - Valid token, post owned by another user → 403 (ownership guard).
  - Valid token, post in `pending_review` → 403 (status guard).
  - Valid token, post in `approved` → 403 (status guard).
  - Valid token, non-existent UUID → 404.
  - Body `{}` (neither `title` nor `text`) → 422.
  - 200 — title update: create a post, moderate it to `changes_requested`, then call
    revise with a new `title`; assert HTTP 200, `status="pending_review"` in response,
    `log_entry.event_type="author_revision"`.
  - 200 — with message: same flow, providing a `message`; assert `log_entry.message`
    matches.
  Prior art: `tests/features/posts/0017_moderate_post/presentation/test_router.py`.

- **Outside-in test** —
  `tests/features/posts/0018_revise_post/revise_post_outside_in_test.py`.
  Full HTTP stack with real adapter, test Postgres, no mocks. Six-step scenario:
  1. Create a regular user (the post author) via `POST /users`.
  2. Authenticate as the author; create a post — confirm `status="pending_review"`.
  3. Create a moderator user and assign the moderator flag (direct DB or fixture).
  4. Authenticate as the moderator; call `POST /posts/{post_uuid}/moderate` with
     `action="changes_requested"` and a `message` — confirm `status="changes_requested"`.
  5. Authenticate as the author; call `PATCH /posts/{post_uuid}/revise` with an updated
     `title` and an optional reply `message` — assert HTTP 200,
     `status="pending_review"`, `log_entry.event_type="author_revision"`.
  6. Fetch the post row directly from the DB and assert `status="pending_review"` and a
     `PostModerationLog` row exists with `event_type="author_revision"`.
  Acceptance gate: the slice is not done until this test is green.

**Opt-outs:** none — all four test levels apply.

## 7. Out of scope for this slice

- Revising a post in `pending_review` or `approved` status — only `changes_requested`
  posts are revisable.
- Revising a post authored by another user — ownership is verified against the JWT.
- Updating fields other than `title` and `text` (e.g. `media_url`).
- Returning the full `PostModerationLog` history — only the log entry created by this
  revision is returned.
- Notifications (email or in-app) to the moderator when a revision is submitted.
- The `pending_review` → `approved` and `pending_review` → `changes_requested`
  transitions — those are slice 0017.
- The `list_pending_posts` endpoint — that is slice 0019.

## 8. Open questions

None — all decisions resolved in the PRD.
