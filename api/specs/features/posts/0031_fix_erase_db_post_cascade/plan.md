# 0031 · fix_erase_db_post_cascade — Implementation plan

## 1. Header

- **Feature:** posts
- **Slice:** 0031_fix_erase_db_post_cascade
- **PRD:** ./prd.md
- **Reference slice:** `../0030_erase_db_post/plan.md` — the slice being fixed;
  the two new implementation steps modify files created there.
- **HTTP path:** `DELETE /api/v1/{username}/db_post/{id}` (unchanged — no new
  endpoint).
- **STABLE files touched:**
  - `src/app/adapters/db/models/post.py` — add `relationship` to
    `PostModerationLog` with `cascade="all, delete-orphan"`. Requires explicit
    user approval per `agent_docs/stable_vs_feature.md` § When a STABLE change
    is unavoidable.

## 2. Context summary

Slice 0030 (`erase_db_post`) implements `DELETE /api/v1/{username}/db_post/{id}`
as a proper vertical slice. Its `EraseDbPostAdapter.hard_delete` method issues a
Core DML `DELETE FROM post WHERE id=:id`. This fails at runtime with a
`ForeignKeyViolationError` whenever the post has associated `PostModerationLog`
rows, because the FK `post_moderation_log.post_id → post.id` has no `ON DELETE
CASCADE` constraint in the database. This slice fixes the root cause by
declaring the cascade at the ORM model level and rewriting `hard_delete` to use
the ORM session API (`session.delete`), which issues child DELETEs before the
parent DELETE automatically. No HTTP contract changes. No schema changes.

## 3. API contract

**Unchanged.** The HTTP path, method, path parameters, response body, status
codes, auth requirement, and cache-invalidation keys are all identical to those
specified in `../0030_erase_db_post/plan.md` § 3. This slice does not touch the
router, schemas, use case, port, or command.

## 4. File structure

No new files. Two existing files are modified:

```
src/app/
└── adapters/db/models/
    └── post.py                         # STABLE — add relationship to PostModerationLog

src/app/features/posts/erase_db_post/
└── data/
    └── adapter.py                      # FEATURE — rewrite hard_delete; add selectinload import
```

Two existing test files are extended (new test cases added, no test cases
removed):

```
tests/features/posts/0030_erase_db_post/
├── data/
│   └── test_adapter.py                 # add cascade assertion test for hard_delete
└── erase_db_post_outside_in_test.py    # add moderation-log seeding to scenario 1
```

## 5. Implementation steps

### Step 1 — STABLE: Add relationship to Post model

**File:** `src/app/adapters/db/models/post.py`

Add a `moderation_logs` relationship field to the `Post` class, declared after
the existing mapped columns:

```
moderation_logs: Mapped[list["PostModerationLog"]] = relationship(
    cascade="all, delete-orphan",
    lazy="raise",
    init=False,
    repr=False,
    default_factory=list,
)
```

Key choices:

- `cascade="all, delete-orphan"` — instructs SQLAlchemy to issue `DELETE`
  statements for all `PostModerationLog` children before deleting the `Post`
  parent when `session.delete(post)` is called.
- `lazy="raise"` — raises `InvalidRequestError` if any code path attempts an
  implicit lazy load of `moderation_logs`. This enforces that all callers must
  use `selectinload` explicitly; prevents silent `MissingGreenlet` failures in
  async context.
- `init=False, default_factory=list` — required by `MappedAsDataclass`: the
  field is not part of the constructor signature and defaults to an empty list.
- `repr=False` — avoids loading the relationship when `repr(post)` is called
  in logs or debug output.
- No `back_populates` — `PostModerationLog` does not need a back-reference for
  the cascade to work; the relationship is intentionally one-directional.

No import of `PostModerationLog` class is needed at module level; the string
`"PostModerationLog"` is resolved lazily by the SQLAlchemy mapper registry at
configuration time, avoiding a circular import. Both models inherit from the
same `Base`, so the registry resolves the name correctly.

Verify after the change: `alembic revision --autogenerate -m "check"` must
produce an empty migration (no detected schema changes). Discard the empty
revision file without committing it.

### Step 2 — FEATURE: Rewrite `hard_delete` in the adapter

**File:** `src/app/features/posts/erase_db_post/data/adapter.py`

Replace the existing `hard_delete` method body. Add `selectinload` to the
import block (`from sqlalchemy.orm import selectinload`). Remove the `delete`
import from `sqlalchemy` if it is no longer used by any other method in the
adapter (it currently is not).

New `hard_delete`:

```python
async def hard_delete(self, post_id: int) -> None:
    async with self._session_factory() as session:
        result = await session.execute(
            select(Post).where(Post.id == post_id).options(
                selectinload(Post.moderation_logs)
            )
        )
        post = result.scalar_one()
        await session.delete(post)
        await session.commit()
```

Rationale for each line:

- `selectinload(Post.moderation_logs)` — eagerly loads the moderation log rows
  in the same async round-trip. Required because `lazy="raise"` on the
  relationship prevents implicit loading; without this option the
  `session.delete` cascade would trigger `InvalidRequestError`.
- `scalar_one()` (not `scalar_one_or_none()`) — by the time `hard_delete` is
  called, `find_post` has already confirmed the post exists. A `NoResultFound`
  here indicates a race condition (the post was concurrently deleted) and
  should surface as HTTP 500 via the global handler, not silently succeed.
- `session.delete(post)` — stages the ORM delete. SQLAlchemy evaluates the
  `cascade="all, delete-orphan"` rule and issues `DELETE FROM
  post_moderation_log WHERE post_id=:id` before `DELETE FROM post WHERE id=:id`.
- No `try/except` — the cascade eliminates the `ForeignKeyViolationError`. No
  business-meaningful infrastructure exceptions remain to translate (per
  `agent_docs/error_handling.md` § Adapter: catch only when there is business
  meaning to translate).

### Step 3 — Test: Extend adapter unit test

**File:** `tests/features/posts/0030_erase_db_post/data/test_adapter.py`

Add one new test case after the existing `test_hard_delete_removes_row_permanently`:

```
test_hard_delete_removes_post_and_moderation_logs
```

Scenario:

1. Seed a `PostModerationLog` row whose `post_id` references `ep30_alice_post["id"]`.
2. Call `adapter.hard_delete(ep30_alice_post["id"])`.
3. Assert the `post` row no longer exists in the DB (raw `SELECT` via `text()`).
4. Assert the `post_moderation_log` row no longer exists in the DB (raw `SELECT`
   via `text()` on the log's `id`).

This is the authoritative unit-level assertion for the cascade behavior. The
existing `test_hard_delete_removes_row_permanently` test is kept unchanged — it
exercises the non-moderated post path and remains valid.

### Step 4 — Test: Extend outside-in test

**File:**
`tests/features/posts/0030_erase_db_post/erase_db_post_outside_in_test.py`

Extend `test_admin_hard_deletes_post_row_is_gone_and_get_returns_404` (Scenario
1):

- Before the `DELETE` call, seed one `PostModerationLog` row for
  `ep30_alice_post["id"]`.
- After the `DELETE` call and the existing DB assertion on the post row, add a
  second DB assertion confirming that no `post_moderation_log` rows with that
  `post_id` remain.

No changes to Scenario 2 (`test_ownership_enforcement_wrong_namespace_and_non_superuser`)
— it does not exercise the cascade path.

### Step 5 — Verify

```
ruff format src/app
ruff check src/app
mypy src/app
pytest tests/features/posts/0030_erase_db_post/ -v
pytest tests/smoke/test_app_starts.py -v
pytest -v
```

The slice is complete when:

- All 0030 tests pass, including both outside-in scenarios.
- `mypy src/app` reports no errors.
- The smoke test passes.
- No pre-existing outside-in tests are broken.

## 6. Tests planned

- **Use-case unit test** — `tests/features/posts/0030_erase_db_post/domain/test_use_case.py`.
  **No change.** The use case is unchanged; the mocked port contract is
  unchanged.

- **Adapter unit test** — `tests/features/posts/0030_erase_db_post/data/test_adapter.py`.
  **One new test case added** (Step 3 above). Verifies that `hard_delete`
  permanently removes both the post row and its `PostModerationLog` rows.
  Existing test cases are unchanged. Prior art: the existing
  `test_hard_delete_removes_row_permanently` in the same file.

- **Endpoint integration test** — `tests/features/posts/0030_erase_db_post/presentation/test_router.py`.
  **No change.** The HTTP contract is unchanged; the router test already
  asserts the happy-path 200 response. The cascade is an adapter concern not
  visible at the HTTP layer.

- **Outside-in test** — `tests/features/posts/0030_erase_db_post/erase_db_post_outside_in_test.py`.
  **Extended** (Step 4 above). Scenario 1 gains a moderation-log seeding step
  and a post-deletion moderation-log DB assertion. The cascade path is now
  covered end-to-end in the acceptance gate.

**Opt-outs:** none. Both affected test levels (adapter unit and outside-in) are
updated; the two unchanged levels (use-case unit and router integration) are
documented with explicit "no change" justification.

## 7. Out of scope for this slice

- Adding `ON DELETE CASCADE` at the database level — the ORM cascade achieves
  the same result without a migration; no schema change is warranted.
- Adding cascade behavior to any other Post-related table beyond
  `PostModerationLog` — no other FK currently blocks the delete.
- Changing `lazy="raise"` to `lazy="selectin"` on the relationship — that
  would cause every `Post` read to load moderation logs; the `selectinload` at
  the call site is preferable.
- Changing `find_post` or `get_user_by_username` adapter methods — both are
  correct and unaffected.
- Changes to use case, port, command, domain entities, response schema, router,
  DI container, or `.importlinter` — none are needed.
- Cache-invalidation logic changes — the existing `@cache` decorator contract
  is preserved.

## 8. Open questions

None. The STABLE file change (`post.py`) requires user approval before
implementation; approval was given in the conversation preceding this plan
(the user confirmed the two-file approach and accepted the STABLE model
change).
