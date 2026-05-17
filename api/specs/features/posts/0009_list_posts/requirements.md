# 0009 · list_posts — Requirements

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md

## Functional requirements

- **F1.** The endpoint `GET /api/v1/{username}/posts` returns HTTP 200 with a
  `ListPostsResponse` body when called with valid path and query parameters.
- **F2.** `ListPostsResponse` contains exactly the fields `items: list[PostItemSchema]`,
  `total_count: int`, `page: int`, and `items_per_page: int`.
- **F3.** Each `PostItemSchema` in the response contains exactly the fields `id: int`,
  `title: str`, `text: str`, `media_url: str | None`, `created_at: datetime`,
  `created_by_user_id: int`, and `username: str`.
- **F4.** The `username` field of each `PostItemSchema` is the value of
  `user.username` for the post's author, resolved by joining `post.created_by_user_id`
  to `user.id`; it is not derived from the URL path parameter.
- **F5.** When `username` does not match any row in the `user` table, the endpoint
  returns HTTP 200 with `items: []` and `total_count: 0`.
- **F6.** When a user exists but has no non-deleted posts, the endpoint returns HTTP
  200 with `items: []` and `total_count: 0`.
- **F7.** Posts with `post.is_deleted = true` are excluded from both `items` and
  `total_count`.
- **F8.** Posts whose author has `user.is_deleted = true` are excluded from both
  `items` and `total_count`.
- **F9.** `total_count` reflects the total number of matching non-deleted posts for
  the user across all pages, not only the current page.
- **F10.** The `items` list contains at most `items_per_page` posts starting at the
  offset `(page - 1) * items_per_page` within the full result set.
- **F11.** The endpoint returns HTTP 422 when the `page` query parameter is less
  than 1.
- **F12.** The endpoint returns HTTP 422 when `items_per_page` is less than 1 or
  greater than 100.
- **F13.** The endpoint response is cached in Redis for 60 seconds under the key
  prefix `{username}_posts:page_{page}:items_per_page:{items_per_page}`; a second
  identical request made within the TTL is served from the cache without a database
  round-trip.
- **F14.** The cache key format is identical to the one used by the old `read_posts`
  handler so that existing cache-invalidation patterns in `patch_post` and `erase_post`
  (which target `{username}_posts:*`) continue to work without modification.
- **F15.** `ListPostsUseCase.__call__` returns exactly the `PostPage` value returned
  by the port, without modification or re-validation.

## Non-functional requirements

- **N1.** `ListPostsUseCase` is a class; its public interface is a single `__call__`
  method called as `await use_case(query)`. Per `agent_docs/architecture.md` §
  Use-case shape.
- **N2.** `ListPostsAdapter` explicitly inherits from `ListPostsPort` in its class
  definition (`class ListPostsAdapter(ListPostsPort):`). Per `agent_docs/architecture.md`
  § Terminology: port and adapter.
- **N3.** `ListPostsPort` carries the `@runtime_checkable` decorator. Per
  `agent_docs/architecture.md` § Port pattern (canonical).
- **N4.** `ListPostsAdapter.list` contains no `try/except` block; it is a read-only
  query with no business-meaningful exception path, and all infrastructure failures
  propagate to the global exception handler. Per `agent_docs/error_handling.md` §
  Right shape: read-only query, no catch.
- **N5.** `ListPostsResponse` and `PostItemSchema` carry `model_config =
  ConfigDict(from_attributes=True)`.
- **N6.** Every new `.py` file in the `list_posts/` folder starts with the header
  `# FEATURE: list_posts — <purpose>` on line 1. Per `agent_docs/stable_vs_feature.md`.
- **N7.** `ListPostsUseCase` raises no `HTTPException` and contains no import from
  FastAPI, SQLAlchemy, or any adapter. Per CLAUDE.md universal hard rules §1.
- **N8.** No file inside `list_posts/` imports from another slice's `domain/`,
  `data/`, or `presentation/` folder. Per `agent_docs/architecture.md` § Layer rules.
- **N9.** All database access in `ListPostsAdapter` uses `async def` and `await`;
  no synchronous calls. Per CLAUDE.md locked technology stack.
- **N10.** All imports inside `src/app/` (including `list_posts/`) use relative
  import paths; absolute `app.*` imports are used only inside `tests/`. Per
  `agent_docs/architecture.md` § Import conventions.
- **N11.** `mypy src/app` passes with strict mode for all new code introduced by
  this slice. Per CLAUDE.md verifying changes.
- **N12.** `ruff format src/app` and `ruff check src/app` pass with no errors for
  all new code introduced by this slice. Per CLAUDE.md verifying changes.

## Out of scope

- Returning HTTP 404 for a non-existent username on this endpoint.
- Migrating any other post handler (`write_post`, `read_post`, `patch_post`,
  `erase_post`, `erase_db_post`) to the vertical slice pattern.
- Filtering, sorting, or full-text search on the post list.
- Cursor-based pagination.
- Authentication or authorization on `GET /{username}/posts`.

## Traceability

| Requirement | Verified by |
|---|---|
| F1 | endpoint integration test, outside-in test |
| F2, F3 | endpoint integration test, outside-in test |
| F4 | adapter unit test, endpoint integration test |
| F5, F6 | adapter unit test, endpoint integration test |
| F7, F8 | adapter unit test, endpoint integration test |
| F9, F10 | adapter unit test, endpoint integration test |
| F11, F12 | endpoint integration test |
| F13, F14 | endpoint integration test |
| F15 | use-case unit test |
| N1–N12 | code review checklist in validation.md |
