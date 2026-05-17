# 0013 · moderation_db_foundation — Requirements

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md

## Functional requirements

**User model — moderator fields**

- **F1.** The `user` table gains a non-nullable boolean column `is_moderator`
  with a database-level default of `false` and an index.
- **F2.** The `user` table gains a nullable integer column
  `moderator_granted_by_user_id` with a foreign key constraint to `user.id`,
  `NULL` as default, and an index.
- **F3.** The `User` ORM class maps `is_moderator` without `init=False` so
  that it can be supplied as a constructor argument (following the `is_superuser`
  pattern).
- **F4.** The `User` ORM class maps `moderator_granted_by_user_id` with
  `init=False` so that it is never set at user-creation time (following the
  `tier_id` pattern).

**Post model — status field**

- **F5.** The `post` table gains a non-nullable `VARCHAR(20)` column `status`
  with an index.
- **F6.** All existing `Post` rows receive `status = 'pending_review'` upon
  migration upgrade, enforced via `server_default` in the Alembic migration.
- **F7.** New `Post` rows created without an explicit `status` argument receive
  `status = 'pending_review'` via the ORM-level `default`.

**PostModerationLog model — new table**

- **F8.** A new table `post_moderation_log` is created with columns: `id`
  (integer PK, autoincrement), `post_id` (integer, non-nullable), `user_id`
  (integer, non-nullable), `event_type` (`VARCHAR(20)`, non-nullable), `action`
  (`VARCHAR(20)`, nullable), `message` (`VARCHAR(2000)`, nullable),
  `created_at` (timestamptz, non-nullable).
- **F9.** `post_moderation_log.post_id` has a foreign key constraint to `post.id`.
- **F10.** `post_moderation_log.user_id` has a foreign key constraint to `user.id`.
- **F11.** `post_moderation_log.post_id` and `post_moderation_log.user_id` each
  have their own index.
- **F12.** `PostModerationLog.created_at` is `init=False` and is always
  populated by `default_factory=lambda: datetime.now(UTC)`.
- **F13.** The `PostModerationLog` table has no `updated_at`, `deleted_at`,
  `is_deleted`, or `uuid` columns — it is append-only.

**Migration**

- **F14.** A single Alembic migration applies all schema changes (F1–F13)
  atomically in one `upgrade()` call.
- **F15.** The migration's `downgrade()` reverses all changes: drops
  `post_moderation_log`, removes `post.status`, removes `user.is_moderator`
  and `user.moderator_granted_by_user_id`.
- **F16.** `PostModerationLog` is imported in
  `src/app/adapters/db/models/__init__.py` so that Alembic's autogenerate
  discovers the model.

## Non-functional requirements

- **N1.** The new ORM model file `post_moderation_log.py` starts with
  `# STABLE: Infrastructure skeleton. Change only when infra changes.`
  per `agent_docs/stable_vs_feature.md`. (ORM models are STABLE, not FEATURE.)
- **N2.** All modified files (`user.py`, `post.py`) retain their existing
  `# STABLE:` header on line 1 unchanged.
- **N3.** `mypy src/app` passes with no new errors after all changes are
  applied, per `CLAUDE.md` § Verifying changes.
- **N4.** `ruff format src/app` and `ruff check src/app` pass with no errors,
  per `CLAUDE.md` § Verifying changes.
- **N5.** The `adapters/db/models/` files import only from `..base` and
  Python stdlib — no imports from `features/`, `core/`, or `domain/`, per
  `agent_docs/architecture.md` § Layer rules.
- **N6.** The Alembic migration file is reviewed by a human before `alembic
  upgrade head` is run, to confirm `server_default` is present for
  `post.status` (F6) and FK constraints are correct (F9, F10).

## Out of scope

- Use-cases, ports, adapters, or HTTP endpoints for any moderation operation.
- Changes to any Pydantic schema (`UserRead`, `UserMeRead`,
  `GetUserByUsernameResponse`, etc.) — those are in slice 0014.
- `CHECK` constraint on `Post.status` or `PostModerationLog.event_type`.
- SQLAlchemy `relationship()` declarations on any model.

## Traceability

| Requirement | Verified by |
|---|---|
| F1, F2, F3, F4 | migration review (human) + smoke test import |
| F5, F6, F7 | migration review (human) + smoke test import |
| F8, F9, F10, F11, F12, F13 | migration review (human) + smoke test import |
| F14, F15 | `alembic upgrade head` + `alembic downgrade -1` (manual) |
| F16 | smoke test — app import fails if model is missing from `__init__.py` |
| N1, N2 | code review checklist in `validation.md` |
| N3 | `mypy src/app` run in CI / locally |
| N4 | `ruff format` + `ruff check` run in CI / locally |
| N5 | code review checklist in `validation.md` |
| N6 | migration review step in `validation.md` |
