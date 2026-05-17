# 0017 · moderate_post — Implementation plan

## 1. Header

- **Feature:** posts
- **Slice:** 0017_moderate_post
- **PRD:** ./prd.md
- **Reference slice:** `../../../users/0015_assign_moderator/plan.md` — closest operation
  shape: a privilege-gated mutation that checks existence, guards against a conflict, then
  writes a state transition and returns a result entity.
- **HTTP path:** `POST /api/v1/posts/{post_uuid}/moderate`
- **STABLE files touched:**
  - `bootstrap/container.py` — add `moderate_post_adapter` and `moderate_post_use_case`
    providers plus their imports.

## 2. Context summary

A moderator or superuser calls `POST /posts/{post_uuid}/moderate` to act on a post that is
in `pending_review` status. The router resolves the caller via the new
`get_current_moderator_or_superuser` dependency (introduced in this slice in
`features/users/dependencies.py`) and builds a `ModeratePostCommand` carrying the post
UUID, the requester's integer PK, a privilege flag, the `action` string, and an optional
`message`. `ModeratePostUseCase` enforces five guards — privilege, existence,
self-review, terminal-state, and message-required — then delegates to the port to
atomically update `Post.status` and insert a `PostModerationLog` row. The use-case returns
a `ModeratedPostResult`; the router converts it to `ModeratePostResponse` (HTTP 200). No
migrations are needed — the `Post.status` column and `PostModerationLog` table were added
by slice 0013.

## 3. API contract

**Path params:**

| Param | Type | Notes |
|---|---|---|
| `post_uuid` | `UUID` | UUID of the post to moderate |

**Request body** (`ModeratePostRequest`):

| Field | Type | Required | Notes |
|---|---|---|---|
| `action` | `Literal["approved", "changes_requested"]` | yes | validated at schema boundary |
| `message` | `str \| None` | conditional | required when `action = "changes_requested"` |

**Response body** (`ModeratePostResponse`):

| Field | Type | Notes |
|---|---|---|
| `post_uuid` | `UUID` | |
| `status` | `str` | new post status after the decision |
| `log_entry.id` | `int` | PK of the inserted `PostModerationLog` row |
| `log_entry.event_type` | `str` | always `"moderator_review"` |
| `log_entry.action` | `str \| None` | mirrors `action` from request |
| `log_entry.message` | `str \| None` | mirrors `message` from request |
| `log_entry.created_at` | `datetime` | UTC timestamp of the decision |

**Status codes:**

- `200 OK` — decision recorded; response body confirmed.
- `401 Unauthorized` — missing or invalid Bearer token.
- `403 Forbidden` — authenticated user is not a moderator or superuser; or requester is
  the post's author (self-review guard); or `action = changes_requested` with
  `message = None` (use-case enforcement).
- `404 Not Found` — `NotFoundDomainError`; `post_uuid` does not exist.
- `409 Conflict` — `DuplicateValueDomainError`; post is already in `approved` terminal
  state.
- `422 Unprocessable Entity` — `action` is not one of the two recognised values, or
  `action = changes_requested` with `message = None` (schema-level `@model_validator`).

## 4. File structure

All new files; no existing files deleted. One STABLE file and two FEATURE files receive
minimal additions.

```
src/app/features/posts/moderate_post/
├── __init__.py
├── domain/
│   ├── __init__.py
│   ├── commands.py                         # ModeratePostCommand
│   ├── entities.py                         # PostForModeration, ModerationLogEntry,
│   │                                       # ModeratedPostResult
│   ├── ports/
│   │   ├── __init__.py
│   │   └── moderate_post_port.py           # ModeratePostPort
│   └── use_case.py                         # ModeratePostUseCase
├── data/
│   ├── __init__.py
│   └── adapter.py                          # ModeratePostAdapter(ModeratePostPort)
└── presentation/
    ├── __init__.py
    ├── router.py                            # POST /posts/{post_uuid}/moderate
    └── schemas.py                          # ModeratePostRequest, ModerationLogEntrySchema,
                                            # ModeratePostResponse
```

FEATURE files modified (not STABLE):

```
src/app/features/users/dependencies.py     # add get_current_moderator_or_superuser
src/app/features/posts/router.py           # include_router(moderate_post_router)
```

STABLE files modified (minimal additions only):

```
src/app/bootstrap/container.py             # two providers + two imports
```

No new ORM model. No Alembic migration.

## 5. Implementation steps

### Step 1 — Auth dependency: `get_current_moderator_or_superuser`

**File:** `src/app/features/users/dependencies.py` (FEATURE — already exists)

Add after `get_current_superuser`:

```python
async def get_current_moderator_or_superuser(
    current_user: Annotated[dict, Depends(get_current_user)],
) -> dict:
    if not (current_user.get("is_moderator") or current_user.get("is_superuser")):
        raise ForbiddenException("You do not have enough privileges.")
    return current_user
```

Mirrors the structure of `get_current_superuser`. Raises `ForbiddenException` (fastcrud)
so FastAPI returns HTTP 403 at the transport layer, consistent with the existing auth
dependency pattern. Returns the full user dict for use in the router.

### Step 2 — Domain: Command

**File:** `src/app/features/posts/moderate_post/domain/commands.py`

Header: `# FEATURE: moderate_post — domain command.`

```python
class ModeratePostCommand(BaseModel):
    post_uuid: UUID
    requester_user_id: int
    requester_is_privileged: bool
    action: str
    message: str | None
```

`requester_user_id` is the integer PK of the acting user; used for the self-review check
and for writing `PostModerationLog.user_id`. `requester_is_privileged` is the second-layer
defence flag populated by the router from the resolved dependency dict. All fields always
required.

### Step 3 — Domain: Entities

**File:** `src/app/features/posts/moderate_post/domain/entities.py`

Header: `# FEATURE: moderate_post — domain entities.`

```python
class PostForModeration(BaseModel):
    id: int
    uuid: UUID
    status: str
    created_by_user_id: int

class ModerationLogEntry(BaseModel):
    id: int
    event_type: str
    action: str | None
    message: str | None
    created_at: datetime

class ModeratedPostResult(BaseModel):
    post_uuid: UUID
    status: str
    log_entry: ModerationLogEntry
```

`PostForModeration` is the lightweight read model used for business checks. It must not
be imported from another slice; it is defined fresh here per `agent_docs/architecture.md`
§ Layer rules.

### Step 4 — Domain: Port

**File:** `src/app/features/posts/moderate_post/domain/ports/moderate_post_port.py`

Header: `# FEATURE: moderate_post — port protocol.`

```python
@runtime_checkable
class ModeratePostPort(Protocol):
    async def get_post_by_uuid(self, post_uuid: UUID) -> PostForModeration | None: ...
    async def apply_decision(
        self,
        post_id: int,
        post_uuid: UUID,
        action: str,
        moderator_user_id: int,
        message: str | None,
    ) -> ModeratedPostResult: ...
```

`@runtime_checkable` is mandatory per `agent_docs/architecture.md` § Terminology: port
and adapter. Two methods: a narrow read for business checks, and an atomic write that
updates Post and inserts the log row.

### Step 5 — Domain: Use case

**File:** `src/app/features/posts/moderate_post/domain/use_case.py`

Header: `# FEATURE: moderate_post — use case.`

`class ModeratePostUseCase`:
- `__init__(self, port: ModeratePostPort)`.
- `async def __call__(self, command: ModeratePostCommand) -> ModeratedPostResult`:
  1. If `command.requester_is_privileged` is `False` → raise
     `ForbiddenDomainError("Moderator or superuser privilege required")`.
  2. `post = await self._port.get_post_by_uuid(command.post_uuid)`.
  3. If `post is None` → raise `NotFoundDomainError("Post not found")`.
  4. If `post.created_by_user_id == command.requester_user_id` → raise
     `ForbiddenDomainError("Moderators may not review their own posts")`.
  5. If `post.status == "approved"` → raise
     `DuplicateValueDomainError("Post is already approved")`.
  6. If `command.action == "changes_requested"` and `command.message is None` → raise
     `ForbiddenDomainError("A message is required when requesting changes")`.
  7. Return `await self._port.apply_decision(post.id, post.uuid, command.action,
     command.requester_user_id, command.message)`.

Imports `ForbiddenDomainError`, `NotFoundDomainError`, `DuplicateValueDomainError` from
`domain/errors.py` via relative path (`....domain.errors` — five levels up from
`moderate_post/domain/use_case.py`). Never raises `HTTPException`. Never catches.

### Step 6 — Data: Adapter

**File:** `src/app/features/posts/moderate_post/data/adapter.py`

Header: `# FEATURE: moderate_post — data adapter.`

`class ModeratePostAdapter(ModeratePostPort)` — explicit inheritance mandatory per
`agent_docs/architecture.md` § Adapter pattern (canonical).

Constructor: `__init__(self, session_factory: async_sessionmaker[AsyncSession])`.

**`get_post_by_uuid(post_uuid)`** — `SELECT id, uuid, status, created_by_user_id FROM
post WHERE uuid = post_uuid`. Return a mapped `PostForModeration` if found, else `None`.
No `try/except` per `agent_docs/error_handling.md` § Right shape: read-only query, no
catch.

**`apply_decision(post_id, post_uuid, action, moderator_user_id, message)`** — within a
single session context:
1. `UPDATE post SET status = action, updated_at = now() WHERE id = post_id` and commit.
2. `INSERT INTO post_moderation_log (post_id, user_id, event_type, action, message)
   VALUES (post_id, moderator_user_id, "moderator_review", action, message)`, then
   `session.refresh(log_model)` to populate `id` and `created_at`.
3. Return `ModeratedPostResult(post_uuid=post_uuid, status=action, log_entry=ModerationLogEntry(...))`.

Both operations share the same session and a single `await session.commit()`. No
`try/except` — an `UPDATE status` and `INSERT` log row carry no unique constraints that
would produce a business-meaningful `IntegrityError`; any infrastructure failure
propagates to the global handler per `agent_docs/error_handling.md`.

Import the `Post` ORM model from `adapters/db/models/post.py` and the
`PostModerationLog` ORM model from `adapters/db/models/post_moderation_log.py` via
relative imports.

### Step 7 — Presentation: Schemas

**File:** `src/app/features/posts/moderate_post/presentation/schemas.py`

Header: `# FEATURE: moderate_post — request/response schemas.`

```python
class ModeratePostRequest(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    action: Literal["approved", "changes_requested"]
    message: str | None = None

    @model_validator(mode="after")
    def message_required_for_changes(self) -> "ModeratePostRequest":
        if self.action == "changes_requested" and self.message is None:
            raise ValueError("message is required when action is changes_requested")
        return self

class ModerationLogEntrySchema(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    event_type: str
    action: str | None
    message: str | None
    created_at: datetime

class ModeratePostResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    post_uuid: UUID
    status: str
    log_entry: ModerationLogEntrySchema
```

The `@model_validator` enforces the `message` requirement at the schema boundary (HTTP
422) before the use-case is invoked. The use-case enforces the same rule as second-layer
defence for non-HTTP callers.

### Step 8 — Presentation: Router

**File:** `src/app/features/posts/moderate_post/presentation/router.py`

Header: `# FEATURE: moderate_post — HTTP router.`

Use the lazy-container-import pattern established in `assign_moderator`:

```python
def _get_moderate_post_use_case() -> ModeratePostUseCase:
    from .....bootstrap.container import container  # noqa: PLC0415
    return container.moderate_post_use_case()
```

Endpoint:

```python
@router.post(
    "/posts/{post_uuid}/moderate",
    response_model=ModeratePostResponse,
    status_code=status.HTTP_200_OK,
)
async def moderate_post_endpoint(
    post_uuid: UUID,
    request: ModeratePostRequest,
    use_case: Annotated[ModeratePostUseCase, Depends(_get_moderate_post_use_case)],
    current_user: Annotated[dict, Depends(get_current_moderator_or_superuser)],
) -> ModeratePostResponse:
    command = ModeratePostCommand(
        post_uuid=post_uuid,
        requester_user_id=current_user["id"],
        requester_is_privileged=bool(
            current_user.get("is_moderator") or current_user.get("is_superuser")
        ),
        action=request.action,
        message=request.message,
    )
    result = await use_case(command)
    return ModeratePostResponse(
        post_uuid=result.post_uuid,
        status=result.status,
        log_entry=ModerationLogEntrySchema(
            id=result.log_entry.id,
            event_type=result.log_entry.event_type,
            action=result.log_entry.action,
            message=result.log_entry.message,
            created_at=result.log_entry.created_at,
        ),
    )
```

Import `get_current_moderator_or_superuser` from `.....features.users.dependencies`
(relative). No business logic. No `try/except`. No direct DB access.

### Step 9 — DI wiring: Container

**File:** `src/app/bootstrap/container.py` (STABLE — two-line addition)

Add after the last existing use-case provider:

```python
moderate_post_adapter = providers.Factory(
    ModeratePostAdapter,
    session_factory=session_factory,
)

moderate_post_use_case = providers.Factory(
    ModeratePostUseCase,
    port=moderate_post_adapter,
)
```

Add the two corresponding imports at the top of the file alongside existing feature
imports.

### Step 10 — Router registration

**File:** `src/app/features/posts/router.py` (FEATURE file)

Add one import and one `include_router` call following the existing pattern:

```python
from .moderate_post.presentation.router import router as moderate_post_router
# ...
router.include_router(moderate_post_router)
```

`bootstrap/router.py` is **not touched** — it already aggregates `posts_router`, which
in turn aggregates all post slice sub-routers.

### Step 11 — Verify

```
ruff format src/app
ruff check src/app
mypy src/app
pytest
```

Outside-in test specifically:

```
pytest tests/features/posts/0017_moderate_post/moderate_post_outside_in_test.py -v
```

The slice is not done until all of the above pass, including the smoke test
(`tests/smoke/test_app_starts.py`).

## 6. Tests planned

- **Use-case unit test** —
  `tests/features/posts/0017_moderate_post/domain/test_use_case.py`.
  Mock `ModeratePostPort` (a `MagicMock` satisfying the protocol).
  Seven cases:
  - `requester_is_privileged=False` → `ForbiddenDomainError`; assert
    `port.get_post_by_uuid` is never called.
  - `port.get_post_by_uuid` returns `None` → `NotFoundDomainError`; assert
    `port.apply_decision` is never called.
  - Post `created_by_user_id` equals `requester_user_id` → `ForbiddenDomainError`
    (self-review).
  - Post `status = "approved"` → `DuplicateValueDomainError`.
  - `action = "changes_requested"`, `message = None` → `ForbiddenDomainError`.
  - Happy path — approve: port methods succeed; assert `apply_decision` called with
    `action="approved"`, `message=None`; assert returned entity matches port's return.
  - Happy path — changes_requested: same, with `action="changes_requested"` and a
    non-null `message`.
  Prior art: `tests/features/users/0015_assign_moderator/domain/test_use_case.py`.

- **Adapter unit test** —
  `tests/features/posts/0017_moderate_post/data/test_adapter.py`.
  Uses a real async session against the test Postgres database.
  Four cases:
  - `get_post_by_uuid` — UUID not found: assert `None` returned.
  - `get_post_by_uuid` — UUID found: insert a post row; assert returned
    `PostForModeration` fields match the row.
  - `apply_decision` — approve happy path: insert a `pending_review` post; call
    `apply_decision` with `action="approved"`; assert returned `ModeratedPostResult` has
    `status="approved"`, `log_entry.event_type="moderator_review"`,
    `log_entry.action="approved"`; fetch the post row and assert `status="approved"`.
  - `apply_decision` — changes_requested: same, verifying `action="changes_requested"`
    and that `message` is stored in the log row.
  Prior art: `tests/features/users/0001_create_user/data/test_adapter.py`.

- **Endpoint integration test** —
  `tests/features/posts/0017_moderate_post/presentation/test_router.py`.
  `httpx.AsyncClient` against the running app with test Postgres.
  Nine cases:
  - No Authorization header → 401.
  - Valid token, non-moderator non-superuser → 403.
  - Moderator moderates their own post → 403 (self-review).
  - Moderator token, non-existent UUID → 404.
  - Post already `approved`, moderate again → 409.
  - `action="changes_requested"`, no `message` → 422.
  - `action="approved"`, valid post → 200; assert `status="approved"` and
    `log_entry.event_type="moderator_review"` in body.
  - `action="changes_requested"`, with `message` → 200; assert `action` and `message`
    in `log_entry`.
  - Superuser (not moderator) can moderate → 200.
  Prior art: `tests/features/posts/0011_create_post/presentation/test_router.py`.

- **Outside-in test** —
  `tests/features/posts/0017_moderate_post/moderate_post_outside_in_test.py`.
  Full HTTP stack with real adapter, test Postgres, no mocks.
  Six-step scenario:
  1. Create a regular user (the post author) via `POST /users`.
  2. Authenticate as the author; create a post — assert response `status` is
     `pending_review`.
  3. Create a moderator user (set `is_moderator=True` directly in the DB via the test
     session or fixture).
  4. Authenticate as the moderator.
  5. `POST /posts/{post_uuid}/moderate` with `action="approved"` — assert HTTP 200 and
     `status="approved"` in the response.
  6. Fetch the post row directly from the DB and assert `status="approved"` and a
     `PostModerationLog` row exists with `event_type="moderator_review"`.
  Acceptance gate: the slice is not done until this test is green.

**Opt-outs:** none — all four test levels apply.

## 7. Out of scope for this slice

- Transitioning an `approved` post to any other state.
- Moderating a post that is in `changes_requested` state (allowed only after the author
  revises it in slice 0018 `revise_post`, which returns the post to `pending_review`).
- Returning the full post body (title, text, media_url) in the moderation response.
- Paginating or filtering the moderation log.
- Notifications (email or in-app) to the author.
- Bulk moderation.
- `get_current_moderator_or_superuser` gating on `list_pending_posts` — that is slice
  0019's responsibility; the dependency is introduced here and reused there.
- Rate limiting — endpoint is behind moderator/superuser auth.
- Cache invalidation — no caching currently applied to post detail reads.

## 8. Open questions

None — all decisions resolved in the PRD.
