# PRD — Slice 0026: get_post

## Problem Statement

The `GET /users/{username}/post/{id}` endpoint exists as a bare function in the
flat `posts/router.py` file. It bypasses the Vertical Slice + Hexagonal
architecture that all other post endpoints follow: it calls `crud_users` and
`crud_posts` (FastCRUD) directly from the router function, it has no use-case
class, no port, and no adapter. This makes it impossible to test the business
logic in isolation, and the business logic that is present is incorrect:

1. The endpoint returns a post regardless of its moderation status — a caller can
   retrieve a `pending_review` or `changes_requested` post via a direct URL, even
   though `list_posts` hides those same posts from non-authors. The two endpoints
   are inconsistent.
2. Moderators and superusers are not given any special access; they see the same
   filtered view as anonymous visitors, which contradicts the moderation model
   established in slices 0012–0021.
3. The response schema (`PostRead`) does not include the author's `username`,
   forcing clients to carry it from a previous request.

## Solution

Extract the `GET /users/{username}/post/{id}` endpoint into a proper `get_post`
vertical slice, consistent with the `list_posts` and `create_post` slices. The
slice introduces:

- A `GetPostQuery` domain command carrying the target username, post id, the
  requester's username (for resource-based ownership check), and a privilege flag
  (for role-based moderator/superuser bypass).
- A `GetPostPort` protocol with a single `get` method that fetches the post via
  a JOIN query and returns a `PostItem` (or `None` if the post or user does not
  exist). The adapter performs no status filtering — it returns the post as-is.
- A `GetPostUseCase` that owns both access-control checks: (a) resource-based —
  the requester is the post author; (b) role-based — the requester is a moderator
  or superuser. If the post's status is not `approved` and neither check passes,
  the use case raises `NotFoundDomainError`, hiding the post as 404.
- A `GetPostAdapter` (implements `GetPostPort`) that issues a single JOIN query
  on `Post` and `User`, returning `PostItem` with `username` populated.
- A `presentation/router.py` that resolves the optional caller via
  `get_optional_user`, computes the privilege flag, builds the query, calls the
  use case, and returns the response. The existing `@cache` decorator is
  preserved with the same key prefix and resource-id name to keep cache
  invalidation working with `patch_post` and `erase_post`.
- The response now includes `username`, matching the `PostItem` shape already
  used by `list_posts`. This is a deliberate contract change.

## User Stories

1. As an unauthenticated visitor, I want `GET /users/{username}/post/{id}` to
   return HTTP 200 with the post body when the post is `approved`, so that I can
   display the post to any reader.
2. As an unauthenticated visitor, I want `GET /users/{username}/post/{id}` to
   return HTTP 404 when the post exists but is `pending_review`, so that
   unapproved content is never publicly accessible via a direct URL.
3. As an unauthenticated visitor, I want `GET /users/{username}/post/{id}` to
   return HTTP 404 when the post exists but is `changes_requested`, so that
   rejected content is never publicly accessible via a direct URL.
4. As an authenticated user who is not the post author, I want the same
   visibility rules as an unauthenticated visitor — only `approved` posts are
   visible to me — so that I cannot access another user's unapproved content.
5. As a post author, I want to retrieve my own post via
   `GET /users/{username}/post/{id}` regardless of its status, so that I can
   inspect a `pending_review` or `changes_requested` post directly.
6. As a moderator, I want to retrieve any post regardless of its status via
   `GET /users/{username}/post/{id}`, so that I can review content before
   approving or requesting changes.
7. As a superuser, I want to retrieve any post regardless of its status via
   `GET /users/{username}/post/{id}`, so that I have full administrative
   visibility over all content.
8. As any caller, I want HTTP 404 when the `{username}` path parameter does not
   correspond to a known, non-deleted user, so that the endpoint does not leak
   user existence information.
9. As any caller, I want HTTP 404 when the `{id}` path parameter does not
   correspond to a known, non-deleted post owned by `{username}`, so that posts
   belonging to other users are not retrievable via a mismatched path.
10. As a frontend developer, I want the response body to include `username`, so
    that I can display the author's handle without a separate user request.
11. As a frontend developer, I want the response body to include `status`, so
    that I can render a moderation-state badge alongside the post.
12. As a frontend developer, I want the response body to include `post_uuid`,
    so that I can use the stable UUID as a shareable identifier.
13. As a client relying on the existing cache-invalidation contract, I want the
    cache key format to remain unchanged after this refactor, so that existing
    `patch_post` and `erase_post` invalidation logic continues to work without
    modification.

## Implementation Decisions

### Slice structure

A new `get_post` slice is created under `features/posts/get_post/` with the
standard subdirectory layout: `domain/`, `data/`, `presentation/`.

### Domain command

`GetPostQuery` carries four fields:
- `username: str` — path parameter identifying the resource owner.
- `post_id: int` — path parameter identifying the post.
- `requester_username: str | None = None` — `None` for unauthenticated callers;
  set to the caller's username otherwise. Used for the resource-based ownership
  check.
- `requester_is_privileged: bool = False` — `True` when the caller is a
  moderator or superuser. Computed by the router from `optional_user`'s
  `is_moderator` and `is_superuser` flags. Separates role-based policy from
  resource-based policy.

### Port

`GetPostPort` is a `@runtime_checkable` `Protocol` with one method:

```
get(query: GetPostQuery) -> PostItem | None
```

The port returns `None` when the user or post does not exist. It performs no
status filtering. The use case is responsible for all policy decisions.

### Use case

`GetPostUseCase.__call__` applies access-control in two stages:

1. Call the port. If `None` is returned, raise `NotFoundDomainError("Post not found")`.
2. If `post.status != "approved"`, check whether the caller may bypass the filter:
   - Resource-based: `query.requester_username == query.username` (is the author).
   - Role-based: `query.requester_is_privileged` (is moderator or superuser).
   If neither condition holds, raise `NotFoundDomainError("Post not found")`.
3. Return the `PostItem`.

The use case raises `NotFoundDomainError` (never `HTTPException`) for both
"does not exist" and "exists but not visible" cases — both are presented as 404
to the caller, preventing status enumeration.

### Adapter

`GetPostAdapter` (implements `GetPostPort`) issues a single `SELECT` with a
`JOIN` on `User` and `Post`, filtered by `User.username`, `Post.id`,
`User.is_deleted == False`, and `Post.is_deleted == False`. No filter on
`Post.status` — that decision belongs to the use case. Returns a `PostItem`
with `username` populated from the joined `User` row, or `None` if no row
matches.

### Response schema

`GetPostResponse` in `presentation/schemas.py` mirrors `PostItemSchema` from
`list_posts`: it includes `id`, `title`, `text`, `media_url`, `created_at`,
`created_by_user_id`, `username`, `status`, and `post_uuid`. The response is
validated via `model_validate` from the returned `PostItem`.

### Router

The presentation router resolves the optional caller with `get_optional_user`,
computes `requester_is_privileged = bool(optional_user and (optional_user["is_superuser"] or optional_user["is_moderator"]))`,
constructs `GetPostQuery`, calls the use case, and returns `GetPostResponse`.

The `@cache` decorator preserves the existing key contract:
```
key_prefix="{username}_post_cache", resource_id_name="id"
```
This is intentional: `patch_post` and `erase_post` in the flat `router.py`
invalidate this key; changing it would break their invalidation without touching
those endpoints, which are out of scope.

### DI container

Two new entries in `bootstrap/container.py`:
- `get_post_adapter` — `providers.Factory(GetPostAdapter, session_factory=session_factory)`
- `get_post_use_case` — `providers.Factory(GetPostUseCase, port=get_post_adapter)`

### Flat router cleanup

The `read_post` function is removed from `features/posts/router.py`. The new
slice's router is included via `router.include_router(get_post_router)`. The
three remaining flat endpoints (`patch_post`, `erase_post`, `erase_db_post`)
are unchanged.

### API contract change

The response body gains two fields compared to the old `PostRead`:
- `username: str` — the author's handle.
- `status: str` — the post's moderation status.

All previously present fields (`id`, `title`, `text`, `media_url`,
`created_by_user_id`, `created_at`, `post_uuid`) are preserved.

## Testing Decisions

Good tests verify observable behaviour through the public interface — HTTP status
codes, response bodies, and database state — not which internal methods were
called or which SQL queries were issued.

### Use-case unit test

Required. The use case now contains non-trivial branching logic (resource-based
and role-based checks). Test with a mocked `GetPostPort`:

- Port returns `None` → `NotFoundDomainError` raised.
- Port returns an `approved` post, no auth → post returned.
- Port returns a `pending_review` post, requester is author → post returned.
- Port returns a `pending_review` post, requester is privileged (moderator/superuser) → post returned.
- Port returns a `pending_review` post, requester is neither author nor privileged → `NotFoundDomainError` raised.
- Port returns a `changes_requested` post, same matrix of requester roles.

Prior art: `tests/features/posts/0017_moderate_post/domain/test_use_case.py`,
`tests/features/posts/0018_revise_post/domain/test_use_case.py`.

### Adapter unit test

Using a real async session against the test Postgres database, verify:

- User and post both exist, not deleted → `PostItem` returned with all fields
  populated including `username`.
- User does not exist → `None` returned.
- Post does not exist for that user → `None` returned.
- Post exists but is soft-deleted → `None` returned.
- Post has `status = pending_review` → `PostItem` returned (adapter does not filter).

Prior art: `tests/features/posts/0009_list_posts/data/test_adapter.py`.

### Endpoint integration test

`httpx.AsyncClient` against the running app with test Postgres:

- Approved post, unauthenticated → HTTP 200, correct body including `username` and `status`.
- Pending post, unauthenticated → HTTP 404.
- Pending post, author authenticated → HTTP 200.
- Pending post, moderator authenticated → HTTP 200.
- Pending post, superuser authenticated → HTTP 200.
- Pending post, different authenticated user → HTTP 404.
- Unknown username → HTTP 404.
- Unknown post id → HTTP 404.
- Post id belongs to different user → HTTP 404.

Prior art: `tests/features/posts/0009_list_posts/presentation/test_router.py`.

### Outside-in test

One outside-in acceptance test covering the end-to-end flow:

1. Register `alice` and `bob`; promote `carol` to moderator.
2. Alice creates a post (defaults to `pending_review`).
3. Unauthenticated `GET /users/alice/post/{id}` → HTTP 404.
4. Authenticated as `bob` → HTTP 404.
5. Authenticated as `alice` (author) → HTTP 200, `status = "pending_review"`,
   `username = "alice"` in response body.
6. Authenticated as `carol` (moderator) → HTTP 200.
7. Directly set post status to `approved` in the DB via the test session.
8. Unauthenticated `GET /users/alice/post/{id}` → HTTP 200, `status = "approved"`.
9. `GET /users/unknown/post/{id}` → HTTP 404.
10. `GET /users/alice/post/99999` → HTTP 404.

The slice is not done until this test is green and all pre-existing outside-in
tests remain green.

## Out of Scope

- Refactoring `patch_post`, `erase_post`, and `erase_db_post` — these remain as
  flat functions in `posts/router.py` and are separate future slices.
- Cache key rotation or invalidation strategy changes — the existing key contract
  is preserved deliberately.
- Soft-delete visibility rules — any post with `is_deleted = True` is treated as
  non-existent (404) for all callers, without exception.
- Rate-limit configuration for this endpoint — handled cross-cuttingly by the
  existing rate-limit middleware.
- Adding pagination or filtering to the single-post endpoint — it returns exactly
  one post.

## Further Notes

- The resource-based and role-based access checks are intentionally separated in
  the query command (`requester_username` vs `requester_is_privileged`). This
  models the two distinct policy types explicitly rather than collapsing them into
  a single `can_see_all` flag, keeping the domain command semantically honest.
- The use case hides non-visible posts as `NotFoundDomainError` (404) rather than
  `ForbiddenDomainError` (403). This prevents callers from enumerating post
  statuses by probing the endpoint.
- `PostItem` from `posts/_shared/entities.py` is reused as the use-case return
  type. No custom entity is needed for this slice.
- The `@cache` decorator on the new router endpoint must reference `resource_id_name="id"`
  (matching the path parameter name) to maintain key compatibility with the
  existing invalidation calls in `patch_post` and `erase_post`.
