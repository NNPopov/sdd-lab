# Decision log — 0013_moderation_db_foundation

**Slice:** `specs/features/moderation/0013_moderation_db_foundation`
**Date:** 2026-05-15
**Type:** DB-only slice (ORM models + Alembic migration, no use-case)

---

## Problems encountered and resolutions

### Problem 1 — Stale import in `migrations/env.py`

**What happened:** Running `alembic revision --autogenerate` failed immediately:
```
ModuleNotFoundError: No module named 'app.core.db'
```
The `env.py` had a leftover import `from app.core.db.database import Base` pointing
to a path that no longer exists. The project moved `Base` to `app.adapters.db.base`
during an earlier refactor.

**Resolution:** Changed line 12 of `src/migrations/env.py`:
```python
# before
from app.core.db.database import Base
# after
from app.adapters.db.base import Base
```

**Lesson:** Before running `alembic revision` on a project for the first time in a
session (or after a long pause), verify `migrations/env.py` imports are valid.
The `env.py` is a STABLE file that is easily forgotten during infra refactors.

---

### Problem 2 — TokenBlacklist not visible to Alembic → spurious `drop_table`

**What happened:** Alembic detected the `token_blacklist` table in the database but
found no corresponding ORM model in its scan. It generated `op.drop_table('token_blacklist')`
in the migration — which would have destroyed live data.

**Root cause:** `env.py` called `import_models("app.adapters.db.models")` which only
walks the `app/adapters/db/models/` package. `TokenBlacklist` lives in a sibling
package: `app/adapters/db/token_blacklist/model.py`. That package was never added to
the Alembic scan.

**Resolution:** Added a second `import_models` call in `env.py`:
```python
import_models("app.adapters.db.models")
import_models("app.adapters.db.token_blacklist")  # ← added
```

**Lesson:** Every ORM model that has a table in the DB **must** be imported (directly or
via package scan) inside `migrations/env.py` before `alembic autogenerate` is run.
If a model is in a non-standard location (outside `adapters/db/models/`), `env.py`
must be updated explicitly. Check for this whenever adding a new ORM model outside
the main `models/` package.

---

### Problem 3 — `post_moderation_log` table pre-existed in dev DB

**What happened:** The second autogenerate run produced no `create_table` for
`post_moderation_log`. Alembic logged:
```
Detected sequence named 'post_moderation_log_id_seq' as owned by integer column
'post_moderation_log(id)', assuming SERIAL and omitting
```
The table had been created directly in the dev DB (likely via SQLAlchemy `create_all()`
in an earlier session) without going through Alembic. Alembic saw it as "already in sync"
and omitted the DDL.

**Resolution:**
1. Manually added `op.create_table('post_moderation_log', ...)` to the migration so
   it works correctly on a fresh database.
2. Dropped the pre-existing table from the dev DB before running `alembic upgrade head`:
   ```python
   await conn.execute(text('DROP TABLE IF EXISTS post_moderation_log CASCADE'))
   ```

**Lesson:** In a dev environment where `create_all()` has been used, the DB may contain
tables that Alembic does not know about. Always check the autogenerate output for
missing `create_table` entries when introducing new ORM models. If a table is already
in the DB but not tracked by Alembic, drop it and let the migration recreate it properly.

---

### Problem 4 — `server_default` missing for `post.status`

**What happened:** Alembic autogenerate produced:
```python
op.add_column('post', sa.Column('status', sa.String(length=20), nullable=False))
```
No `server_default`. Applying this to a DB with existing rows would fail with
`NOT NULL constraint violation` — or would silently leave existing rows without a value
if applied with a default at the application level only.

**Root cause:** Alembic autogenerate does **not** translate ORM-level `default=`
parameters into SQL `server_default`. These are two separate mechanisms:
- `default=` in `mapped_column` → Python-side default, applied only by SQLAlchemy
  when constructing a new ORM object before INSERT.
- `server_default=` in `op.add_column` → SQL-level `DEFAULT`, applied by the DB
  when a column is added to a table with existing rows.

**Resolution:** Manually added `server_default` to both new non-nullable columns
in the migration:
```python
op.add_column('post', sa.Column('status', sa.String(length=20),
    server_default='pending_review', nullable=False))
op.add_column('user', sa.Column('is_moderator', sa.Boolean(),
    server_default='false', nullable=False))
```

**Lesson:** After every `alembic revision --autogenerate`, inspect every
`op.add_column` for non-nullable columns being added to tables with existing rows.
If the ORM model uses `default=` for such a column, add the corresponding
`server_default=` manually in the migration. Alembic will never do this automatically.
See requirement F6 in `requirements.md` as the checklist item to catch this.

---

### Problem 5 — Spurious unique constraints on PK columns

**What happened:** Autogenerate produced `op.create_unique_constraint(None, 'post', ['id'])`
(and similarly for `rate_limit`, `tier`, `token_blacklist`). These were not part of
our schema changes.

**Root cause:** ORM models define `id` columns with both `primary_key=True` and
`unique=True`. PostgreSQL's primary key already enforces uniqueness (no separate
unique constraint needed), so the DB had no explicit unique constraint on `id`. Alembic
compared the ORM metadata (which says `unique=True`) to the DB (which only has the PK
constraint) and detected a diff.

**Resolution:** Removed all spurious unique-constraint operations from the migration.
They are a pre-existing schema drift issue unrelated to this slice.

**Lesson:** When reviewing autogenerated migrations, filter out any `create_unique_constraint`
on `id` columns — they are caused by the `unique=True, primary_key=True` pattern in
ORM models and are redundant in PostgreSQL. Do not include them in a migration unless
the slice's requirements explicitly call for a unique constraint on that column.

---

## Checklist for future DB-only slices

Use this before declaring a DB-only slice done:

- [ ] `migrations/env.py` imports resolve without error (`alembic revision` runs)
- [ ] All ORM models (including those outside `adapters/db/models/`) are visible to Alembic
- [ ] Autogenerate output reviewed line-by-line — no spurious `drop_table` or `drop_column`
- [ ] Every non-nullable column added to an existing table has `server_default=` in migration
- [ ] `post_moderation_log`-style issue checked: new tables not pre-existing in dev DB
- [ ] `alembic upgrade head` runs clean on the dev DB
- [ ] `ruff format`, `ruff check`, `mypy src/app` pass
- [ ] Full test suite shows no new failures
