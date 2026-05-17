# 0023 · expose_post_uuid — Requirements

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md

## Functional requirements

- **F1.** `GET /api/v1/{username}/posts` returns HTTP 200 with each item in
  `ListPostsResponse.items` containing a `post_uuid` field of type UUID.
- **F2.** `GET /api/v1/posts` returns HTTP 200 with each item in
  `ListAllPostsResponse.items` containing a `post_uuid` field of type UUID.
- **F3.** `POST /api/v1/{username}/post` returns HTTP 201 with
  `CreatePostResponse` containing a `post_uuid` field of type UUID.
- **F4.** `GET /api/v1/{username}/post/{id}` returns HTTP 200 with the
  response body containing a `post_uuid` field of type UUID.
- **F5.** The `post_uuid` value in all four responses for a given post equals
  the value of the `uuid` column on the corresponding `Post` row.
- **F6.** `ListPostsAdapter.list()` populates `PostItem.post_uuid` from
  `Post.uuid` for every row returned.
- **F7.** `ListAllPostsAdapter.list()` populates `PostItem.post_uuid` from
  `Post.uuid` for every row returned.
- **F8.** `CreatePostAdapter.create()` populates `CreatedPost.post_uuid` from
  `Post.uuid` after the INSERT and session refresh.
- **F9.** The `read_post` response includes `post_uuid` derived from the `uuid`
  column selected via FastCRUD; the field `uuid` itself does not appear in the
  JSON output.
- **F10.** `PATCH /api/v1/{username}/post/{id}` (`patch_post`) and
  `DELETE /api/v1/{username}/post/{id}` (`erase_post`) responses are unchanged
  and do not include `post_uuid`.
- **F11.** `GET /api/v1/posts/pending` (`list_pending_posts`) response is
  unchanged; it already returns `post_uuid` from slice 0019.
- **F12.** No database migration is executed; the `uuid` column already exists
  on the `Post` table.

## Non-functional requirements

- **N1.** All modified `.py` files retain their `# FEATURE:` header on line 1.
  New test files carry `# FEATURE: expose_post_uuid — <purpose>`. Per
  `agent_docs/stable_vs_feature.md`.
- **N2.** No STABLE files are modified. The `Post` ORM model,
  `bootstrap/container.py`, `bootstrap/router.py`, and `domain/errors.py`
  are untouched. Per `agent_docs/stable_vs_feature.md`.
- **N3.** No `HTTPException` is raised in any modified code path; domain errors
  propagate to `adapters/http/exception_handlers.py`. Per
  `agent_docs/error_handling.md`.
- **N4.** No new `try/except` blocks are introduced; UUID field mapping is
  mechanical and carries no business-meaningful exception path. Per
  `agent_docs/error_handling.md`.
- **N5.** No cross-slice imports are introduced; `PostItem` in
  `posts/_shared/entities.py` is already the sanctioned shared entity for
  `list_posts` and `list_all_posts`. Per `agent_docs/architecture.md`.
- **N6.** All I/O remains `async def` + `await`; no synchronous database calls
  are added. Per `agent_docs/architecture.md`.
- **N7.** mypy strict passes for all modified and new source files.
- **N8.** Ruff format and lint pass for all modified and new source files.
- **N9.** New Pydantic schemas that validate from ORM objects use
  `model_config = ConfigDict(from_attributes=True)`. Per
  `agent_docs/architecture.md`.

## Out of scope

- Adding `post_uuid` to `patch_post` or `erase_post` responses (those return
  only a confirmation message string).
- Adding `post_uuid` to `list_pending_posts` (already present from slice 0019).
- The `GET /posts/{post_uuid}/moderation-log` endpoint (slice 0024).
- Cache key changes (`post_uuid` is additive to the response).
- Filtering or searching posts by UUID.

## Traceability

| Requirement | Verified by |
|---|---|
| F1 | endpoint integration test; outside-in test (step 4) |
| F2 | endpoint integration test; outside-in test (step 5) |
| F3 | endpoint integration test; outside-in test (step 2) |
| F4 | endpoint integration test; outside-in test (step 6) |
| F5 | outside-in test (step 7 — UUID equality across all four calls) |
| F6 | adapter unit test (`ListPostsAdapter`) |
| F7 | adapter unit test (`ListAllPostsAdapter`) |
| F8 | outside-in test (create response carries `post_uuid`) |
| F9 | endpoint integration test (`GET /{username}/post/{id}` response shape) |
| F10 | existing tests for `patch_post` / `erase_post` (must remain green) |
| F11 | existing `list_pending_posts` outside-in test (must remain green) |
| F12 | code review checklist in validation.md |
| N1–N9 | code review checklist in validation.md |
