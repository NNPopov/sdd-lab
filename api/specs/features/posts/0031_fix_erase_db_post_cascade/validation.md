# 0031 · fix_erase_db_post_cascade — Validation

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md
- Requirements: ./requirements.md

## Prerequisites

- App running locally: `uvicorn src.app.main:app --reload` (from the project
  root) against a development Postgres instance with migrations applied
  (`alembic upgrade head`).
- A superuser account exists. Obtain a token with:
  ```
  curl -X POST http://localhost:8000/api/v1/auth/login \
    -F "username=<superuser>" -F "password=<password>"
  ```
  Set the returned access token as `$SUPER_TOKEN` in your shell.
- A regular (non-superuser) user account and token set as `$USER_TOKEN`.
- A target post that was created by `alice` and has at least one
  `PostModerationLog` row. Seed it by creating a post as `alice`, then calling
  the moderate-post endpoint, which inserts a row into `post_moderation_log`.
  Note the post `{id}` as `$POST_ID`.

---

## Manual scenarios

### S1 — Happy path: hard-delete a post that has moderation log rows

**Covers:** F1, F2, F3.

**Steps:**

1. Confirm `alice`'s post is visible:
   ```
   curl http://localhost:8000/api/v1/alice/post/$POST_ID
   ```
   Expected: HTTP 200, post body returned.

2. Confirm at least one moderation log row exists for the post (directly in the
   DB, or via the get-moderation-log endpoint if available):
   ```sql
   SELECT * FROM post_moderation_log WHERE post_id = <POST_ID>;
   ```
   Expected: one or more rows present.

3. Issue the hard delete as a superuser:
   ```
   curl -X DELETE http://localhost:8000/api/v1/alice/db_post/$POST_ID \
     -H "Authorization: Bearer $SUPER_TOKEN"
   ```
   Expected: HTTP 200, body `{"message": "Post deleted from the database"}`.

4. Verify the `post` row is permanently gone:
   ```sql
   SELECT * FROM post WHERE id = <POST_ID>;
   ```
   Expected: zero rows (not soft-deleted — completely absent).

5. Verify all moderation log rows for that post are permanently gone:
   ```sql
   SELECT * FROM post_moderation_log WHERE post_id = <POST_ID>;
   ```
   Expected: zero rows.

6. Confirm subsequent GET returns 404 (cache invalidated):
   ```
   curl http://localhost:8000/api/v1/alice/post/$POST_ID
   ```
   Expected: HTTP 404.

---

### S2 — Happy path: hard-delete a post that has no moderation log rows

**Covers:** F1, F3 (baseline — cascade must not break the no-logs case).

**Steps:**

1. Create a fresh post as `alice` (or use any existing live post with no
   moderation history) and note its `{id}` as `$NEW_POST_ID`.

2. Confirm no moderation log rows exist for it:
   ```sql
   SELECT * FROM post_moderation_log WHERE post_id = <NEW_POST_ID>;
   ```
   Expected: zero rows.

3. Issue the hard delete:
   ```
   curl -X DELETE http://localhost:8000/api/v1/alice/db_post/$NEW_POST_ID \
     -H "Authorization: Bearer $SUPER_TOKEN"
   ```
   Expected: HTTP 200, body `{"message": "Post deleted from the database"}`.

4. Verify the `post` row is gone:
   ```sql
   SELECT * FROM post WHERE id = <NEW_POST_ID>;
   ```
   Expected: zero rows.

---

### S3 — Wrong username namespace → 404

**Covers:** F6.

**Steps:**

1. Using a valid `$POST_ID` belonging to `alice`, attempt delete via `bob`'s
   namespace:
   ```
   curl -X DELETE http://localhost:8000/api/v1/bob/db_post/$POST_ID \
     -H "Authorization: Bearer $SUPER_TOKEN"
   ```
   Expected: HTTP 404, body `{"error": {"code": "notfound", "message": "Post not found"}}`.

2. Verify the post row still exists in the DB:
   ```sql
   SELECT * FROM post WHERE id = <POST_ID>;
   ```
   Expected: row is present and unchanged.

---

### S4 — Non-existent username → 404

**Covers:** F5.

**Steps:**

1. Attempt delete with a username that has no DB row:
   ```
   curl -X DELETE http://localhost:8000/api/v1/no_such_user_xyz/db_post/$POST_ID \
     -H "Authorization: Bearer $SUPER_TOKEN"
   ```
   Expected: HTTP 404, body `{"error": {"code": "notfound", "message": "User not found"}}`.

---

### S5 — Non-superuser caller → 403

**Covers:** F7.

**Steps:**

1. Attempt delete using a regular user token:
   ```
   curl -X DELETE http://localhost:8000/api/v1/alice/db_post/$POST_ID \
     -H "Authorization: Bearer $USER_TOKEN"
   ```
   Expected: HTTP 403.

2. Verify the post row still exists in the DB (the 403 check must fire before
   any write):
   ```sql
   SELECT * FROM post WHERE id = <POST_ID>;
   ```
   Expected: row is present.

---

### S6 — Unauthenticated caller → 401

**Covers:** F8.

**Steps:**

1. Attempt delete with no token:
   ```
   curl -X DELETE http://localhost:8000/api/v1/alice/db_post/$POST_ID
   ```
   Expected: HTTP 401.

---

### S7 — Soft-deleted post → 404

**Covers:** F6.

**Steps:**

1. Soft-delete a live post via the `erase_post` endpoint (`DELETE
   /api/v1/alice/post/$POST_ID`) — this marks `is_deleted=True`.

2. Attempt hard-delete on the same post:
   ```
   curl -X DELETE http://localhost:8000/api/v1/alice/db_post/$POST_ID \
     -H "Authorization: Bearer $SUPER_TOKEN"
   ```
   Expected: HTTP 404, body `{"error": {"code": "notfound", "message": "Post not found"}}`.

3. Verify the post row still exists (soft-deleted but not hard-deleted):
   ```sql
   SELECT id, is_deleted FROM post WHERE id = <POST_ID>;
   ```
   Expected: row present with `is_deleted = true`.

---

### S8 — Read paths unaffected (no lazy-load regression)

**Covers:** N3 (manual verification that `lazy="raise"` does not break reads).

**Steps:**

1. Fetch a post through the `get_post` endpoint:
   ```
   curl http://localhost:8000/api/v1/alice/post/$SOME_POST_ID
   ```
   Expected: HTTP 200, post body returned — no `InvalidRequestError` or 500.

2. Fetch the post list:
   ```
   curl "http://localhost:8000/api/v1/alice/posts"
   ```
   Expected: HTTP 200, list returned — no 500.

   These checks confirm that `lazy="raise"` on `Post.moderation_logs` does not
   cause any existing read path (which never loads moderation logs) to crash.

---

## Code review checklist

This checklist is scoped to the two source files and two test files that change
in this slice. Standard items that do not apply (new routers, new DI wiring,
new schema files) are omitted.

### STABLE file change (`adapters/db/models/post.py`)

- [ ] `Post.moderation_logs` relationship is declared with
      `cascade="all, delete-orphan"`.
- [ ] `Post.moderation_logs` is configured with `lazy="raise"` — not
      `lazy="select"` or `lazy="dynamic"`, which would silently lazy-load or
      fail differently in async context.
- [ ] `Post.moderation_logs` is declared with `init=False, repr=False,
      default_factory=list` — required by `MappedAsDataclass` (the field must
      not appear in the constructor signature and must have a default value).
- [ ] `PostModerationLog` is referenced as the string `"PostModerationLog"`,
      not as a direct class import — avoids circular import between
      `post.py` and `post_moderation_log.py`.
- [ ] The file header on line 1 is still `# STABLE: ...` — unchanged from
      before the modification.
- [ ] `alembic revision --autogenerate` produces **no schema changes** (empty
      migration) — confirm and discard the revision file without committing.

### Adapter rewrite (`features/posts/erase_db_post/data/adapter.py`)

- [ ] `hard_delete` no longer imports or calls `delete()` from `sqlalchemy`
      — Core DML is fully replaced.
- [ ] `hard_delete` imports `selectinload` from `sqlalchemy.orm`.
- [ ] `hard_delete` uses `select(Post).where(Post.id == post_id).options(selectinload(Post.moderation_logs))`
      to load the post instance eagerly — this is required because `lazy="raise"`
      would otherwise make `session.delete(post)` raise `InvalidRequestError`.
- [ ] `hard_delete` calls `session.delete(post)`, not `session.execute(delete(...))`.
- [ ] `hard_delete` calls `await session.commit()` after `session.delete(post)`.
- [ ] `hard_delete` uses `scalar_one()` (not `scalar_one_or_none()`) — a
      missing post at this stage is a race condition, not a domain case, and
      should surface as HTTP 500 via the global handler.
- [ ] `hard_delete` contains no `try/except` block — the cascade removes the
      FK violation root cause; no business-meaningful exception remains to
      translate (per `agent_docs/error_handling.md`).
- [ ] All other adapter methods (`get_user_by_username`, `find_post`) are
      **unchanged** — verify the diff contains only `hard_delete` and the
      import block.
- [ ] The file header on line 1 is still `# FEATURE: erase_db_post — data adapter.`

### Adapter unit test (`data/test_adapter.py`)

- [ ] A new test case `test_hard_delete_removes_post_and_moderation_logs`
      exists and seeds a `PostModerationLog` row before calling `hard_delete`.
- [ ] The test asserts that the `post_moderation_log` row is gone after
      `hard_delete`, not just the `post` row.
- [ ] The existing `test_hard_delete_removes_row_permanently` test is
      unchanged — it continues to cover the no-logs case.

### Outside-in test (`erase_db_post_outside_in_test.py`)

- [ ] Scenario 1 (`test_admin_hard_deletes_post_row_is_gone_and_get_returns_404`)
      seeds at least one `PostModerationLog` row before the DELETE call.
- [ ] Scenario 1 includes a DB assertion after deletion confirming that no
      `post_moderation_log` rows with that `post_id` remain.
- [ ] Scenario 2 is unchanged.

### Quality gates

Run from the project root in this order:

```
ruff format src/app tests
ruff check src/app tests
mypy src/app
pytest tests/features/posts/0030_erase_db_post/ -v
pytest tests/smoke/test_app_starts.py -v
pytest -v
```

All must pass. Pay special attention to the smoke test — it boots the app via
uvicorn (not pytest) and catches import errors that only appear when
`src/app/` is not on the Python path. A failing smoke test means the slice
is **not done**, even if every other test is green.

If any ruff or mypy issue appears specifically in the modified `post.py` model
(e.g. type annotation on the `relationship`), it must be fixed before the PR
is approved.
