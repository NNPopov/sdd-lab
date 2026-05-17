# 0022 · list_all_posts_visibility — Requirements

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md

## Functional requirements

- **F1.** `GET /api/v1/posts` returns HTTP 200 with a `ListAllPostsResponse` body for
  every caller regardless of authentication state or privilege level.
- **F2.** When the caller is unauthenticated (no `Authorization` header), the response
  contains only posts with `status = 'approved'`.
- **F3.** When the caller is authenticated as a regular user (neither `is_moderator`
  nor `is_superuser`), the response contains only posts with `status = 'approved'`.
- **F4.** When the caller is authenticated as a user with `is_moderator = True`, the
  response contains all non-deleted posts regardless of their `status`.
- **F5.** When the caller is authenticated as a user with `is_superuser = True`, the
  response contains all non-deleted posts regardless of their `status`.
- **F6.** The `total_count` field in the response reflects the count of posts actually
  returned: filtered to approved only for non-privileged callers; unfiltered for
  privileged callers.
- **F7.** When no approved posts exist and the caller is non-privileged, the response
  is HTTP 200 with `items: []` and `total_count: 0`.
- **F8.** Every item in the response carries a `status` field populated from
  `Post.status`.
- **F9.** The response items maintain newest-first ordering by `created_at` regardless
  of the visibility filter applied.
- **F10.** `ListAllPostsQuery` carries the field `requester_is_privileged: bool = False`;
  the adapter reads this field to decide whether to apply the `status = 'approved'`
  filter.
- **F11.** The router resolves the optional caller identity via the existing
  `get_optional_user` dependency and sets `requester_is_privileged = True` when the
  resolved user's `is_moderator` or `is_superuser` flag is `True`.
- **F12.** The cache key for `GET /api/v1/posts` is
  `all_posts:{view}:page_{page}:items_per_page:{items_per_page}`, where `view` is
  `"privileged"` when `requester_is_privileged = True` and `"public"` otherwise.
- **F13.** The privileged cache entry and the public cache entry are stored
  independently so a privileged caller's response never populates the cache seen by
  public callers.
- **F14.** The `seed_users_and_posts` fixture in
  `tests/features/posts/0010_list_all_posts/conftest.py` sets `status='approved'` on
  every seeded post so that the existing 0010 outside-in test continues to pass after
  this slice is implemented.

## Non-functional requirements

- **N1.** The use-case `ListAllPostsUseCase` is a class with `__call__()`; called as
  `await use_case(query)`. Per `agent_docs/architecture.md` § Use-case shape.
- **N2.** The adapter catches only business-meaningful infrastructure exceptions. For
  this slice, the adapter contains only a read-only query — no `try/except` is added.
  Other infrastructure exceptions propagate to the global handler per
  `agent_docs/error_handling.md`.
- **N3.** Pydantic schemas use `model_config = ConfigDict(from_attributes=True)` for
  entities that come from the ORM. `ListAllPostsQuery` and `PostItemSchema` already
  conform; no change required.
- **N4.** No new `.py` files are introduced by this slice; all changes are to existing
  `# FEATURE:` files. The `# FEATURE:` header must remain on line 1 of each modified
  file.
- **N5.** No `HTTPException` is raised inside `ListAllPostsUseCase` or
  `ListAllPostsAdapter`. Per `agent_docs/error_handling.md`.
- **N6.** No cross-slice imports are introduced. The only cross-feature import added is
  `get_optional_user` from `features/users/dependencies.py` into
  `list_all_posts/presentation/router.py`, which is permitted (shared feature
  dependency). Per `agent_docs/architecture.md` § Layer rules.
- **N7.** All database calls remain `async def` with `await`. No synchronous DB calls.
  Per CLAUDE.md.
- **N8.** `mypy src/app` strict mode passes for all modified files after the change.
- **N9.** `ruff format src/app` and `ruff check src/app` pass for all modified files.
- **N10.** `bootstrap/container.py` is not modified; the existing `list_all_posts_adapter`
  and `list_all_posts_use_case` providers absorb the new `requester_is_privileged`
  field transparently. Per plan.md § 1 STABLE files touched.

## Out of scope

- Visibility filtering on `GET /api/v1/{username}/posts` — implemented in slice 0021.
- Exposing `PostModerationLog` entries on global feed items — available through the
  pending-posts queue (slice 0019).
- Adding `post_uuid` to global feed response items.
- Cache invalidation when a post's `status` changes — existing `all_posts:*` wildcard
  patterns cover both the `privileged` and `public` cache segments automatically.
- Rate limiting on the global feed endpoint beyond what already exists.
- Pagination or filtering beyond `page` / `items_per_page`.

## Traceability

| Requirement | Verified by |
|---|---|
| F1 | endpoint integration test; outside-in test |
| F2 | endpoint integration test (unauthenticated scenario); outside-in test step 5 |
| F3 | endpoint integration test (regular-user scenario); outside-in test step 6 |
| F4 | endpoint integration test (moderator scenario); outside-in test step 7 |
| F5 | endpoint integration test (superuser scenario) |
| F6 | adapter unit test (`total_count` assertions for both privilege levels) |
| F7 | endpoint integration test (empty-result scenario) |
| F8 | adapter unit test (`status` field on every `PostItem`); endpoint integration test |
| F9 | adapter unit test (ordering preserved after filter); outside-in test (implicit) |
| F10 | adapter unit test (direct `ListAllPostsAdapter.list()` call with both flag values) |
| F11 | endpoint integration test (token resolution to privilege flag) |
| F12, F13 | code review checklist in validation.md (cache key structure is not observable via HTTP) |
| F14 | running the 0010 outside-in test green after conftest update |
| N1–N10 | code review checklist in validation.md |
