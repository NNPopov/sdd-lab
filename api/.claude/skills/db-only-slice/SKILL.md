---
name: db-only-slice
description: Use this skill when implementing a DB-only slice — one that adds ORM models, columns, or tables and an Alembic migration, but has no use-case, port, adapter, or HTTP endpoint. Trigger when the plan.md says "no use-case" and "no HTTP entry point", or when the user says "implement the DB foundation slice".
disable-model-invocation: false
---

# db-only-slice

Implement a DB-only slice: ORM model changes and an Alembic migration.
No use-case, no port, no adapter, no router.

## When to use

- The slice's `plan.md` says there is no HTTP entry point.
- The slice only touches `adapters/db/models/` and `migrations/versions/`.
- The acceptance gate is `alembic upgrade head` + smoke test, not an outside-in test.

## Process

### 1. Read the inputs

Read in this order:
- `specs/features/<feature>/<NNNN>_<slice>/plan.md`
- `specs/features/<feature>/<NNNN>_<slice>/requirements.md`
- Existing ORM models that will be modified (full file, not excerpts)
- `src/app/adapters/db/models/__init__.py`
- `src/migrations/env.py`

### 2. Implement ORM changes

Apply changes in the order listed in `plan.md`:

**Adding columns to an existing model:**
- Non-nullable column with a Python default → add `default=` to `mapped_column`.
- Non-nullable column for existing rows → also add `server_default=` to the ORM column
  *and* confirm the migration will carry `server_default=` (see Step 4).
- Column that is never set at construction time → add `init=False`.
- Self-referential FK → `ForeignKey("same_table.id")` is valid in PostgreSQL.

**Creating a new ORM model file:**
- Line 1: `# STABLE: Infrastructure skeleton. Change only when infra changes.`
- Use `MappedAsDataclass` via `Base` (which already inherits it).
- `id` column: `autoincrement=True, primary_key=True, init=False`.
- Append-only tables: no `updated_at`, `deleted_at`, `is_deleted`.
- `created_at` that is always set by the server: `default_factory=lambda: datetime.now(UTC), init=False`.

**Registering the new model:**
- Add `from .new_model import NewModel  # noqa: F401` to
  `src/app/adapters/db/models/__init__.py` in alphabetical order.
- This makes Alembic discover the model in autogenerate.

### 3. Verify `migrations/env.py` before autogenerate

Check two things:

**3a. Base import is correct:**
```python
from app.adapters.db.base import Base  # correct
# NOT: from app.core.db.database import Base  # stale path
```

**3b. All ORM models are discovered:**
`env.py` calls `import_models(package_name)` for each package that contains ORM
models. If a model lives outside `app.adapters.db.models` (e.g. in
`app.adapters.db.token_blacklist`), add a second call:
```python
import_models("app.adapters.db.models")
import_models("app.adapters.db.token_blacklist")  # any additional package
```
Missing this causes Alembic to see the table in the DB but not in models → it
generates `op.drop_table(...)` for that table. That is a data-loss bug.

### 4. Generate and review the migration

```
cd src
alembic revision --autogenerate -m "<description>"
```

Open the generated file immediately and verify **every line**:

**Drop-table check:** If the output contains `op.drop_table(...)` for a table you
did not remove from any model, stop. A model is missing from Alembic's scan (see
Step 3b). Fix `env.py` and regenerate. Do not apply a migration that drops tables
you did not intend to drop.

**Pre-existing table check:** If a new ORM model's table already exists in the dev DB
(e.g. created by `create_all()` in a previous session), Alembic will not generate
`op.create_table(...)` for it. Look for "Detected sequence named `<table>_id_seq`"
in the autogenerate log without a corresponding "Detected added table" — that means
the table already exists.
- Manually add `op.create_table(...)` for the missing table in the migration.
- Drop the pre-existing table from the dev DB before running `alembic upgrade head`.

**server_default check (critical):** For every `op.add_column` on a non-nullable column
being added to a table that may already have rows, confirm the call has `server_default=`.
Alembic autogenerate **never** copies ORM `default=` into SQL `server_default`.
Add it manually if missing:
```python
# autogenerate output (wrong for existing rows):
op.add_column('post', sa.Column('status', sa.String(20), nullable=False))

# corrected:
op.add_column('post', sa.Column('status', sa.String(20),
    server_default='pending_review', nullable=False))
```

**Spurious unique constraints:** Autogenerate may emit
`op.create_unique_constraint(None, 'some_table', ['id'])` for PK columns that
have `unique=True` in the ORM. PostgreSQL PKs already imply uniqueness; these are
redundant. Remove them from the migration if they are not part of your requirements.

**Index check:** Confirm `op.create_index` entries exist for every column you added
`index=True` to.

**FK check:** Confirm `op.create_foreign_key` entries match the FK columns you added.

**downgrade check:** Confirm `downgrade()` reverses all `upgrade()` operations in
reverse order: drop FKs → drop indexes → drop columns → drop tables.

### 5. Apply the migration

If a new table pre-existed in dev DB:
```python
# Drop it first so the migration can create it cleanly
await conn.execute(text('DROP TABLE IF EXISTS <table_name> CASCADE'))
```

Then:
```
alembic upgrade head
```

Confirm it prints `Running upgrade  -> <revision>, <message>` with no errors.

### 6. Quality gates

Run in this order — all must pass:

```
ruff format src/app
ruff check src/app
mypy src/app
pytest tests/smoke/        # if smoke test exists
pytest                     # full suite, no new failures
```

For `mypy`: any new ORM column must be typed correctly (`Mapped[bool]`,
`Mapped[int | None]`, etc.). `init=False` columns must not be `Mapped[T]`
unless they have a `default` or `default_factory`.

The slice is done when all gates pass and `alembic upgrade head` is clean.

## Common mistakes

- ❌ Running `alembic revision` before verifying `env.py` imports — wastes a
  migration file on an import error.
- ❌ Not adding a new model's package to `import_models` in `env.py` — causes
  `drop_table` for unrelated tables.
- ❌ Forgetting `server_default=` on non-nullable columns added to tables with
  existing rows — `NOT NULL` violation on upgrade or silent data loss.
- ❌ Applying the migration to a dev DB that has tables pre-created by `create_all()`
  without first dropping them — the migration silently skips `create_table` and the
  migration is incomplete for fresh environments.
- ❌ Accepting spurious `create_unique_constraint` on PK `id` columns — clutters
  the migration with no-op DDL.
- ❌ Forgetting `# noqa: F401` on imports in `models/__init__.py` — ruff flags them
  as unused imports (they exist only for Alembic discovery).

## Reference

- Decision log with concrete examples from the first DB-only slice:
  `.claude/decisions/0013_moderation_db_foundation_lessons.md`
- Architecture rules: `agent_docs/architecture.md`
- STABLE vs FEATURE headers: `agent_docs/stable_vs_feature.md`
