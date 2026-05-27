# 0059 · remove_username_user_lookup — Implementation plan

## 1. Header

- **Feature:** posts
- **Slice:** 0059_remove_username_user_lookup
- **PRD:** ./prd.md
- **Reference slice (if any):** ../0032_extract_user_lookup/plan.md — same operation
  shape (pure refactor on the shared `UserLookupPort` / `UserLookupAdapter`, no new
  HTTP entry point, acceptance gate = existing outside-in tests stay green). 0032
  *created* the shared lookup surface and the `get_active_user_by_username` method;
  this slice *removes* that method now that it has zero callers.
- **HTTP path:** none — no route, request/response schema, or status code changes.
- **STABLE files touched:** none.
  - `bootstrap/container.py` is **not** touched: it constructs one
    `UserLookupAdapter` via `user_lookup_adapter = providers.Factory(...)` and injects
    it as `UserLookupPort` into the four write use-cases. Removing one method from
    the adapter/port does not change any provider wiring.
  - The two modified source files (`_shared/user_lookup_port.py`,
    `_shared/user_lookup_adapter.py`) are **FEATURE** files
    (`# FEATURE: posts._shared — …`), not STABLE.

## 2. Context summary

The `{username}` → `{user_id}` post-route migration is functionally complete: every
Posts API route identifies the author by integer `user_id`, and every post write
use-case (`create_post`, `update_post`, `erase_post`, `erase_db_post`) resolves the
author through the shared `get_active_user_by_id`. The username-based lookup
`get_active_user_by_username` on `UserLookupPort` / `UserLookupAdapter` was retained
only so not-yet-migrated slices stayed green; it now has **zero `src` callers**
(confirmed by grep — it appears solely in its own port declaration and adapter
implementation). This slice deletes that dead method from the Protocol and the
adapter, leaving `get_active_user_by_id` as the sole user-resolution method, and
prunes the shared adapter test suite accordingly. No behaviour, route, schema, DI,
or database change. The acceptance gate is that the full test suite — including the
four post write slices' outside-in tests, the smoke test, and the import-linter
architecture gate — stays green.

## 3. API contract

No new or changed HTTP contract. All Posts API endpoints are unchanged from the
consumer's perspective.

| Endpoint | Change |
|---|---|
| `POST /api/v1/{author_id}/post` | none — internal helper removal only |
| `PATCH /api/v1/post/{post_id}` | none — internal helper removal only |
| `DELETE /api/v1/post/{post_id}` (soft) | none — internal helper removal only |
| `DELETE /api/v1/post/{post_id}/db` | none — internal helper removal only |

Acceptance signal: `pytest` exits 0, including `tests/smoke/test_app_starts.py` and
the four existing `*_outside_in_test.py` files for create/update/erase/erase_db post.

## 4. File structure

No new slice folder is created. The change is a deletion spanning two `posts/_shared/`
source files and one existing adapter test module.

```
src/app/features/posts/_shared/
├── user_lookup_port.py        ← modify: delete get_active_user_by_username from the Protocol
└── user_lookup_adapter.py     ← modify: delete the get_active_user_by_username method

tests/features/posts/0032_extract_user_lookup/data/
└── test_user_lookup_adapter.py ← modify: drop 3 username behaviour tests,
                                   re-point the OperationalError propagation test
                                   to get_active_user_by_id, keep 3 by-id tests
```

No new ORM model, no `_shared/schemas.py` field changes, no Alembic migration.

**Explicitly NOT changed** (per PRD § What is explicitly NOT removed):

- `_shared/entities.py::UserIdentity.username` — retained. Still populated by
  `get_active_user_by_id` and asserted by its adapter test; a harmless DTO field
  outside this initiative's scope.
- `User.username` display selects in read adapters (`get_post`, `list_posts`,
  `list_all_posts`, `list_pending_posts`, `get_moderation_log`) — frozen by the
  initiative; response bodies still surface the author handle.

## 5. Implementation steps

### Step 1 — Shared port: remove `get_active_user_by_username`

File: `src/app/features/posts/_shared/user_lookup_port.py`

Current Protocol declares both methods. Delete the username method, leaving:

```python
# FEATURE: posts._shared — UserLookupPort protocol.
from typing import Protocol, runtime_checkable

from .entities import UserIdentity


@runtime_checkable
class UserLookupPort(Protocol):
    async def get_active_user_by_id(self, user_id: int) -> UserIdentity | None: ...
```

The `@runtime_checkable` decorator and the `UserIdentity` import are unchanged
(`get_active_user_by_id` still returns `UserIdentity | None`).

Verify: `mypy src/app` — `UserLookupAdapter` still satisfies the now-one-method
Protocol; the four use-cases that depend only on `get_active_user_by_id` still
type-check.

### Step 2 — Shared adapter: remove the `get_active_user_by_username` method

File: `src/app/features/posts/_shared/user_lookup_adapter.py`

Delete the `get_active_user_by_username` method (and its `User.username == username`
`select`). The class continues to inherit the port explicitly and keeps
`get_active_user_by_id` unchanged:

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

    async def get_active_user_by_id(self, user_id: int) -> UserIdentity | None:
        async with self._session_factory() as session:
            result = await session.execute(
                select(User).where(User.id == user_id, User.is_deleted.is_(False))
            )
            user = result.scalar_one_or_none()
            if user is None:
                return None
            return UserIdentity.model_validate(user)
```

**Imports stay as-is:** `select`, `User`, `UserIdentity`, and `UserLookupPort` are all
still used by `get_active_user_by_id`. (Only the `User.username` *column reference*
inside the deleted method goes away; the `User` model import remains.) The explicit
`class UserLookupAdapter(UserLookupPort):` inheritance is mandatory per CLAUDE.md and
is preserved. No `try/except` — a read-only query has no business-meaningful
infrastructure exception to translate; `OperationalError` still propagates to the
global handler per `agent_docs/error_handling.md`.

Verify: `ruff check src/app` reports no unused import; `mypy src/app` passes;
`isinstance(UserLookupAdapter(...), UserLookupPort)` remains `True`.

### Step 3 — Prune the shared adapter test module

File: `tests/features/posts/0032_extract_user_lookup/data/test_user_lookup_adapter.py`

Per PRD § Modified test:

- **Remove** the three `get_active_user_by_username` behaviour tests:
  - `test_get_active_user_by_username_returns_user_identity_for_active_user` (F5/F6)
  - `test_get_active_user_by_username_returns_none_for_unknown_username` (F7)
  - `test_get_active_user_by_username_returns_none_for_soft_deleted_user` (F8)
- **Re-point** the infrastructure-exception-propagation test
  (`test_get_active_user_by_username_propagates_operational_error`, N3) so it calls
  `get_active_user_by_id(123)` instead of `get_active_user_by_username("alice")`.
  Rename it to `test_get_active_user_by_id_propagates_operational_error`. The mocked
  `AsyncSession.execute` `side_effect = OperationalError(...)` and the
  `pytest.raises(OperationalError)` assertion are unchanged — the N3 guarantee
  remains covered by a still-existing method.
- **Keep** the three `get_active_user_by_id` behaviour tests unchanged
  (active-user-found, unknown-id, soft-deleted-user).
- Update the module docstring header: drop the F5/F6/F7/F8 coverage note for the
  username method; keep the by-id and N3 coverage note. After the change, **every
  test in the module exercises a method that still exists.**

Verify: `pytest tests/features/posts/0032_extract_user_lookup/ -v` is green and
contains no reference to `get_active_user_by_username`.

### Step 4 — Verify residual wording (checked invariant, no code change)

Confirm by search that no `ForbiddenDomainError(...)` message (or other user-facing
string) in the posts feature mentions "username":

```
rg -n "username" src/app/features/posts --glob '*.py' | rg -i "forbidden|raise|message"
```

Expected: clean. `create_post` (0055) and `update_post` (0056) already removed their
username-mentioning messages; `erase_post` / `erase_db_post` never had one. Recorded
as a verified invariant, not a change.

Note: the four migration-slice outside-in tests
(`0055`/`0056`/`0057`/`0058`) mention `get_active_user_by_username` **only in their
header comment narrative** describing each slice's historical red-state. These are
comments, not calls — they require no change and are left as historical record.

### Step 5 — Full verification

```
ruff format src/app
ruff check src/app
mypy src/app
pytest
```

Then the acceptance-gate subset explicitly:

```
pytest tests/features/posts/0055_migrate_create_post_route_username_to_user_id/migrate_create_post_route_username_to_user_id_outside_in_test.py \
       tests/features/posts/0056_migrate_update_post_route_username_to_user_id/migrate_update_post_route_username_to_user_id_outside_in_test.py \
       tests/features/posts/0057_migrate_erase_post_route_username_to_user_id/migrate_erase_post_route_username_to_user_id_outside_in_test.py \
       tests/features/posts/0058_migrate_erase_db_post_route_username_to_user_id/migrate_erase_db_post_route_username_to_user_id_outside_in_test.py -v
```

And the architecture gate (import-linter, run from `api/src` with UTF-8 per project
memory):

```
lint-imports
```

Baseline the suite before the change (stash the pre-change failure set) and after,
and prove **zero net-new failures**. Green across `pytest` (incl.
`tests/smoke/test_app_starts.py`), `mypy`, and `lint-imports` is required.

## 6. Tests planned

This slice adds **no behaviour and no entry point**, so the default four-level test
matrix is opted out except for the one existing module that is pruned.

- **Use-case unit test** — **opted out (none new).** No use-case changes; the four
  write use-cases already call only `get_active_user_by_id` and their existing unit
  tests are untouched.
- **Adapter unit test** — **modified in place**, not new:
  `tests/features/posts/0032_extract_user_lookup/data/test_user_lookup_adapter.py`.
  Drop the three username behaviour cases, re-point the `OperationalError`
  propagation case (N3) to `get_active_user_by_id`, keep the three by-id behaviour
  cases. This is the only test file changed by the slice.
- **Endpoint integration test** — **opted out (none new).** No HTTP contract change;
  existing integration tests stay green.
- **Outside-in test** — **opted out (none new).** No new HTTP entry point. The
  acceptance gate is the **existing** outside-in tests for `create_post`,
  `update_post`, `erase_post`, and `erase_db_post` remaining green, proving the
  removed method was genuinely unused. This mirrors how slice 0032 opted out of its
  own outside-in test as a pure refactor.

**Why opt-outs are justified:** a pure dead-code removal introduces no new branch,
no new failure mode, and no observable behaviour. The most meaningful signal is that
the consumers' existing behavioural tests stay green; the only new test work is
pruning and re-pointing the shared adapter tests so every remaining test exercises a
method that still exists.

## 7. Out of scope for this slice

- Removing or renaming `UserIdentity.username` — retained (see § File structure).
- Any `User.username` display select in read adapters or the `username` field in
  response bodies — frozen by the initiative.
- The `check_post_owner` policy — already id-based since slice 0055; unchanged here.
- Any route, schema, DI wiring, or behaviour change — this is a dead-code removal only.
- No Alembic migration, no ORM model change.
- The Flutter client — unaffected by an internal helper removal.

## 8. Open questions

None. The PRD states all decisions; grep confirms `get_active_user_by_username` has
zero `src` callers, so the slice is unblocked.
