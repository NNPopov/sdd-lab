# 0010 · list_all_posts — Requirements

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md

## Functional requirements

- **F1.** The endpoint `GET /api/v1/posts` returns HTTP 200 with a
  `ListAllPostsResponse` body when called with valid query parameters.
- **F2.** `ListAllPostsResponse` contains exactly the fields
  `items: list[PostItemSchema]`, `total_count: int`, `page: int`, and
  `items_per_page: int`.
- **F3.** Each `PostItemSchema` in the response contains exactly the fields
  `id: int`, `title: str`, `text: str`, `media_url: str | None`,
  `created_at: datetime`, `created_by_user_id: int`, and `username: str`.
- **F4.** The `username` field of each `PostItemSchema` is the value of
  `user.username` for the post's author, resolved by joining
  `post.created_by_user_id` to `user.id`; it is never derived from a request
  parameter.
- **F5.** The endpoint returns posts from all non-deleted users; no author
  filter is applied.
- **F6.** When no non-deleted posts exist across any user, the endpoint returns
  HTTP 200 with `items: []` and `total_count: 0`.
- **F7.** Posts with `post.is_deleted = true` are excluded from both `items`
  and `total_count`.
- **F8.** Posts whose author has `user.is_deleted = true` are excluded from
  both `items` and `total_count`.
- **F9.** `total_count` reflects the total number of matching non-deleted posts
  across all non-deleted users on all pages, not only the current page.
- **F10.** The `items` list contains at most `items_per_page` posts starting at
  the offset `(page - 1) * items_per_page` within the full result set.
- **F11.** The `items` list is ordered by `post.created_at` descending (newest
  post first); this ordering is stable across pages.
- **F12.** The endpoint returns HTTP 422 when the `page` query parameter is
  less than 1.
- **F13.** The endpoint returns HTTP 422 when `items_per_page` is less than 1
  or greater than 100.
- **F14.** The endpoint requires no authentication token; unauthenticated
  requests receive the same `ListAllPostsResponse` as any other caller.
- **F15.** The endpoint response is cached in Redis for 60 seconds under the
  key prefix `all_posts:page_{page}:items_per_page:{items_per_page}`; a second
  identical request made within the TTL is served from the cache without a
  database round-trip.
- **F16.** `ListAllPostsUseCase.__call__` returns exactly the `PostPage` value
  returned by the port, without modification or re-validation.
- **F17.** `PostItem` and `PostPage` domain entities are defined in
  `features/posts/_shared/entities.py` and imported by both `list_posts` and
  `list_all_posts` from that shared location; neither slice defines its own
  duplicate copies of these types after this slice lands.

## Non-functional requirements

- **N1.** `ListAllPostsUseCase` is a class; its public interface is a single
  `__call__` method called as `await use_case(query)`. Per
  `agent_docs/architecture.md` § Use-case shape.
- **N2.** `ListAllPostsAdapter` explicitly inherits from `ListAllPostsPort` in
  its class definition (`class ListAllPostsAdapter(ListAllPostsPort):`). Per
  `agent_docs/architecture.md` § Terminology: port and adapter.
- **N3.** `ListAllPostsPort` carries the `@runtime_checkable` decorator. Per
  `agent_docs/architecture.md` § Port pattern (canonical).
- **N4.** `ListAllPostsAdapter.list` contains no `try/except` block; it is a
  read-only query with no business-meaningful exception path, and all
  infrastructure failures propagate to the global exception handler. Per
  `agent_docs/error_handling.md` § Right shape: read-only query, no catch.
- **N5.** `ListAllPostsResponse` and `PostItemSchema` carry
  `model_config = ConfigDict(from_attributes=True)`.
- **N6.** Every new `.py` file in the `list_all_posts/` folder starts with
  `# FEATURE: list_all_posts — <purpose>` on line 1, and
  `_shared/entities.py` starts with `# FEATURE: posts._shared — <purpose>`.
  Per `agent_docs/stable_vs_feature.md`.
- **N7.** `ListAllPostsUseCase` raises no `HTTPException` and contains no
  import from FastAPI, SQLAlchemy, or any adapter layer. Per CLAUDE.md
  universal hard rules §1 and §2.
- **N8.** No file inside `list_all_posts/` imports from another slice's
  `domain/`, `data/`, or `presentation/` folder; cross-slice access within
  the posts feature goes only through `features/posts/_shared/`. Per
  `agent_docs/architecture.md` § Layer rules and `_shared/` rules.
- **N9.** All database access in `ListAllPostsAdapter` uses `async def` and
  `await`; no synchronous SQLAlchemy calls. Per CLAUDE.md locked technology
  stack.
- **N10.** All imports inside `src/app/` (including `list_all_posts/` and
  the updated `list_posts/` files) use relative import paths; absolute
  `app.*` imports are used only inside `tests/`. Per `agent_docs/architecture.md`
  § Import conventions.
- **N11.** `mypy src/app` passes with strict mode for all new and modified
  code introduced by this slice (including the `list_posts` import updates).
  Per CLAUDE.md verifying changes.
- **N12.** `ruff format src/app` and `ruff check src/app` pass with no errors
  for all new and modified code introduced by this slice. Per CLAUDE.md
  verifying changes.

## Out of scope

- Write-side cache invalidation for the `all_posts:*` cache key.
- Filtering by any field other than the implicit soft-delete filter.
- Sorting options other than `post.created_at DESC`.
- Cursor-based pagination.
- Authentication or authorization on `GET /posts`.
- Adding `ORDER BY` to the existing `list_posts` endpoint.
- Migrating any other post handler to the vertical slice pattern.

## Traceability

| Requirement | Verified by |
|---|---|
| F1 | endpoint integration test, outside-in test |
| F2, F3 | endpoint integration test, outside-in test |
| F4 | adapter unit test, endpoint integration test |
| F5 | adapter unit test, endpoint integration test |
| F6 | adapter unit test, endpoint integration test |
| F7, F8 | adapter unit test, endpoint integration test |
| F9, F10 | adapter unit test, endpoint integration test |
| F11 | adapter unit test, outside-in test |
| F12, F13 | endpoint integration test |
| F14 | endpoint integration test |
| F15 | endpoint integration test |
| F16 | use-case unit test |
| F17 | code review checklist in validation.md |
| N1–N12 | code review checklist in validation.md |
