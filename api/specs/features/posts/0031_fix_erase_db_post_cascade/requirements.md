# 0031 · fix_erase_db_post_cascade — Requirements

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md

## Functional requirements

**F1.** `DELETE /api/v1/{username}/db_post/{id}` returns HTTP 200 with
`{"message": "Post deleted from the database"}` when the authenticated superuser
targets a valid, non-soft-deleted post owned by `{username}`, regardless of
whether the post has associated `PostModerationLog` rows.

**F2.** A successful invocation of `EraseDbPostAdapter.hard_delete(post_id)`
permanently removes all `PostModerationLog` rows whose `post_id` column equals
the given `post_id`, in the same database transaction as the post deletion.

**F3.** A successful invocation of `EraseDbPostAdapter.hard_delete(post_id)`
permanently removes the `Post` row whose `id` equals `post_id` from the
database (hard delete — not soft delete).

**F4.** The `Post` ORM model declares a `relationship` named `moderation_logs`
pointing to `PostModerationLog` with `cascade="all, delete-orphan"`, so that
every code path that calls `session.delete(post)` automatically cascades the
delete to children without per-adapter knowledge of the `PostModerationLog`
table.

**F5.** `DELETE /api/v1/{username}/db_post/{id}` returns HTTP 404 with error
body `{"error": {"code": "notfound", "message": "User not found"}}` when
`{username}` does not correspond to a known, non-soft-deleted user.

**F6.** `DELETE /api/v1/{username}/db_post/{id}` returns HTTP 404 with error
body `{"error": {"code": "notfound", "message": "Post not found"}}` when the
post identified by `{id}` does not exist, is soft-deleted, or does not belong to
the user identified by `{username}`.

**F7.** `DELETE /api/v1/{username}/db_post/{id}` returns HTTP 403 when the
authenticated caller is not a superuser.

**F8.** `DELETE /api/v1/{username}/db_post/{id}` returns HTTP 401 when no valid
authentication token is supplied.

## Non-functional requirements

**N1.** `EraseDbPostAdapter.hard_delete` uses the SQLAlchemy ORM session API
(`session.delete(post)`) rather than a Core DML `delete()` statement, per the
project's ORM-first data access convention.

**N2.** `EraseDbPostAdapter.hard_delete` eagerly loads `Post.moderation_logs`
via `selectinload` before calling `session.delete(post)`, because
`lazy="raise"` on the relationship prohibits implicit loading in async context
and would raise `InvalidRequestError` if the relationship were not pre-loaded.

**N3.** `Post.moderation_logs` is configured with `lazy="raise"` so that any
code path outside the deletion adapter that accidentally triggers an implicit
load raises `InvalidRequestError` immediately rather than causing a silent
`MissingGreenlet` failure in async context.

**N4.** `EraseDbPostAdapter.hard_delete` contains no `try/except` — the ORM
cascade removes the root cause of the `ForeignKeyViolationError`, so no
business-meaningful infrastructure exception remains to translate (per
`agent_docs/error_handling.md` § Adapter: catch only when there is business
meaning to translate).

**N5.** No Alembic migration is generated for this slice — the `relationship` is
a Python-only ORM construct with no DDL representation; the FK constraint on
`post_moderation_log.post_id` is unchanged.

**N6.** `Post.moderation_logs` is declared with `init=False`, `repr=False`, and
`default_factory=list` to comply with `MappedAsDataclass` requirements: the
field is absent from the constructor signature and defaults to an empty list.

**N7.** The use-case (`EraseDbPostUseCase`), port (`EraseDbPostPort`), command
(`EraseDbPostCommand`), domain entities, response schema (`EraseDbPostResponse`),
router, DI container, and `.importlinter` are not modified by this slice.

**N8.** The modified source file (`adapters/db/models/post.py`) retains its
`# STABLE:` header on line 1; the modified feature file
(`features/posts/erase_db_post/data/adapter.py`) retains its `# FEATURE:` header
on line 1, per `agent_docs/stable_vs_feature.md` § The two header types.

**N9.** `mypy src/app` with strict settings passes for all modified code.

**N10.** `ruff format src/app` and `ruff check src/app` pass for all modified
code.

## Out of scope

- Adding `ON DELETE CASCADE` at the database level — the ORM cascade achieves
  the same result without a migration.
- Cascade deletion of any Post-related table beyond `PostModerationLog` — no
  other FK currently blocks the delete.
- Changing `lazy="raise"` to `lazy="selectin"` on the relationship — that would
  cause every `Post` read to load moderation logs; `selectinload` at the call
  site is preferable.
- Changes to `find_post` or `get_user_by_username` adapter methods.
- Cache-invalidation logic changes — the existing `@cache` decorator contract
  is preserved.

## Traceability

| Requirement | Verified by |
|---|---|
| F1 | outside-in test (Scenario 1 extended with moderation logs); endpoint integration test (HTTP 200 happy path) |
| F2 | adapter unit test (`test_hard_delete_removes_post_and_moderation_logs`); outside-in test (Scenario 1 DB assertion on `post_moderation_log`) |
| F3 | adapter unit test (existing `test_hard_delete_removes_row_permanently`); outside-in test (Scenario 1 DB assertion on `post`) |
| F4 | code review (Post model `relationship` declaration) |
| F5 | endpoint integration test (HTTP 404, unknown user); outside-in test (Scenario 2, wrong namespace) |
| F6 | endpoint integration test (HTTP 404, post not found / soft-deleted / wrong owner); outside-in test (Scenario 2, wrong namespace step) |
| F7 | endpoint integration test (HTTP 403); outside-in test (Scenario 2, non-superuser step) |
| F8 | endpoint integration test (HTTP 401) |
| N1 | code review (`hard_delete` uses `session.delete`, no `delete()` import) |
| N2 | code review (`selectinload(Post.moderation_logs)` present in `hard_delete`) |
| N3 | code review (`lazy="raise"` on `Post.moderation_logs`) |
| N4 | code review (no `try/except` block in `hard_delete`) |
| N5 | run `alembic revision --autogenerate` and confirm empty output; discard revision |
| N6 | code review (`init=False, repr=False, default_factory=list` on `Post.moderation_logs`) |
| N7 | code review (diff confirms those files are untouched) |
| N8 | code review (line 1 of each modified file) |
| N9 | `mypy src/app` CI step |
| N10 | `ruff format src/app` + `ruff check src/app` CI steps |
