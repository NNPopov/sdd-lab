# PRD — Slice 0031: fix_erase_db_post_cascade

## Problem Statement

The `DELETE /{username}/db_post/{id}` endpoint (`erase_db_post`, slice 0030)
fails at runtime with a `ForeignKeyViolationError` whenever the target post has
associated `PostModerationLog` rows. PostgreSQL refuses the `DELETE FROM post
WHERE id=:id` statement because `post_moderation_log.post_id` references
`post.id` with no `ON DELETE CASCADE` constraint. This makes the endpoint
completely unusable for any post that has ever been moderated — exactly the
posts most likely to require administrative deletion.

Additionally, the current `hard_delete` adapter method uses the SQLAlchemy Core
DML API (`delete(Post).where(...)`) rather than the ORM session API
(`session.get` + `session.delete`). This bypasses the ORM's cascade machinery
and is inconsistent with the project's ORM-first data access style.

## Solution

Fix `erase_db_post` so that hard-deleting a post also permanently removes all
associated `PostModerationLog` rows, in the correct order (children before
parent), without requiring any database schema changes.

The fix has two parts:

1. Add a `relationship` to the `Post` ORM model pointing to `PostModerationLog`
   with `cascade="all, delete-orphan"`. This declares the cascade intent at the
   model layer — the correct architectural location — so that any code path
   performing an ORM session delete on a `Post` inherits safe child deletion
   automatically.

2. Rewrite `EraseDbPostAdapter.hard_delete` to use the ORM session API: load
   the `Post` instance with its moderation logs eagerly via `selectinload`, call
   `session.delete(post)`, then commit. SQLAlchemy issues the child
   `PostModerationLog` DELETEs before the parent `Post` DELETE automatically.

No Alembic migration is required. The FK constraint already exists in the
database; the `relationship` is a Python-only ORM construct with no DDL
representation.

## User Stories

1. As a superuser, I want `DELETE /{username}/db_post/{id}` to succeed even
   when the target post has associated moderation log entries, so that
   moderation history does not prevent permanent deletion of content.
2. As a superuser, I want all `PostModerationLog` rows for a hard-deleted post
   to be permanently removed from the database, so that no orphaned audit
   records are left behind after a purge.
3. As a superuser, I want the hard-delete endpoint to continue returning HTTP
   200 with `{"message": "Post deleted from the database"}` on success,
   regardless of whether the post had moderation history, so that the public
   HTTP contract is unchanged.
4. As a superuser, I want the hard-delete endpoint to continue returning HTTP
   404 when the post does not exist or does not belong to the given username,
   so that the ownership and existence checks are unaffected by the cascade fix.
5. As a developer, I want the `Post` ORM model to declare its cascade
   relationship to `PostModerationLog`, so that the ownership rule "moderation
   logs live and die with their post" is encoded once at the model layer and
   not duplicated across adapters.
6. As a developer, I want `EraseDbPostAdapter.hard_delete` to use the ORM
   session API (`session.get` + `session.delete`) instead of Core DML, so that
   the adapter is consistent with the project's ORM-first data access
   convention.
7. As a developer, I want the adapter unit test for `hard_delete` to verify
   that `PostModerationLog` rows are deleted alongside the post, so that the
   cascade behavior is covered and a future regression is caught immediately.
8. As a developer, I want the outside-in acceptance test to exercise the full
   delete flow against a post that has at least one moderation log entry, so
   that the cascade path is covered end-to-end in the acceptance gate.
9. As a developer, I want the `selectinload` eager-loading to be scoped to the
   deletion path only, so that existing read paths (`get_post`, `list_posts`)
   do not incur the cost of loading moderation logs on every query.

## Implementation Decisions

### Post ORM model change (STABLE file)

A `relationship` is added to the `Post` model pointing to `PostModerationLog`
with `cascade="all, delete-orphan"`. Because async SQLAlchemy does not support
implicit lazy loading (it raises `MissingGreenlet` errors), the relationship is
configured without a default eager strategy. All call sites that perform a
session delete must explicitly use `selectinload` when loading the instance.
This scopes the loading cost to the deletion path only.

`lazy="raise"` may optionally be set on the relationship to make accidental
implicit lazy access a hard error rather than a silent greenlet failure.

This is a STABLE file change and requires explicit approval before
implementation.

### Adapter rewrite (FEATURE file)

`EraseDbPostAdapter.hard_delete` is replaced with three steps inside a single
`async_sessionmaker` context:

1. Load the `Post` instance via `select(Post).where(Post.id == post_id)
   .options(selectinload(Post.moderation_logs))`.
2. Call `await session.delete(post)`.
3. Call `await session.commit()`.

The Core DML `delete(Post).where(...)` statement is removed entirely. No
`try/except` is added — the cascade eliminates the FK violation, so no
`IntegrityError` handling is required.

### No schema change

No Alembic migration is generated. The `relationship` is a Python-only ORM
construct. The FK constraint on `post_moderation_log.post_id` is unchanged.

### No use-case or port change

`EraseDbPostUseCase.__call__` is unchanged. `EraseDbPostPort.hard_delete(post_id: int) -> None`
is unchanged. The cascade is an internal adapter implementation detail,
invisible above the adapter boundary.

### No HTTP contract change

The router, response schema, status code, cache-invalidation decorator, and
authentication requirement are all unchanged.

## Testing Decisions

Good tests verify observable behavior through the public interface — database
state after the operation and HTTP responses — not which SQL statements were
issued or which ORM methods were called internally.

### Adapter unit test update

The existing `test_adapter.py` test for `hard_delete` is extended with a new
case:

- Seed a post owned by a user.
- Seed at least one `PostModerationLog` row referencing that post.
- Call `hard_delete(post_id)`.
- Assert the `post` row no longer exists in the database.
- Assert no `PostModerationLog` rows with that `post_id` remain.

This is the authoritative test for the cascade behavior. Prior art:
`tests/features/posts/0030_erase_db_post/data/test_adapter.py`.

### Outside-in test update

The acceptance scenario in `erase_db_post_outside_in_test.py` is updated to
seed at least one moderation log entry (via the moderate-post flow) before the
admin performs the hard delete. Post-deletion DB assertions include confirming
that no `PostModerationLog` rows with that `post_id` remain. Prior art: the
existing outside-in test in the same file.

### Use-case unit test

No change required. The unit test mocks the port and does not exercise the ORM
layer.

### Router integration test

No change required. The observable HTTP contract is unchanged.

## Out of Scope

- Adding `ON DELETE CASCADE` at the database level — the ORM cascade achieves
  the same result without a migration.
- Cascade deletion of any other Post-related tables beyond `PostModerationLog`
  — no other tables are currently affected by the FK violation.
- Lazy loading configuration changes beyond what is necessary for the
  deletion path.
- Changes to `find_post` or `get_user_by_username` adapter methods.
- Changes to the use case, port, command, domain entities, or response schema.
- Cache-invalidation logic changes — the existing `@cache` decorator contract
  is preserved deliberately.
- Hard-deletion of already-soft-deleted posts — a separate, future
  data-purge slice if needed.

## Further Notes

- The `relationship` on `Post` is a STABLE file change. It encodes at the model
  layer that `PostModerationLog` rows are owned by the `Post` and must not
  outlive it. This is the architecturally correct location per the project
  rules: the adapter should not need to know which child tables exist.
- The `selectinload` approach scopes the eager-load cost to the deletion path.
  Read paths (`list_posts`, `get_post`, etc.) are entirely unaffected.
- If future slices need to hard-delete `Post` objects through other adapters,
  the cascade is inherited automatically from the model — no per-adapter
  duplication is needed.
- The original 0030 PRD stated "No `try/except` in the adapter — there are no
  business-meaningful infrastructure exceptions to translate for a hard-delete."
  This remains correct after the fix: the cascade removes the root cause of the
  `IntegrityError`, so no exception translation is ever needed.
