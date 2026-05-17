# 0013 · moderation_db_foundation — Implementation plan

## 1. Header

- **Feature:** moderation (infra)
- **Slice:** `0013_moderation_db_foundation`
- **PRD:** `./prd.md`
- **Reference slice:** None — no prior DB-only slice exists in the roadmap.
- **HTTP path:** None — this slice has no HTTP entry point.
- **STABLE files touched:**
  - `src/app/adapters/db/models/user.py` — add `is_moderator`, `moderator_granted_by_user_id`
  - `src/app/adapters/db/models/post.py` — add `status`
  - `src/app/adapters/db/models/post_moderation_log.py` — new file
  - `src/app/adapters/db/models/__init__.py` — add `PostModerationLog` import
  - `migrations/versions/<hash>_add_moderation_schema.py` — Alembic autogenerate

  All STABLE changes are authorised by parent PRD
  `specs/features/moderation/0012_moderation/prd.md`.

## 2. Context summary

This slice lays the schema foundation that all subsequent moderation slices
(0014–0022) depend on. It adds two columns to the `user` table
(`is_moderator`, `moderator_granted_by_user_id`), adds a `status` column to
the `post` table (default `pending_review`), and introduces a new
`PostModerationLog` ORM model that stores every moderation event and author
revision as an append-only log. No use-case, port, adapter, or HTTP endpoint
is introduced; the slice's only deliverable is a verified Alembic migration.

## 3. API contract

Not applicable — this slice has no HTTP entry point.

## 4. File structure

```
src/app/adapters/db/models/
├── user.py                        # STABLE — two new Mapped columns
├── post.py                        # STABLE — one new Mapped column
├── post_moderation_log.py         # STABLE — new ORM model (new file)
└── __init__.py                    # STABLE — add PostModerationLog import

migrations/versions/
└── <hash>_add_moderation_schema.py   # Alembic autogenerate output
```

No feature folder is created. No `__init__.py` stubs needed.

## 5. Implementation steps

### Step 1 — `user.py`: add moderator fields

Add two columns after `is_superuser`:

```python
is_moderator: Mapped[bool] = mapped_column(default=False, index=True)
moderator_granted_by_user_id: Mapped[int | None] = mapped_column(
    ForeignKey("user.id"), index=True, default=None, init=False
)
```

`is_moderator` follows the `is_superuser` pattern — no `init=False`, so the
constructor accepts it as an optional argument (defaulting to `False`).

`moderator_granted_by_user_id` follows the `tier_id` pattern — `init=False`
because it is never set at user-creation time; the `assign_moderator` use-case
updates it via a dedicated adapter.

The `ForeignKey("user.id")` self-reference is valid in PostgreSQL: the FK
points to the same `user` table.

Verify: `mypy src/app` must pass after this edit.

### Step 2 — `post.py`: add status field

Add after `is_deleted`, importing `String` if not already present:

```python
status: Mapped[str] = mapped_column(String(20), default="pending_review", index=True)
```

No `init=False` — the `create_post` adapter (slice 0020) will pass `status`
explicitly. Maximum length 20 covers the longest value (`changes_requested`
= 18 characters).

Verify: `mypy src/app` must pass.

### Step 3 — `post_moderation_log.py`: create new model

Create `src/app/adapters/db/models/post_moderation_log.py`:

```python
# STABLE: Infrastructure skeleton. Change only when infra changes.
from datetime import UTC, datetime

from sqlalchemy import DateTime, ForeignKey, String
from sqlalchemy.orm import Mapped, mapped_column

from ..base import Base


class PostModerationLog(Base):
    __tablename__ = "post_moderation_log"

    id: Mapped[int] = mapped_column(autoincrement=True, primary_key=True, init=False)
    post_id: Mapped[int] = mapped_column(ForeignKey("post.id"), index=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("user.id"), index=True)
    event_type: Mapped[str] = mapped_column(String(20))
    action: Mapped[str | None] = mapped_column(String(20), default=None)
    message: Mapped[str | None] = mapped_column(String(2000), default=None)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default_factory=lambda: datetime.now(UTC), init=False
    )
```

`event_type` values: `moderator_review`, `author_revision`.
`action` values: `approved`, `changes_requested` (only populated when
`event_type = moderator_review`).
`created_at` is `init=False` because it is always set by the default factory —
callers never supply it.

The table has no `updated_at`, no `is_deleted`, no `uuid`. It is append-only.

Verify: `mypy src/app` must pass.

### Step 4 — `__init__.py`: register the new model

Add one import line to `src/app/adapters/db/models/__init__.py` (alphabetical
order between `Post` and `RateLimit`):

```python
from .post_moderation_log import PostModerationLog  # noqa: F401
```

Without this line, Alembic's autogenerate cannot discover `PostModerationLog`
and will not generate the table DDL.

### Step 5 — Generate and review the Alembic migration

Run:

```
alembic revision --autogenerate -m "add_moderation_schema"
```

Open the generated file and verify:

1. **`user` table**: `op.add_column` for both `is_moderator` (Boolean, not
   nullable, `server_default='false'`) and `moderator_granted_by_user_id`
   (Integer, nullable, FK to `user.id`).
2. **`post` table**: `op.add_column` for `status` (String(20), not nullable).
   Confirm the migration includes `server_default='pending_review'` so that
   all existing `Post` rows receive the value on upgrade. If Alembic does not
   emit `server_default` automatically, add it manually to the
   `op.add_column(...)` call before running upgrade.
3. **`post_moderation_log` table**: `op.create_table` with all seven columns
   and two `ForeignKeyConstraint` entries (`post.id`, `user.id`).
4. **Indexes**: confirm `op.create_index` entries for `is_moderator`,
   `moderator_granted_by_user_id` on `user`; `status` on `post`; `post_id`,
   `user_id` on `post_moderation_log`.

### Step 6 — Apply the migration

```
alembic upgrade head
```

Confirm with `\d user`, `\d post`, `\d post_moderation_log` in `psql` (or
equivalent) that all columns and indexes are present.

### Step 7 — Verify

```
ruff format src/app
ruff check src/app
mypy src/app
pytest tests/smoke/
```

All four must pass before the slice is considered done.

## 6. Tests planned

This slice introduces no use-case, adapter, or HTTP endpoint.

| Level | Decision |
|---|---|
| Use-case unit test | Opted out — no use-case |
| Adapter unit test | Opted out — no adapter |
| Endpoint integration test | Opted out — no HTTP endpoint |
| Outside-in test | Opted out — DB-only slice per parent PRD (0012) |

Verification is Alembic upgrade + smoke test (Step 7 above).

## 7. Out of scope for this slice

- Use-cases, ports, adapters, or HTTP endpoints for any moderation operation.
- Changes to any Pydantic schema (`UserRead`, `UserMeRead`,
  `GetUserByUsernameResponse`, etc.) — that is slice 0014.
- `CheckConstraint` on `Post.status` or `PostModerationLog.event_type` —
  application-level validation is sufficient for now.
- SQLAlchemy `relationship()` declarations on `User`, `Post`, or
  `PostModerationLog` — adapters use explicit joins via `select()` statements.

## 8. Open questions

None — the parent PRD explicitly states that existing Post rows should enter
`pending_review` after migration, which is handled by `server_default` in
Step 5.
