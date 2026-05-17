# PRD — 0013: Moderation DB Foundation

## Problem Statement

The subsequent moderation slices (0014–0022) all depend on new database columns
and a new table that do not yet exist. Before any moderation business logic can
be implemented, the schema foundation must be in place: the `User` table needs
a moderator role flag and an audit FK, the `Post` table needs a lifecycle status
column, and a new `PostModerationLog` table must be created to store the full
chronological history of moderation events and author revisions.

## Solution

Add two columns to `User`, one column to `Post`, and create a new
`PostModerationLog` ORM model. Deliver a single verified Alembic migration that
applies all three changes atomically. No use-case, adapter, or HTTP endpoint is
introduced in this slice.

## User Stories

1. As a developer implementing moderation slices, I want `User.is_moderator` and
   `User.moderator_granted_by_user_id` to exist in the database, so that role
   assignment logic has a persistence target.
2. As a developer implementing moderation slices, I want `Post.status` to exist
   with a default of `pending_review`, so that post lifecycle state can be
   tracked.
3. As a developer implementing moderation slices, I want the `PostModerationLog`
   table to exist with all required columns and FK constraints, so that
   moderation event history can be persisted.
4. As a developer, I want a single Alembic migration that applies all schema
   changes atomically, so that the database can be upgraded in one step.

## Implementation Decisions

### Changes to `User` ORM model

- `is_moderator: bool` — defaults to `False`; indexed.
- `moderator_granted_by_user_id: int | None` — nullable FK to `user.id`;
  `init=False`; indexed. Set when moderator is assigned, cleared when revoked.

### Changes to `Post` ORM model

- `status: str` — values enforced at application level:
  `pending_review`, `approved`, `changes_requested`; defaults to
  `pending_review`; indexed; maximum length 20 characters.

### New `PostModerationLog` ORM model

| Column | Type | Constraints |
|---|---|---|
| `id` | int | PK, autoincrement, `init=False` |
| `post_id` | int | FK → `post.id`, indexed, non-nullable |
| `user_id` | int | FK → `user.id`, indexed, non-nullable |
| `event_type` | str(20) | `moderator_review` or `author_revision` |
| `action` | str(20) or None | `approved` or `changes_requested`; only for `moderator_review` |
| `message` | str(2000) or None | optional remark or reply |
| `created_at` | datetime(tz) | `default_factory=lambda: datetime.now(UTC)`, `init=False` |

The table is intentionally append-only. No `updated_at`, no soft delete.

### Alembic migration

One migration covering all three changes. The `status` column default
(`pending_review`) is applied at the database level via `server_default` in
the migration so that existing Post rows receive the value automatically on
upgrade.

## Testing Decisions

No use-case, adapter, or HTTP endpoint is introduced. The slice is verified by:

1. Alembic migration applies without errors (`alembic upgrade head`).
2. Smoke test passes (`pytest tests/smoke/`), confirming no import errors.

All four standard test levels (use-case unit, adapter unit, endpoint
integration, outside-in) are opted out: there is no business logic to test.

## Out of Scope

- Use-cases, ports, adapters, or HTTP endpoints.
- Schema changes to any Pydantic model (`UserRead`, `UserMeRead`, etc.).
- Data migration for existing `Post` rows beyond the `server_default`.

## Further Notes

- All files touched are STABLE. This plan is the explicit authorisation per
  parent PRD `specs/features/moderation/0012_moderation/prd.md`.
- Existing Post rows will have `status = 'pending_review'` after migration,
  making them invisible to regular users until approved. This is intentional:
  pre-existing posts enter the same moderation queue as new ones.
