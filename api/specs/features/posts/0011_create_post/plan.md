# 0011 · create_post — Implementation plan

## 1. Header

- **Feature:** posts
- **Slice:** 0011_create_post
- **PRD:** ./prd.md
- **Reference slice (if any):** `specs/features/users/0001_create_user/plan.md` — same create-operation shape.
- **HTTP path:** `POST /api/v1/{username}/post`
- **STABLE files touched:**
  - `bootstrap/container.py` — two new providers appended (`create_post_adapter`, `create_post_use_case`). Permitted as part of normal feature work.
  - `features/posts/router.py` — FEATURE file (not STABLE); `write_post` handler removed, sub-router included.

## 2. Context summary

An authenticated API consumer sends a title, body text, and an optional media URL to
`POST /api/v1/{username}/post`. The new slice extracts this logic from the fat `write_post`
handler in `features/posts/router.py` into a fully conformant hexagonal slice. The use-case
resolves the target user by username, enforces that the requester matches the target user
(ownership check), builds an internal command with the resolved user ID, and delegates
persistence to the port. The old `write_post` handler is deleted after the slice is in place.
The response is HTTP 201 with the created post's public fields.

## 3. API contract

**Request body** (`CreatePostRequest`):

| Field | Type | Validation |
|---|---|---|
| `title` | `str` | `min_length=1`, `max_length=30` |
| `text` | `str` | `min_length=1`, `max_length=63206` |
| `media_url` | `str \| None` | optional, no format validation |

`model_config = ConfigDict(extra="forbid")`

**Path params:**

| Param | Type |
|---|---|
| `username` | `str` |

**Auth:** `get_current_user` dependency (from `features/users/dependencies.py`); returns
`dict[str, Any]` with at minimum `id` and `username` keys.

**Response body** (`CreatePostResponse`):

| Field | Type |
|---|---|
| `id` | `int` |
| `title` | `str` |
| `text` | `str` |
| `media_url` | `str \| None` |
| `created_by_user_id` | `int` |
| `created_at` | `datetime` |

**Status codes:**

- `201 Created` — post created successfully.
- `403 Forbidden` — `ForbiddenDomainError`: authenticated user's username differs from the path `{username}`.
- `404 Not Found` — `NotFoundDomainError`: no active user found for `{username}`.
- `422 Unprocessable Entity` — Pydantic field-level validation failure (missing field, wrong type, extra field).

## 4. File structure

New files created:

```
src/app/features/posts/create_post/
├── __init__.py
├── domain/
│   ├── __init__.py
│   ├── commands.py             # CreatePostCommand, CreatePostInternalCommand
│   ├── entities.py             # PostAuthor, CreatedPost
│   ├── ports/
│   │   ├── __init__.py
│   │   └── create_post_port.py # CreatePostPort (Protocol)
│   └── use_case.py             # CreatePostUseCase
├── data/
│   ├── __init__.py
│   └── adapter.py              # CreatePostAdapter(CreatePostPort)
└── presentation/
    ├── __init__.py
    ├── router.py               # POST /{username}/post
    └── schemas.py              # CreatePostRequest, CreatePostResponse
```

No new ORM model. The existing `adapters/db/models/post.py` (`Post`) and
`adapters/db/models/user.py` (`User`) are used read-only by the adapter. No Alembic
migration is required.

Existing files modified:

```
src/app/features/posts/router.py      # remove write_post; include create_post sub-router
src/app/bootstrap/container.py        # two new providers appended
```

## 5. Implementation steps

### Step 1 — Domain: Commands

**File:** `src/app/features/posts/create_post/domain/commands.py`

```python
# FEATURE: create_post — domain commands.
from pydantic import BaseModel


class CreatePostCommand(BaseModel):
    target_username: str
    requester_username: str
    title: str
    text: str
    media_url: str | None


class CreatePostInternalCommand(BaseModel):
    created_by_user_id: int
    title: str
    text: str
    media_url: str | None
```

`CreatePostCommand` carries both usernames so the use-case can enforce ownership without
reading request state. `CreatePostInternalCommand` replaces usernames with the resolved
`created_by_user_id` after the user lookup.

Verify: both classes import cleanly with no framework dependencies.

### Step 2 — Domain: Entities

**File:** `src/app/features/posts/create_post/domain/entities.py`

```python
# FEATURE: create_post — domain entities.
from datetime import datetime

from pydantic import BaseModel, ConfigDict


class PostAuthor(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    username: str


class CreatedPost(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    title: str
    text: str
    media_url: str | None
    created_by_user_id: int
    created_at: datetime
```

`PostAuthor` is returned by the port's user-lookup method. `CreatedPost` is returned by
`port.create()` and mapped to the HTTP response. Both are slice-local and do not reuse
`posts/_shared/` types. `model_config = ConfigDict(from_attributes=True)` allows direct
`.model_validate(orm_row)` in the adapter.

### Step 3 — Domain: Port

**File:** `src/app/features/posts/create_post/domain/ports/create_post_port.py`

```python
# FEATURE: create_post — port protocol.
from typing import Protocol, runtime_checkable

from ..commands import CreatePostInternalCommand
from ..entities import CreatedPost, PostAuthor


@runtime_checkable
class CreatePostPort(Protocol):
    async def get_user_by_username(self, username: str) -> PostAuthor | None: ...
    async def create(self, command: CreatePostInternalCommand) -> CreatedPost: ...
```

Two methods are required because the use-case performs a user lookup before the write;
both responsibilities are inseparable for this slice. Per `agent_docs/architecture.md`,
a two-method port is acceptable when the methods serve one use-case. The `@runtime_checkable`
decorator is mandatory per CLAUDE.md.

### Step 4 — Domain: Use case

**File:** `src/app/features/posts/create_post/domain/use_case.py`

```python
# FEATURE: create_post — use case.
from ...domain.errors import ForbiddenDomainError, NotFoundDomainError
from .commands import CreatePostCommand, CreatePostInternalCommand
from .entities import CreatedPost
from .ports.create_post_port import CreatePostPort


class CreatePostUseCase:
    def __init__(self, port: CreatePostPort) -> None:
        self._port = port

    async def __call__(self, command: CreatePostCommand) -> CreatedPost:
        author = await self._port.get_user_by_username(command.target_username)
        if author is None:
            raise NotFoundDomainError("User not found")
        if command.requester_username != author.username:
            raise ForbiddenDomainError("You can only post under your own username")
        internal = CreatePostInternalCommand(
            created_by_user_id=author.id,
            title=command.title,
            text=command.text,
            media_url=command.media_url,
        )
        return await self._port.create(internal)
```

The import path for `DomainError` subclasses uses the correct relative path from within the
slice's `domain/` folder back up to `app/domain/errors.py`. The use-case raises only
`DomainError` subclasses and never catches. Error handling per `agent_docs/error_handling.md`.

**Note on imports:** `domain/` must not import `adapters/`, `core/`, or any framework.
`app.domain.errors` is `domain/` importing from `domain/` — permitted. The relative import
path from `features/posts/create_post/domain/use_case.py` to `app/domain/errors.py` is
`from ....domain.errors import ...` (four dots: create_post/domain → posts → features → app).

### Step 5 — Data: Adapter

**File:** `src/app/features/posts/create_post/data/adapter.py`

```python
# FEATURE: create_post — data adapter.
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from ....adapters.db.models.post import Post
from ....adapters.db.models.user import User
from ..domain.commands import CreatePostInternalCommand
from ..domain.entities import CreatedPost, PostAuthor
from ..domain.ports.create_post_port import CreatePostPort


class CreatePostAdapter(CreatePostPort):
    def __init__(self, session_factory: async_sessionmaker[AsyncSession]) -> None:
        self._session_factory = session_factory

    async def get_user_by_username(self, username: str) -> PostAuthor | None:
        async with self._session_factory() as session:
            result = await session.execute(
                select(User).where(User.username == username, User.is_deleted.is_(False))
            )
            user = result.scalar_one_or_none()
            if user is None:
                return None
            return PostAuthor.model_validate(user)

    async def create(self, command: CreatePostInternalCommand) -> CreatedPost:
        async with self._session_factory() as session:
            post = Post(
                created_by_user_id=command.created_by_user_id,
                title=command.title,
                text=command.text,
                media_url=command.media_url,
            )
            session.add(post)
            await session.commit()
            await session.refresh(post)
            return CreatedPost.model_validate(post)
```

Explicit `class CreatePostAdapter(CreatePostPort):` inheritance is mandatory per
`agent_docs/architecture.md`. The `get_user_by_username` method has no try/except —
a SELECT cannot violate constraints; infrastructure failures propagate to the global handler
(per `agent_docs/error_handling.md`). The `create` method also has no try/except: a unique
constraint on the `Post` table is not defined (no unique columns beyond `id` and `uuid`),
so `IntegrityError` is not expected as a business-meaningful event here; any DB failure
propagates unchanged.

The `Post` ORM model uses `MappedAsDataclass` via the project's `Base`; pass only the
columns without server-side defaults (`uuid`, `created_at`, `is_deleted` are handled by
SQLAlchemy defaults and need not be set manually).

### Step 6 — Presentation: Schemas

**File:** `src/app/features/posts/create_post/presentation/schemas.py`

```python
# FEATURE: create_post — request/response schemas.
from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field


class CreatePostRequest(BaseModel):
    model_config = ConfigDict(extra="forbid", from_attributes=True)

    title: str = Field(min_length=1, max_length=30)
    text: str = Field(min_length=1, max_length=63206)
    media_url: str | None = None


class CreatePostResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    title: str
    text: str
    media_url: str | None
    created_by_user_id: int
    created_at: datetime
```

`max_length` values for `title` and `text` mirror the `Post` ORM model column lengths.
`extra="forbid"` on the request rejects unknown fields (per PRD).

### Step 7 — Presentation: Router

**File:** `src/app/features/posts/create_post/presentation/router.py`

```python
# FEATURE: create_post — HTTP router.
from typing import Annotated, Any

from fastapi import APIRouter, Depends, status

from .....features.users.dependencies import get_current_user
from ..domain.commands import CreatePostCommand
from ..domain.use_case import CreatePostUseCase
from .schemas import CreatePostRequest, CreatePostResponse

router = APIRouter(tags=["posts"])


def _get_create_post_use_case() -> CreatePostUseCase:
    from .....bootstrap.container import container  # noqa: PLC0415

    return container.create_post_use_case()


@router.post(
    "/{username}/post",
    response_model=CreatePostResponse,
    status_code=status.HTTP_201_CREATED,
)
async def create_post_endpoint(
    username: str,
    request: CreatePostRequest,
    current_user: Annotated[dict[str, Any], Depends(get_current_user)],
    use_case: Annotated[CreatePostUseCase, Depends(_get_create_post_use_case)],
) -> CreatePostResponse:
    command = CreatePostCommand(
        target_username=username,
        requester_username=current_user["username"],
        title=request.title,
        text=request.text,
        media_url=request.media_url,
    )
    result = await use_case(command)
    return CreatePostResponse.model_validate(result)
```

The local factory `_get_create_post_use_case()` follows the same pattern as `list_posts`
and `list_all_posts` — no `dependency_injector.wiring` needed. No `@cache` decorator
(write operation). No `Request` parameter (no cache). The `requester_username` comes from
`current_user["username"]` (the dict returned by `get_current_user`).

### Step 8 — DI wiring: Container

**File:** `src/app/bootstrap/container.py` — append two providers to the existing `Container` class.

```python
# Add these imports at the top of the file:
from ..features.posts.create_post.data.adapter import CreatePostAdapter
from ..features.posts.create_post.domain.use_case import CreatePostUseCase

# Add these providers inside the Container class, after the list_all_posts providers:
create_post_adapter = providers.Factory(
    CreatePostAdapter,
    session_factory=session_factory,
)

create_post_use_case = providers.Factory(
    CreatePostUseCase,
    port=create_post_adapter,
)
```

No `wiring_config` change needed — this project uses the local factory function pattern
(as seen in `list_posts` and `list_all_posts`) rather than `dependency_injector.wiring`.

### Step 9 — Router integration: features/posts/router.py

Modify `src/app/features/posts/router.py`:

1. **Add** import of the new sub-router:
   ```python
   from .create_post.presentation.router import router as create_post_router
   ```
2. **Add** `router.include_router(create_post_router)` after the existing `include_router` calls.
3. **Delete** the entire `write_post` function (lines 23–47 in the current file).
4. **Remove** `PostCreate` and `PostCreateInternal` from the `.schemas` import line — they
   are no longer used by the router after `write_post` is deleted. `PostRead` and `PostUpdate`
   remain (used by `read_post` and `patch_post`). Note: `PostCreate` and `PostCreateInternal`
   are **not** deleted from `schemas.py` itself (still used by `repository.py` as FastCRUD
   type parameters, per PRD decision).

`bootstrap/router.py` is **not touched** — it already registers `posts_router`.

### Step 10 — Verify

```
ruff format src/app
ruff check src/app
mypy src/app
pytest
```

Outside-in test for this slice:

```
pytest tests/features/posts/0011_create_post/create_post_outside_in_test.py -v
```

A change is not complete until all of the above pass (including the smoke test at
`tests/smoke/test_app_starts.py`).

## 6. Tests planned

- **Use-case unit test** — `tests/features/posts/0011_create_post/domain/test_use_case.py`.
  Mocks `CreatePostPort`. Asserts:
  - `port.get_user_by_username` returns `None` → raises `NotFoundDomainError`.
  - `port.get_user_by_username` returns a `PostAuthor` whose `username` differs from
    `command.requester_username` → raises `ForbiddenDomainError`.
  - Both checks pass → `port.create` is called with a `CreatePostInternalCommand` whose
    `created_by_user_id` matches `author.id`.
  - Return value of `__call__` equals the `CreatedPost` returned by `port.create`.

- **Adapter unit test** — `tests/features/posts/0011_create_post/data/test_adapter.py`.
  Uses a real async session against the test Postgres database (per PRD testing decisions).
  Asserts:
  - `get_user_by_username` returns a `PostAuthor` for an existing active user.
  - `get_user_by_username` returns `None` for a soft-deleted user.
  - `get_user_by_username` returns `None` for an unknown username.
  - `create` seeds a user, inserts a post, returns a `CreatedPost` with correct fields
    including `created_by_user_id`.

- **Endpoint integration test** — `tests/features/posts/0011_create_post/presentation/test_router.py`.
  Uses `httpx.AsyncClient` against the running app with test Postgres. Asserts:
  - Valid payload → HTTP 201, body matches `CreatePostResponse` schema.
  - Unknown username → HTTP 404.
  - Authenticated user's username ≠ path username → HTTP 403.
  - Missing `title` → HTTP 422.
  - Missing `text` → HTTP 422.

- **Outside-in test** — `tests/features/posts/0011_create_post/create_post_outside_in_test.py`.
  Full HTTP stack, real adapter, test Postgres, no mocks except at external boundaries.
  Acceptance gate: authenticate as a user, `POST /{username}/post` with valid body, assert
  HTTP 201 and that the response body matches expected post fields. Must be RED before
  implementation, GREEN after.

**Opt-outs:** none.

## 7. Out of scope for this slice

- Migrating `read_post`, `patch_post`, `erase_post`, or `erase_db_post` to the vertical
  slice pattern.
- Deleting `PostCreate` or `PostCreateInternal` from `posts/schemas.py` (still used by
  `posts/repository.py` as FastCRUD type parameters).
- Adding media upload handling (`media_url` is accepted as a plain optional string).
- Rate limiting on the create-post endpoint.
- `@cache` decorator or cache invalidation (creation has no cached read to invalidate).
- Adding a `_shared/` folder for the posts feature (only one write slice exists; premature).

## 8. Open questions

None. The PRD is complete and prescribes all architectural decisions including the two-method
port, the username-based ownership check, and the `PostAuthor`/`CreatedPost` entity split.
