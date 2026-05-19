# 0026 · get_post — Requirements

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md

## Functional requirements

- **F1.** `GET /api/v1/{username}/post/{id}` returns HTTP 200 with a
  `GetPostResponse` body (fields: `id`, `title`, `text`, `media_url`,
  `created_at`, `created_by_user_id`, `username`, `status`, `post_uuid`)
  when the post exists, is not soft-deleted, and has `status = "approved"`,
  regardless of whether the caller is authenticated.

- **F2.** The use case returns the post when `post.status != "approved"` and
  `query.requester_username == query.username` (caller is the post author).

- **F3.** The use case returns the post when `post.status != "approved"` and
  `query.requester_is_privileged == True` (caller is a moderator or superuser).

- **F4.** The use case raises `NotFoundDomainError("Post not found")` when
  `post.status != "approved"` and the caller is neither the post author nor a
  privileged user (moderator / superuser).

- **F5.** The use case raises `NotFoundDomainError("Post not found")` when the
  port returns `None` (post or user does not exist, or is soft-deleted).

- **F6.** The endpoint returns HTTP 404 when the port returns `None` for the
  given `{username}` / `{id}` combination (unknown user, unknown post, soft-deleted
  user, or soft-deleted post).

- **F7.** The endpoint returns HTTP 404 when the post has `status =
  "pending_review"` and the caller is unauthenticated.

- **F8.** The endpoint returns HTTP 404 when the post has `status =
  "pending_review"` and the authenticated caller is not the post author and is
  not a moderator or superuser.

- **F9.** The endpoint returns HTTP 200 when the post has `status =
  "pending_review"` and the authenticated caller is the post author.

- **F10.** The endpoint returns HTTP 200 when the post has `status =
  "pending_review"` and the authenticated caller is a moderator
  (`is_moderator = True`).

- **F11.** The endpoint returns HTTP 200 when the post has `status =
  "pending_review"` and the authenticated caller is a superuser
  (`is_superuser = True`).

- **F12.** The endpoint returns HTTP 404 when the post has `status =
  "changes_requested"` and the caller is unauthenticated or is not the post
  author and is not a privileged user.

- **F13.** The endpoint returns HTTP 200 when the post has `status =
  "changes_requested"` and the authenticated caller is the post author or a
  privileged user.

- **F14.** The router computes `requester_is_privileged = True` when
  `optional_user["is_moderator"] or optional_user["is_superuser"]` is truthy,
  and `False` otherwise (including when `optional_user` is `None`).

- **F15.** The adapter returns a `PostItem` (with `username` populated from the
  joined `User` row and `post_uuid` mapped from `Post.uuid`) when both the user
  and post exist and are not soft-deleted.

- **F16.** The adapter returns `None` when no row matches the combined filter
  `User.username == query.username`, `Post.id == query.post_id`,
  `User.is_deleted == False`, `Post.is_deleted == False`.

- **F17.** The adapter applies no filter on `Post.status`; the full `PostItem`
  (with any status value) is returned when the user/post row exists and is not
  soft-deleted.

- **F18.** The `@cache` decorator on the new endpoint uses
  `key_prefix="{username}_post_cache"` and `resource_id_name="id"`, preserving
  the cache key contract relied upon by the existing `patch_post` and `erase_post`
  invalidation calls.

- **F19.** The `read_post` function is removed from
  `src/app/features/posts/router.py`; the new slice's router is registered via
  `router.include_router(get_post_router)`.

## Non-functional requirements

- **N1.** `GetPostUseCase` is a class with `__call__(self, query: GetPostQuery)`;
  called as `await use_case(query)`. Per `agent_docs/architecture.md` §
  Use-case shape.

- **N2.** `GetPostAdapter` contains no `try/except` — the query is read-only and
  has no business-meaningful exception to translate; infrastructure failures
  propagate to the global `_catch_all` handler. Per
  `agent_docs/error_handling.md` § Right shape: read-only query, no catch.

- **N3.** `GetPostResponse` declares
  `model_config = ConfigDict(from_attributes=True)` to support
  `model_validate()` from a `PostItem` instance.

- **N4.** Every new `.py` file starts with `# FEATURE: get_post — <purpose>`.
  Per `agent_docs/stable_vs_feature.md`.

- **N5.** `GetPostUseCase` never raises `HTTPException`; only `NotFoundDomainError`
  (a `DomainError` subclass) is raised. Per CLAUDE.md rule 1 and
  `agent_docs/error_handling.md`.

- **N6.** No cross-slice imports; `PostItem` is imported from
  `features/posts/_shared/entities.py` (own feature's `_shared/`). Per CLAUDE.md
  rule 7 and `agent_docs/architecture.md` § `_shared/` rules.

- **N7.** All database access is `async def` + `await`; no synchronous ORM calls.
  Per CLAUDE.md locked technology stack.

- **N8.** `mypy src/app` (strict mode) passes for all new code. Per CLAUDE.md §
  Verifying changes.

- **N9.** `ruff format src/app` and `ruff check src/app` pass for all new code.
  Per CLAUDE.md § Verifying changes.

## Out of scope

- Refactoring `patch_post`, `erase_post`, and `erase_db_post` — separate future
  slices.
- Cache key rotation or invalidation strategy changes.
- Soft-delete visibility rules — any post with `is_deleted = True` is 404 for all
  callers.
- Rate-limit configuration — handled cross-cuttingly by existing middleware.
- Pagination or filtering on this endpoint.

## Traceability

| Requirement | Verified by |
|---|---|
| F1 | endpoint integration test; outside-in test (step 8) |
| F2 | use-case unit test (author bypass branch); endpoint integration test (author 200); outside-in test (step 5) |
| F3 | use-case unit test (privileged bypass branch); endpoint integration test (moderator 200); outside-in test (step 6) |
| F4 | use-case unit test (neither-author-nor-privileged branch); endpoint integration test (other user 404) |
| F5 | use-case unit test (port returns None branch) |
| F6 | endpoint integration test (unknown username 404; unknown post id 404; soft-deleted post 404); outside-in tests (steps 9, 10) |
| F7 | endpoint integration test (pending, unauthenticated → 404); outside-in test (step 3) |
| F8 | endpoint integration test (pending, different user → 404); outside-in test (step 4) |
| F9 | endpoint integration test (pending, author → 200); outside-in test (step 5) |
| F10 | endpoint integration test (pending, moderator → 200); outside-in test (step 6) |
| F11 | endpoint integration test (pending, superuser → 200) |
| F12 | use-case unit test (changes_requested, neither branch); endpoint integration test |
| F13 | use-case unit test (changes_requested, author/privileged branch); endpoint integration test |
| F14 | endpoint integration test (privilege flag computation); code review checklist |
| F15 | adapter unit test (happy path with all fields) |
| F16 | adapter unit test (missing user; missing post; soft-deleted post) |
| F17 | adapter unit test (pending_review post returned) |
| F18 | code review checklist in validation.md |
| F19 | code review checklist in validation.md |
| N1–N9 | code review checklist in validation.md |
