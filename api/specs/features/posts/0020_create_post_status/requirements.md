# 0020 · create_post_status — Requirements

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md

## Functional requirements

- **F1.** The `CreatedPost` domain entity carries a `status: str` field that is
  populated from the `Post` ORM row via Pydantic's `model_validate`
  (`from_attributes=True`).

- **F2.** `CreatePostAdapter.create()` passes `status="pending_review"` as an
  explicit keyword argument when constructing the `Post` ORM object, so the
  inserted database row has `status = "pending_review"` independently of the
  ORM column default.

- **F3.** `CreatePostResponse` includes a `status: str` field; a successful
  `POST /api/v1/{username}/post` returns HTTP 201 with `"status": "pending_review"`
  in the JSON response body.

- **F4.** The `CreatePostResponse` retains all pre-existing fields unchanged:
  `id`, `title`, `text`, `media_url`, `created_by_user_id`, `created_at`.

- **F5.** All existing error responses for `POST /api/v1/{username}/post` are
  unaffected by this slice: HTTP 401 (no valid JWT), HTTP 403 (requester is not
  the path owner), HTTP 404 (path username not found), HTTP 422 (malformed
  request body).

- **F6.** The existing outside-in test for slice 0011
  (`tests/features/posts/0011_create_post/create_post_outside_in_test.py`)
  remains green after the changes are applied.

## Non-functional requirements

- **N1.** No new `.py` files are introduced; the three modified files
  (`domain/entities.py`, `data/adapter.py`, `presentation/schemas.py`) retain
  their existing `# FEATURE: create_post — ...` header on line 1 per
  `agent_docs/stable_vs_feature.md`.

- **N2.** Only `# FEATURE:` files are modified; no `# STABLE:` files are
  touched per `agent_docs/stable_vs_feature.md`.

- **N3.** `CreatedPost` and `CreatePostResponse` use
  `model_config = ConfigDict(from_attributes=True)` per
  `agent_docs/architecture.md` § Use-case shape.

- **N4.** No `HTTPException` is raised inside the use-case; the use-case raises
  only `DomainError` subclasses per `agent_docs/error_handling.md`.

- **N5.** No cross-slice imports are introduced per
  `agent_docs/architecture.md` § Layer rules.

- **N6.** All database I/O in the adapter uses `async def` with `await`; no
  synchronous calls per CLAUDE.md § Locked technology stack.

- **N7.** `mypy strict` passes for all modified code per CLAUDE.md
  § Verifying changes.

- **N8.** `ruff format` and `ruff check` pass for all modified code per CLAUDE.md
  § Verifying changes.

- **N9.** The adapter does not introduce any new `try/except` blocks; inserting
  a `Post` row with a fixed `status` value has no business-meaningful
  infrastructure exceptions to translate per `agent_docs/error_handling.md`
  § Adapter: catch only when there is business meaning to translate.

## Out of scope

- Post visibility filtering in `GET /users/{username}/posts` and `GET /posts` —
  slices 0021 and 0022.
- Exposing `post_uuid` in the create-post response.
- Status transition enforcement at creation time (only `pending_review` is
  valid; transitions belong to slices 0017 and 0018).
- Cache invalidation (no `@cache` decorator on `create_post`).
- Changes to `CreatePostRequest`, `CreatePostCommand`, or
  `CreatePostInternalCommand`.

## Traceability

| Requirement | Verified by |
|---|---|
| F1 | adapter unit test (`test_create_returns_created_post_with_status`) |
| F2 | adapter unit test (direct SQL query confirms DB row `status`) |
| F3 | endpoint integration test + outside-in test |
| F4 | endpoint integration test (asserts all existing fields present) |
| F5 | existing 0011 integration tests (remain green, not rewritten) |
| F6 | outside-in test (0011 suite run as part of full `pytest`) |
| N1–N9 | code review checklist in `validation.md` |
