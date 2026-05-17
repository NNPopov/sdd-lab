# 0021 · list_posts_visibility — Requirements

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md

## Functional requirements

**Visibility filtering**

- **F1.** When the request has no `Authorization` header, `GET /api/v1/{username}/posts`
  returns HTTP 200 containing only posts whose `status = 'approved'`.
- **F2.** When the request carries a valid Bearer token for a user whose `username`
  differs from the path parameter `{username}`, `GET /api/v1/{username}/posts`
  returns HTTP 200 containing only posts whose `status = 'approved'`.
- **F3.** When the request carries a valid Bearer token for the user whose `username`
  matches the path parameter `{username}`, `GET /api/v1/{username}/posts` returns
  HTTP 200 containing all non-deleted posts regardless of status.
- **F4.** When the target user has no approved posts and the caller is not the author,
  the endpoint returns HTTP 200 with `items: []` and `total_count: 0`.

**Response schema**

- **F5.** Every item in the `items` array of `GET /api/v1/{username}/posts` carries
  a `status` field containing the post's current moderation status string.
- **F6.** The existing response fields (`id`, `title`, `text`, `media_url`,
  `created_at`, `created_by_user_id`, `username`) are unchanged.

**Domain command**

- **F7.** `ListPostsQuery` carries `requester_username: str | None = None`; the
  default `None` represents an unauthenticated caller.

**Adapter — visibility filter**

- **F8.** `ListPostsAdapter.list()` adds `WHERE post.status = 'approved'` to both
  the count query and the rows query when `query.requester_username != query.username`
  (including when `requester_username is None`).
- **F9.** `ListPostsAdapter.list()` omits the `status` filter entirely when
  `query.requester_username == query.username`.
- **F10.** `ListPostsAdapter.list()` maps `status=post.status` on every `PostItem`
  it constructs, in all code paths.

**Cache key**

- **F11.** The router defines a `_get_view` dependency that returns `"author"` when
  the resolved optional user's `username` matches the path `username`, and `"public"`
  otherwise; `view` is an endpoint function parameter so the `@cache` decorator can
  interpolate it in the key.
- **F12.** The cache key for the author view is
  `{username}_posts:author:page_{page}:items_per_page:{items_per_page}`.
- **F13.** The cache key for the public view is
  `{username}_posts:public:page_{page}:items_per_page:{items_per_page}`.

**Shared entity**

- **F14.** `PostItem` in `src/app/features/posts/_shared/entities.py` carries
  `status: str` as a required field (no default).

**list_posts presentation schema**

- **F15.** `PostItemSchema` in `list_posts/presentation/schemas.py` carries
  `status: str` as a required field.

**list_all_posts updates (side-effect of F14)**

- **F16.** `PostItemSchema` in `list_all_posts/presentation/schemas.py` carries
  `status: str` as a required field.
- **F17.** `ListAllPostsAdapter.list()` maps `status=post.status` on every `PostItem`
  it constructs.

**Pre-condition: 0009 test update**

- **F18.** Posts seeded in `tests/features/posts/0009_list_posts/list_posts_outside_in_test.py`
  are created with `status = 'approved'` so the 0009 outside-in test continues to
  pass after visibility filtering is active.

## Non-functional requirements

- **N1.** `ListPostsUseCase` remains a class with a single `__call__(query: ListPostsQuery) -> PostPage`
  method; invoked as `await use_case(query)`. Per `agent_docs/architecture.md`.
- **N2.** `ListPostsAdapter` catches no exceptions; it is a read-only query with no
  business-meaningful exception path. Infrastructure failures propagate to the global
  handler. Per `agent_docs/error_handling.md`.
- **N3.** All Pydantic schemas that are populated from ORM attributes use
  `model_config = ConfigDict(from_attributes=True)`. Per `agent_docs/architecture.md`.
- **N4.** No new `.py` files are created by this slice; all changes are to existing
  `# FEATURE:` files. Per `agent_docs/stable_vs_feature.md`.
- **N5.** No `HTTPException` is raised inside `ListPostsUseCase`. Per
  `agent_docs/error_handling.md`.
- **N6.** `list_posts/presentation/router.py` imports `get_optional_user` from
  `features/users/dependencies` using a relative import (`from ....users.dependencies`);
  it imports nothing from another slice's `domain/`, `data/`, or `presentation/`.
  Per `agent_docs/architecture.md`.
- **N7.** All database calls in modified adapters are `async def` + `await`; no
  synchronous DB I/O. Per CLAUDE.md.
- **N8.** `mypy --strict` passes for all modified source files. Per CLAUDE.md.
- **N9.** `ruff format` and `ruff check` pass for all modified source files. Per CLAUDE.md.

## Out of scope

- Visibility filtering on `GET /posts` (global feed) — slice 0022.
- Moderator or superuser bypass of the `approved`-only filter on per-user profile feeds.
- Cache invalidation when a post's status changes (existing `{username}_posts:*`
  wildcards cover both `author` and `public` segments).
- Rate limiting on this endpoint.
- Adding `post_uuid` or `PostModerationLog` entries to the profile-feed response.

## Traceability

| Requirement | Verified by |
|---|---|
| F1 | endpoint integration test; outside-in test (step 4) |
| F2 | endpoint integration test; outside-in test (step 6) |
| F3 | endpoint integration test; outside-in test (step 5) |
| F4 | endpoint integration test |
| F5 | endpoint integration test; outside-in test |
| F6 | endpoint integration test |
| F7 | code review |
| F8 | adapter unit test (non-author and unauthenticated branches) |
| F9 | adapter unit test (author branch) |
| F10 | adapter unit test (status field on all returned items) |
| F11 | code review |
| F12, F13 | code review; endpoint integration test (cache key verification) |
| F14 | code review |
| F15 | endpoint integration test; outside-in test |
| F16 | code review |
| F17 | code review |
| F18 | 0009 outside-in test (must be green before implementation begins) |
| N1–N9 | code review checklist in validation.md |
