# 0013 · moderation_db_foundation — Validation

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md
- Requirements: ./requirements.md

## Prerequisites

- Local Postgres running (`docker compose up db -d`).
- Dev database migrated to the commit **before** this slice
  (`alembic downgrade -1` if needed — or start from a clean DB).
- `psql` access to the dev database (or a GUI equivalent).
- Python environment active with all deps installed.

---

## Manual scenarios

> These scenarios verify the schema after `alembic upgrade head` is applied.
> All checks are against the database directly — there is no HTTP layer in this
> slice.

---

### S1 — Migration applies cleanly

**Steps:**

1. From project root, run:
   ```
   alembic upgrade head
   ```

**Expected:**

- Command exits with code 0 and no error output.
- `alembic current` shows the new revision as `(head)`.

**Covers:** F14.

---

### S2 — `user` table gains the two moderator columns

**Steps:**

1. In `psql`, run:
   ```sql
   \d user
   ```
   (or `SELECT column_name, data_type, is_nullable, column_default FROM information_schema.columns WHERE table_name = 'user';`)

**Expected:**

- Column `is_moderator` exists: `boolean`, `NOT NULL`, default `false`.
- Column `moderator_granted_by_user_id` exists: `integer`, nullable, no
  explicit default.
- An index exists on `is_moderator`
  (check with `\di` or `SELECT indexname FROM pg_indexes WHERE tablename = 'user';`).
- An index exists on `moderator_granted_by_user_id`.
- A FK constraint `moderator_granted_by_user_id → user.id` exists
  (check `\d user` FK section or `information_schema.referential_constraints`).

**Covers:** F1, F2.

---

### S3 — `post` table gains the `status` column with correct default

**Steps:**

1. In `psql`, run:
   ```sql
   \d post
   ```

**Expected:**

- Column `status` exists: `character varying(20)`, `NOT NULL`.
- An index exists on `status`.

**Covers:** F5.

---

### S4 — Existing Post rows receive `status = 'pending_review'`

**Steps:**

1. Seed one or more post rows **before** running the migration (use the
   dev DB at the previous revision, or restore a snapshot that has posts).
2. Apply the migration:
   ```
   alembic upgrade head
   ```
3. In `psql`, run:
   ```sql
   SELECT id, status FROM post LIMIT 10;
   ```

**Expected:**

- Every pre-existing row shows `status = 'pending_review'`.
- No row has `status IS NULL`.

**Covers:** F6.

---

### S5 — `post_moderation_log` table created with correct shape

**Steps:**

1. In `psql`, run:
   ```sql
   \d post_moderation_log
   ```

**Expected:**

- Columns: `id` (integer, PK, not null), `post_id` (integer, not null),
  `user_id` (integer, not null), `event_type` (varchar(20), not null),
  `action` (varchar(20), nullable), `message` (varchar(2000), nullable),
  `created_at` (timestamptz, not null).
- No `updated_at`, `deleted_at`, `is_deleted`, or `uuid` column present.
- FK constraint `post_id → post.id` present.
- FK constraint `user_id → user.id` present.
- Indexes on `post_id` and `user_id`.

**Covers:** F8, F9, F10, F11, F13.

---

### S6 — ORM models import cleanly (smoke test)

**Steps:**

1. Run:
   ```
   pytest tests/smoke/
   ```

**Expected:**

- Smoke test passes (app boots, `/api/v1/health` returns 200).
- This confirms `PostModerationLog` is importable via
  `adapters/db/models/__init__.py` and that the ORM metadata is consistent
  with the live schema.

**Covers:** F16, N1, N2, N3, N4.

---

### S7 — Migration is reversible (`downgrade`)

**Steps:**

1. Run:
   ```
   alembic downgrade -1
   ```

**Expected:**

- Command exits with code 0.
- `alembic current` shows the previous revision as `(head)`.
- In `psql`:
  - `\d user` no longer shows `is_moderator` or `moderator_granted_by_user_id`.
  - `\d post` no longer shows `status`.
  - `\d post_moderation_log` fails with "did not find any relation named
    `post_moderation_log`".

**Covers:** F15.

---

### S8 — Self-referencing FK allows valid values and rejects invalid ones

**Steps:**

1. Re-apply migration: `alembic upgrade head`.
2. In `psql`, insert a user and note their `id` (e.g. `id = 1`).
3. Run:
   ```sql
   UPDATE "user" SET moderator_granted_by_user_id = 1 WHERE id = 1;
   ```
4. Run:
   ```sql
   UPDATE "user" SET moderator_granted_by_user_id = 99999 WHERE id = 1;
   ```

**Expected:**

- Step 3 succeeds (self-reference is valid).
- Step 4 fails with a FK violation error (no user with `id = 99999`).

**Covers:** F2.

---

## Code review checklist

This checklist is adapted for a STABLE DB-only slice. Items specific to
use-case, adapter, DI, or HTTP router are omitted since those layers do not
exist in this slice.

### Files and headers

- [ ] `post_moderation_log.py` starts with
      `# STABLE: Infrastructure skeleton. Change only when infra changes.`
      on line 1 (per `agent_docs/stable_vs_feature.md` — ORM models are STABLE).
- [ ] `user.py` retains its existing `# STABLE:` header unchanged on line 1.
- [ ] `post.py` retains its existing `# STABLE:` header unchanged on line 1.
- [ ] `adapters/db/models/__init__.py` retains its `# STABLE:` header and the
      new `PostModerationLog` import is in alphabetical order with `# noqa: F401`.

### ORM model correctness

- [ ] `User.is_moderator` has `default=False` and `index=True`; no `init=False`
      (follows `is_superuser` pattern — F3).
- [ ] `User.moderator_granted_by_user_id` has `ForeignKey("user.id")`,
      `default=None`, `index=True`, and `init=False`
      (follows `tier_id` pattern — F4).
- [ ] `Post.status` has `String(20)`, `default="pending_review"`, `index=True`;
      no `init=False` (F5, F7).
- [ ] `PostModerationLog.id` has `autoincrement=True`, `primary_key=True`,
      `init=False` (F8).
- [ ] `PostModerationLog.post_id` has `ForeignKey("post.id")`, `index=True`,
      non-nullable (F9, F11).
- [ ] `PostModerationLog.user_id` has `ForeignKey("user.id")`, `index=True`,
      non-nullable (F10, F11).
- [ ] `PostModerationLog.event_type` is `String(20)`, non-nullable (F8).
- [ ] `PostModerationLog.action` is `String(20)`, nullable, `default=None` (F8).
- [ ] `PostModerationLog.message` is `String(2000)`, nullable, `default=None` (F8).
- [ ] `PostModerationLog.created_at` is `DateTime(timezone=True)`,
      `default_factory=lambda: datetime.now(UTC)`, `init=False` (F12).
- [ ] `PostModerationLog` has no `updated_at`, `deleted_at`, `is_deleted`, or
      `uuid` column (F13).

### Migration review

- [ ] Migration was reviewed by a human before `alembic upgrade head` was run.
- [ ] `op.add_column("post", ...)` for `status` includes
      `server_default=sa.text("'pending_review'")` so existing rows get the
      value on upgrade (F6).
- [ ] `op.add_column("user", ...)` for `is_moderator` includes
      `server_default=sa.text("false")` (F1).
- [ ] The FK constraint from `user.moderator_granted_by_user_id` to `user.id`
      is present in the migration DDL (F2).
- [ ] The FK constraints from `post_moderation_log.post_id → post.id` and
      `post_moderation_log.user_id → user.id` are present (F9, F10).
- [ ] All expected indexes are created in the migration (F1, F2, F5, F11).
- [ ] `downgrade()` reverses every change: drops table, drops columns, drops
      indexes (F15).

### Imports and layer rules

- [ ] `post_moderation_log.py` imports only from `..base` (which is
      `adapters/db/base.py`) and Python stdlib (`datetime`). No imports from
      `features/`, `core/`, or `domain/` (N5, `agent_docs/architecture.md`
      § Layer rules).
- [ ] No new file introduces an import from `features/` into `adapters/`.

### Quality gates

Run from project root — all must be green:

```
ruff format src/app
ruff check src/app
mypy src/app
pytest tests/smoke/
alembic upgrade head
```
