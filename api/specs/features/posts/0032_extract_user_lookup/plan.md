# 0032 · extract_user_lookup — Implementation plan

## 1. Header

- **Feature:** posts
- **Slice:** 0032_extract_user_lookup
- **PRD:** ./prd.md
- **Reference slice:** ../../infra/0025_refactor_token_blacklist/plan.md (pure refactor, no API change)
- **HTTP path:** none — pure refactor; all four post endpoints keep their existing HTTP contracts unchanged
- **STABLE files touched:**
  - `src/app/bootstrap/container.py` — add `user_lookup_adapter` provider; update four use-case providers to receive it

## 2. Context summary

`get_user_by_username` is declared and implemented verbatim in four post slice ports and
adapters (`create_post`, `update_post`, `erase_post`, `erase_db_post`). Each port pollutes its
interface with a cross-cutting concern that has nothing to do with the post operation itself, and
each adapter duplicates the same `SELECT … WHERE username = ? AND is_deleted = False` query. This
slice extracts user resolution into a single `UserLookupPort` protocol and `UserLookupAdapter`
class, both living in `posts/_shared/`. A new `UserIdentity` entity (fields: `id: int`,
`username: str`) replaces the existing `PostAuthor` throughout. Each use-case gains a second
constructor parameter `user_lookup: UserLookupPort` and calls
`self._user_lookup.get_active_user_by_username(username)` instead of the former per-slice port
method. The method name encodes the `is_deleted = False` filter as part of the public contract.
No HTTP endpoint, request schema, response schema, or database schema changes. The acceptance
gate is the four existing outside-in tests remaining green throughout.

**Architecture note:** placing a port and adapter in `_shared/` departs from the default rule
("ports declare one per use-case"). This is an explicit product decision recorded in the PRD:
the `UserLookupPort` is genuinely shared across four slices of the same feature boundary and
acts as a single-method read surface — the role `_shared/repository.py` fills in the
architecture doc.

## 3. API contract

No new HTTP contract. All four existing endpoints are unchanged from the consumer's perspective.

| Endpoint | Change |
|---|---|
| `POST /api/v1/posts` | internal wiring only; request/response/status codes unchanged |
| `PATCH /api/v1/posts/{post_id}` | internal wiring only; request/response/status codes unchanged |
| `DELETE /api/v1/posts/{post_id}` (soft) | internal wiring only; request/response/status codes unchanged |
| `DELETE /api/v1/posts/{post_id}/db` | internal wiring only; request/response/status codes unchanged |

Acceptance signal: `pytest tests/features/posts/` exits 0 with all four existing outside-in
tests green.

## 4. File structure

No new slice folder is created. Changes span `posts/_shared/` (new files) and the four existing
slice folders (modified files). The DI container is updated once.

```
src/app/features/posts/
├── _shared/
│   ├── entities.py                  ← modify: add UserIdentity, delete PostAuthor
│   ├── user_lookup_port.py          ← create: UserLookupPort protocol
│   └── user_lookup_adapter.py       ← create: UserLookupAdapter
│
├── create_post/
│   ├── domain/
│   │   ├── ports/create_post_port.py  ← modify: remove get_user_by_username
│   │   └── use_case.py                ← modify: inject user_lookup, call get_active_user_by_username
│   └── data/adapter.py               ← modify: remove get_user_by_username method
│
├── update_post/
│   ├── domain/
│   │   ├── ports/update_post_port.py  ← modify: remove get_user_by_username
│   │   └── use_case.py                ← modify: inject user_lookup, call get_active_user_by_username
│   └── data/adapter.py               ← modify: remove get_user_by_username method
│
├── erase_post/
│   ├── domain/
│   │   ├── ports/erase_post_port.py   ← modify: remove get_user_by_username
│   │   └── use_case.py                ← modify: inject user_lookup, call get_active_user_by_username
│   └── data/adapter.py               ← modify: remove get_user_by_username method
│
└── erase_db_post/
    ├── domain/
    │   ├── ports/erase_db_post_port.py ← modify: remove get_user_by_username
    │   └── use_case.py                 ← modify: inject user_lookup, call get_active_user_by_username
    └── data/adapter.py                ← modify: remove get_user_by_username method

src/app/bootstrap/container.py  ← STABLE, modify: add user_lookup_adapter provider, update 4 use-case providers
```

## 5. Implementation steps

### Step 1 — Shared entity: replace `PostAuthor` with `UserIdentity`

File: `src/app/features/posts/_shared/entities.py`

In the existing file (header: `# FEATURE: posts._shared — PostItem and PostPage domain entities.`):

- Add `UserIdentity` above `PostItem`:
  ```python
  class UserIdentity(BaseModel):
      model_config = ConfigDict(from_attributes=True)

      id: int
      username: str
  ```
- Delete the `PostAuthor` class entirely.

The header stays as-is (the `—` description can be updated to "shared domain entities" but this
is cosmetic). The `ConfigDict(from_attributes=True)` is required because `model_validate(user)`
is called with an ORM model instance in the adapter.

Verify: `mypy src/app` will flag all remaining `PostAuthor` references as errors — this is
expected and guides the subsequent steps.

### Step 2 — Shared port: create `UserLookupPort`

File: `src/app/features/posts/_shared/user_lookup_port.py` (new)

```python
# FEATURE: posts._shared — UserLookupPort protocol.
from typing import Protocol, runtime_checkable

from .entities import UserIdentity


@runtime_checkable
class UserLookupPort(Protocol):
    async def get_active_user_by_username(self, username: str) -> UserIdentity | None: ...
```

Rules applied:
- `@runtime_checkable` per CLAUDE.md hard rule on ports.
- Method name `get_active_user_by_username` encodes the `is_deleted = False` filter as per PRD.
- Returns `UserIdentity | None` — caller checks for `None` and raises `NotFoundDomainError`.

Verify: `mypy src/app` — the new Protocol is structurally complete (one method).

### Step 3 — Shared adapter: create `UserLookupAdapter`

File: `src/app/features/posts/_shared/user_lookup_adapter.py` (new)

```python
# FEATURE: posts._shared — UserLookupAdapter.
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from ....adapters.db.models.user import User
from .entities import UserIdentity
from .user_lookup_port import UserLookupPort


class UserLookupAdapter(UserLookupPort):
    def __init__(self, session_factory: async_sessionmaker[AsyncSession]) -> None:
        self._session_factory = session_factory

    async def get_active_user_by_username(self, username: str) -> UserIdentity | None:
        async with self._session_factory() as session:
            result = await session.execute(
                select(User).where(User.username == username, User.is_deleted.is_(False))
            )
            user = result.scalar_one_or_none()
            if user is None:
                return None
            return UserIdentity.model_validate(user)
```

No `try/except`: a read-only query has no business-meaningful infrastructure exception to
translate. Per `agent_docs/error_handling.md`, `OperationalError` propagates to the global
handler as a 500. The explicit `class UserLookupAdapter(UserLookupPort):` inheritance is
mandatory per CLAUDE.md.

Verify: `mypy src/app` — passes. `isinstance(UserLookupAdapter(...), UserLookupPort)` returns
`True` (runtime_checkable).

### Step 4 — `create_post`: update port, use-case, adapter

**Port** — `src/app/features/posts/create_post/domain/ports/create_post_port.py`:

Remove `get_user_by_username`. Keep only `create`:
```python
# FEATURE: create_post — port protocol.
from typing import Protocol, runtime_checkable

from ..commands import CreatePostInternalCommand
from ..entities import CreatedPost


@runtime_checkable
class CreatePostPort(Protocol):
    async def create(self, command: CreatePostInternalCommand) -> CreatedPost: ...
```

Remove the `PostAuthor` import.

**Use-case** — `src/app/features/posts/create_post/domain/use_case.py`:

Add `UserLookupPort` as second constructor parameter. Replace the port call:
```python
# FEATURE: create_post — use case.
from .....domain.errors import ForbiddenDomainError, NotFoundDomainError
from ...._shared.user_lookup_port import UserLookupPort
from .commands import CreatePostCommand, CreatePostInternalCommand
from .entities import CreatedPost
from .ports.create_post_port import CreatePostPort


class CreatePostUseCase:
    def __init__(self, port: CreatePostPort, user_lookup: UserLookupPort) -> None:
        self._port = port
        self._user_lookup = user_lookup

    async def __call__(self, command: CreatePostCommand) -> CreatedPost:
        author = await self._user_lookup.get_active_user_by_username(command.target_username)
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

**Adapter** — `src/app/features/posts/create_post/data/adapter.py`:

Remove `get_user_by_username` method and all its imports (`User`, `PostAuthor`). Keep only `create`.

Verify after this step: `mypy src/app` — no `PostAuthor` references in `create_post/`.

### Step 5 — `update_post`: update port, use-case, adapter

**Port** — `src/app/features/posts/update_post/domain/ports/update_post_port.py`:

Remove `get_user_by_username`. Keep `get_post_by_id` and `update`. Remove `PostAuthor` import.

```python
# FEATURE: update_post — port protocol.
from typing import Protocol, runtime_checkable

from ...._shared.entities import PostItem
from ..commands import UpdatePostCommand


@runtime_checkable
class UpdatePostPort(Protocol):
    async def get_post_by_id(self, post_id: int) -> PostItem | None: ...
    async def update(self, command: UpdatePostCommand) -> None: ...
```

**Use-case** — `src/app/features/posts/update_post/domain/use_case.py`:

Add `user_lookup: UserLookupPort` as second parameter. Replace `self._port.get_user_by_username`
with `self._user_lookup.get_active_user_by_username`:

```python
# FEATURE: update_post — use case.
from .....domain.errors import ForbiddenDomainError, NotFoundDomainError
from ...._shared.user_lookup_port import UserLookupPort
from .commands import UpdatePostCommand
from .ports.update_post_port import UpdatePostPort


class UpdatePostUseCase:
    def __init__(self, port: UpdatePostPort, user_lookup: UserLookupPort) -> None:
        self._port = port
        self._user_lookup = user_lookup

    async def __call__(self, command: UpdatePostCommand) -> None:
        author = await self._user_lookup.get_active_user_by_username(command.target_username)
        if author is None:
            raise NotFoundDomainError("User not found")
        if command.requester_username != author.username:
            raise ForbiddenDomainError("You can only update your own posts")
        post = await self._port.get_post_by_id(command.post_id)
        if post is None:
            raise NotFoundDomainError("Post not found")
        await self._port.update(command)
```

**Adapter** — `src/app/features/posts/update_post/data/adapter.py`:

Remove `get_user_by_username` method and its imports.

### Step 6 — `erase_post`: update port, use-case, adapter

**Port** — `src/app/features/posts/erase_post/domain/ports/erase_post_port.py`:

Remove `get_user_by_username`. Keep `find_post` and `soft_delete`. Remove `PostAuthor` import.

```python
# FEATURE: erase_post — port protocol.
from typing import Protocol, runtime_checkable

from ..entities import ErasePostRecord


@runtime_checkable
class ErasePostPort(Protocol):
    async def find_post(self, post_id: int, owner_id: int) -> ErasePostRecord | None: ...
    async def soft_delete(self, post_id: int) -> None: ...
```

**Use-case** — `src/app/features/posts/erase_post/domain/use_case.py`:

```python
# FEATURE: erase_post — use case.
from .....domain.errors import NotFoundDomainError
from ...._shared.user_lookup_port import UserLookupPort
from ..._shared.policies import check_post_owner
from .commands import ErasePostCommand
from .ports.erase_post_port import ErasePostPort


class ErasePostUseCase:
    def __init__(self, port: ErasePostPort, user_lookup: UserLookupPort) -> None:
        self._port = port
        self._user_lookup = user_lookup

    async def __call__(self, command: ErasePostCommand) -> None:
        user = await self._user_lookup.get_active_user_by_username(command.username)
        if user is None:
            raise NotFoundDomainError("User not found")
        check_post_owner(command.requester_username, user.username)
        post = await self._port.find_post(command.post_id, owner_id=user.id)
        if post is None:
            raise NotFoundDomainError("Post not found")
        await self._port.soft_delete(command.post_id)
```

**Adapter** — `src/app/features/posts/erase_post/data/adapter.py`:

Remove `get_user_by_username` method and its imports.

### Step 7 — `erase_db_post`: update port, use-case, adapter

**Port** — `src/app/features/posts/erase_db_post/domain/ports/erase_db_post_port.py`:

Remove `get_user_by_username`. Keep `find_post` and `hard_delete`. Remove `PostAuthor` import.

```python
# FEATURE: erase_db_post — port protocol.
from typing import Protocol, runtime_checkable

from ..entities import EraseDbPostRecord


@runtime_checkable
class EraseDbPostPort(Protocol):
    async def find_post(self, post_id: int, owner_id: int) -> EraseDbPostRecord | None: ...
    async def hard_delete(self, post_id: int) -> None: ...
```

**Use-case** — `src/app/features/posts/erase_db_post/domain/use_case.py`:

```python
# FEATURE: erase_db_post — use case.
from .....domain.errors import NotFoundDomainError
from ...._shared.user_lookup_port import UserLookupPort
from .commands import EraseDbPostCommand
from .ports.erase_db_post_port import EraseDbPostPort


class EraseDbPostUseCase:
    def __init__(self, port: EraseDbPostPort, user_lookup: UserLookupPort) -> None:
        self._port = port
        self._user_lookup = user_lookup

    async def __call__(self, command: EraseDbPostCommand) -> None:
        user = await self._user_lookup.get_active_user_by_username(command.username)
        if user is None:
            raise NotFoundDomainError("User not found")
        post = await self._port.find_post(command.post_id, owner_id=user.id)
        if post is None:
            raise NotFoundDomainError("Post not found")
        await self._port.hard_delete(command.post_id)
```

**Adapter** — `src/app/features/posts/erase_db_post/data/adapter.py`:

Remove `get_user_by_username` method and its imports.

### Step 8 — DI container: add shared provider and update four use-cases

File: `src/app/bootstrap/container.py` (STABLE)

Add import:
```python
from ..features.posts._shared.user_lookup_adapter import UserLookupAdapter
```

Add provider (alongside other adapter providers, before the post use-case providers):
```python
user_lookup_adapter = providers.Factory(
    UserLookupAdapter,
    session_factory=session_factory,
)
```

Update each of the four post use-case providers to pass `user_lookup`:
```python
create_post_use_case = providers.Factory(
    CreatePostUseCase,
    port=create_post_adapter,
    user_lookup=user_lookup_adapter,
)

update_post_use_case = providers.Factory(
    UpdatePostUseCase,
    port=update_post_adapter,
    user_lookup=user_lookup_adapter,
)

erase_post_use_case = providers.Factory(
    ErasePostUseCase,
    port=erase_post_adapter,
    user_lookup=user_lookup_adapter,
)

erase_db_post_use_case = providers.Factory(
    EraseDbPostUseCase,
    port=erase_db_post_adapter,
    user_lookup=user_lookup_adapter,
)
```

No new router module needs to be added to `wiring_config` — `UserLookupPort` is injected into
use-cases via the container, not into any router directly.

### Step 9 — Full verification

```
ruff format src/app
ruff check src/app
mypy src/app
pytest
```

Run the four existing outside-in tests explicitly to confirm the acceptance gate:
```
pytest tests/features/posts/ -k "outside_in" -v
```

All tests must be green. The smoke test (`tests/smoke/test_app_starts.py`) boots the app under a
subprocess and catches import path issues that the pytest `pythonpath = ["src"]` setting masks;
it must also pass.

## 6. Tests planned

**Use-case unit tests** (four files, one per slice) — updated in place:

- `tests/features/posts/0011_create_post/domain/test_use_case.py`
- `tests/features/posts/0028_update_post/domain/test_use_case.py`
- `tests/features/posts/0029_erase_post/domain/test_use_case.py`
- `tests/features/posts/0030_erase_db_post/domain/test_use_case.py`

Each test mocks both the per-slice port (`CreatePostPort`, etc.) and the new `UserLookupPort`.
Scenarios to cover:
- Happy path: `get_active_user_by_username` returns `UserIdentity` → operation proceeds.
- `get_active_user_by_username` returns `None` → `NotFoundDomainError` is raised.
- (Where applicable) requester username does not match owner → `ForbiddenDomainError` is raised.

**Adapter unit test for `UserLookupAdapter`** — new file:
`tests/features/posts/0032_extract_user_lookup/data/test_user_lookup_adapter.py`

Mock the `async_sessionmaker` and `AsyncSession` context manager. Scenarios:
- Active user found → returns `UserIdentity` with correct `id` and `username`.
- User exists but `is_deleted = True` → returns `None`.
- Username does not exist → returns `None`.
- `OperationalError` from `session.execute` propagates unchanged (no catch in adapter).

**Endpoint integration tests** — **opted out** for all four slices. No HTTP contract changes;
the existing integration tests cover request/response/status-code behavior and will remain green.

**Outside-in test** — **opted out for new file.** The PRD decision: no new outside-in test is
written because no user-visible behavior changes. The acceptance gate is the four existing
outside-in tests for `create_post`, `update_post`, `erase_post`, and `erase_db_post` remaining
green throughout the refactor.

## 7. Out of scope for this slice

- Applying the same extraction to user-feature slices (`delete_user`, `delete_db_user`,
  `revoke_moderator`, etc.). That is phase 2 and a separate slice.
- Promoting `UserIdentity`, `UserLookupPort`, or `UserLookupAdapter` to the STABLE layer
  (`domain/shared/`, `ports/`, `adapters/db/`). Phase 2 only.
- Any change to HTTP endpoints, request/response schemas, or OpenAPI contracts.
- Any database migration.
- Role or permission checking beyond what already exists in `posts/_shared/policies.py`.
- The existing `get_user_by_username` slice in `features/users/` (slice 0004); it is an
  unrelated HTTP endpoint for external consumers.

## 8. Open questions

None. All decisions are stated in the PRD.
