# PRD — Slice 0029: erase_post

## Problem Statement

The `DELETE /{username}/post/{id}` endpoint exists as a bare function in the
flat `posts/router.py` file. It bypasses the Vertical Slice + Hexagonal
architecture that all other post endpoints follow: it calls `crud_users` and
`crud_posts` (FastCRUD) directly from the router function, it has no use-case
class, no port, and no adapter. This makes the business logic impossible to
test in isolation.

Additionally, the current implementation contains an authorization gap: it
verifies that the authenticated caller is the user identified by `{username}`
in the path, but does not verify that the post identified by `{id}` actually
belongs to that user. An authenticated user can therefore delete any post in
the system by supplying their own username in the path and any post's numeric
id, as long as they know the id.

## Solution

Extract the `DELETE /{username}/post/{id}` endpoint into a proper `erase_post`
vertical slice, consistent with `get_post`, `revise_post`, and `delete_user`.
The slice:

- Introduces a `ErasePostCommand` domain command.
- Introduces an `ErasePostPort` protocol with three methods: look up the user
  by username, look up the post verifying ownership, and soft-delete the post.
- Introduces an `ErasePostUseCase` that owns the authorization and
  existence-check logic, raising `DomainError` subclasses only.
- Introduces an `ErasePostAdapter` (implements `ErasePostPort`) using raw
  SQLAlchemy 2.0 async queries.
- Creates `posts/_shared/policies.py` with a reusable `check_post_owner`
  function (parallel to `users/_shared/policies.py`) for use by this slice
  and future post-mutation slices.
- Fixes the ownership gap: the post lookup query includes a
  `created_by_user_id` filter so only the genuine author's post is found.
- Preserves the exact cache-invalidation contract so that the existing Redis
  cache for the `get_post` endpoint continues to be invalidated on deletion.
- Keeps the HTTP contract identical: same path, same auth requirement, same
  response body `{"message": "Post deleted"}`, same status code 200.

## User Stories

1. As an authenticated user, I want `DELETE /{username}/post/{id}` to soft-delete
   my post and return HTTP 200 with `{"message": "Post deleted"}`, so that I can
   remove my own content.
2. As an authenticated user, I want `DELETE /{username}/post/{id}` to return
   HTTP 404 when the `{username}` path parameter does not correspond to a known,
   non-deleted user, so that the endpoint does not leak user-existence information.
3. As an authenticated user, I want `DELETE /{username}/post/{id}` to return
   HTTP 404 when the `{id}` path parameter does not correspond to a non-deleted
   post that belongs to `{username}`, so that I cannot discover or delete posts
   that do not belong to me.
4. As an authenticated user trying to delete another user's post, I want to
   receive HTTP 403, so that the API communicates clearly that I am not permitted
   to modify resources belonging to others.
5. As an unauthenticated caller, I want `DELETE /{username}/post/{id}` to return
   HTTP 401, so that deletion without a valid token is rejected at the auth layer.
6. As a post author, I want my post to be soft-deleted (not permanently removed),
   so that the data can be retained for auditing or recovery purposes.
7. As a client relying on the existing cache-invalidation contract, I want the
   `get_post` cache entry for the deleted post to be invalidated when the post is
   deleted, so that subsequent reads return 404 rather than stale cached data.
8. As a client relying on the existing cache-invalidation contract, I want the
   `list_posts` cache entries for the author to be invalidated when a post is
   deleted, so that the author's post list no longer includes the deleted post.
9. As a developer writing future post-mutation slices, I want a shared
   `check_post_owner` policy function in `posts/_shared/policies.py`, so that
   the ownership enforcement logic is defined in one place and not duplicated
   across slices.

## Implementation Decisions

### Slice structure

A new `erase_post` slice is created under `features/posts/erase_post/` with
the standard subdirectory layout: `domain/`, `data/`, `presentation/`.

### Domain command

`ErasePostCommand` carries three fields:

- `username: str` — path parameter identifying the resource owner. Retained
  for future use-case logic (e.g. status-based deletion gates) and to keep the
  command semantically complete.
- `post_id: int` — path parameter identifying the post to delete.
- `requester_username: str` — from `current_user["username"]`. Used for the
  ownership check.

### Port

`ErasePostPort` is a `@runtime_checkable` `Protocol` with three methods:

- `get_user_by_username(username: str) -> PostAuthor | None` — returns the
  author entity (id + username) or `None` if the user does not exist or is
  soft-deleted. Reuses `PostAuthor` from `posts/_shared/entities.py`.
- `find_post(post_id: int, owner_id: int) -> ErasePostRecord | None` — returns
  `ErasePostRecord(id: int)` if a non-deleted post with the given id exists and
  its `created_by_user_id` matches `owner_id`; returns `None` otherwise.
- `soft_delete(post_id: int) -> None` — sets `is_deleted = True` and
  `deleted_at = now(UTC)` on the post row.

### Use case

`ErasePostUseCase.__call__` applies authorization and existence checks in order:

1. Call `get_user_by_username(command.username)`. If `None`, raise
   `NotFoundDomainError("User not found")`.
2. Call `check_post_owner(command.requester_username, user.username)`. Raises
   `ForbiddenDomainError` if the caller is not the path user.
3. Call `find_post(command.post_id, owner_id=user.id)`. If `None`, raise
   `NotFoundDomainError("Post not found")`.
4. Call `soft_delete(command.post_id)`.

The two-method approach (find + delete) is chosen over a single atomic operation
to support future business logic between verification and deletion (e.g. status
checks, audit events).

### Shared policy

`posts/_shared/policies.py` introduces:

```
check_post_owner(requester_username: str, owner_username: str) -> None
```

Raises `ForbiddenDomainError` when `requester_username != owner_username`.
Parallel to `users/_shared/policies.py::check_owner`.

### Adapter

`ErasePostAdapter` (implements `ErasePostPort`) uses SQLAlchemy 2.0 async:

- `get_user_by_username`: `SELECT ... FROM user WHERE username=:u AND is_deleted=False`.
- `find_post`: `SELECT ... FROM post WHERE id=:id AND created_by_user_id=:owner_id AND is_deleted=False`.
- `soft_delete`: `UPDATE post SET is_deleted=True, deleted_at=:now WHERE id=:id`,
  followed by `session.commit()`.

No `try/except` in the adapter — there are no business-meaningful infrastructure
exceptions to translate for a soft-delete. Unknown failures propagate to the
global exception handler.

### Response schema

`ErasePostResponse(message: str)` in `presentation/schemas.py`. The router
returns `ErasePostResponse(message="Post deleted")`. Serializes as
`{"message": "Post deleted"}`, identical to the current response.

### Router

The presentation router:

- Requires `current_user` via `get_current_user` (authenticated callers only).
- Constructs `ErasePostCommand(username=username, post_id=id, requester_username=current_user["username"])`.
- Calls the use case.
- Returns `ErasePostResponse(message="Post deleted")` with `status_code=200`.

The `@cache` decorator is preserved verbatim:

```
key_prefix="{username}_post_cache", resource_id_name="id",
to_invalidate_extra={"{username}_posts": "{username}"}
```

### DI container

Two new entries in `bootstrap/container.py`:

- `erase_post_adapter` — `providers.Factory(ErasePostAdapter, session_factory=session_factory)`
- `erase_post_use_case` — `providers.Factory(ErasePostUseCase, port=erase_post_adapter)`

### Flat router cleanup

The `erase_post` function is removed from `features/posts/router.py`. The new
slice's router is included via `router.include_router(erase_post_router)`.

### Authorization fix

The current implementation's ownership gap is closed: `find_post` filters by
`created_by_user_id = user.id`, so a post can only be deleted through the
endpoint of the user who created it.

## Testing Decisions

Good tests verify observable behaviour through the public interface — HTTP status
codes, response bodies, and database state — not which internal methods were
called or which SQL queries were issued.

### Use-case unit test

Required. The use case contains branching logic across three steps. Test with a
mocked `ErasePostPort`:

- `get_user_by_username` returns `None` → `NotFoundDomainError("User not found")`.
- User found, `requester_username != user.username` → `ForbiddenDomainError`.
- User found, requester matches, `find_post` returns `None` → `NotFoundDomainError("Post not found")`.
- All checks pass → `soft_delete` called, no exception raised.

Prior art: `tests/features/posts/0026_get_post/domain/test_use_case.py`,
`tests/features/users/delete_user/domain/test_use_case.py` (if it exists).

### Adapter unit test

Using a real async session against the test Postgres database:

- `get_user_by_username`: user exists and is not deleted → `PostAuthor` returned;
  user does not exist → `None`; user is soft-deleted → `None`.
- `find_post`: post exists, owned by user, not deleted → `ErasePostRecord` returned;
  post does not exist → `None`; post exists but owned by a different user → `None`;
  post is soft-deleted → `None`.
- `soft_delete`: after call, row has `is_deleted=True` and `deleted_at` is set.

Prior art: `tests/features/posts/0026_get_post/data/test_adapter.py`.

### Endpoint integration test

`httpx.AsyncClient` against the running app with test Postgres:

- Authenticated as owner, post exists → HTTP 200, `{"message": "Post deleted"}`.
- Authenticated as owner, post not found → HTTP 404.
- Authenticated as owner, post belongs to a different user → HTTP 404.
- Authenticated as a different user → HTTP 403.
- Unauthenticated → HTTP 401.
- Unknown username in path → HTTP 404.

Prior art: `tests/features/posts/0026_get_post/presentation/test_router.py`.

### Outside-in test

One outside-in acceptance test covering the end-to-end flow:

1. Seed `alice` and `bob`.
2. Alice creates a post.
3. Bob attempts `DELETE /api/v1/bob/post/{alice_post_id}` (authenticated as Bob,
   post belongs to Alice) → HTTP 404.
4. Alice attempts `DELETE /api/v1/alice/post/{alice_post_id}` (authenticated as
   Bob pretending to be Alice) → HTTP 403.
5. Alice deletes her own post: `DELETE /api/v1/alice/post/{alice_post_id}`
   authenticated as Alice → HTTP 200, `{"message": "Post deleted"}`.
6. DB assertion: post row has `is_deleted=True`.
7. Subsequent `GET /api/v1/alice/post/{alice_post_id}` → HTTP 404 (post gone).

The slice is not done until this test is green and all pre-existing outside-in
tests remain green.

## Out of Scope

- Refactoring `patch_post` and `erase_db_post` — these remain as flat functions
  in `posts/router.py` and are separate future slices.
- Hard deletion (`erase_db_post`) — remains unchanged and is a separate endpoint.
- Cache key rotation or invalidation strategy changes — the existing key contract
  is preserved deliberately.
- Rate-limit configuration for this endpoint — handled cross-cuttingly by the
  existing middleware.
- Moderation-status-based deletion gates (e.g. preventing deletion of an
  `approved` post) — out of scope for this slice, enabled by the two-step port
  design.

## Further Notes

- The `find_post` + `soft_delete` split (rather than a single atomic adapter
  method) is deliberate: future slices may need to inspect post state (e.g.
  status) between the existence check and the deletion. The design accommodates
  this without a port interface change.
- `PostAuthor` from `posts/_shared/entities.py` is reused as the return type of
  `get_user_by_username`. Its `id` field is required to pass `owner_id` to
  `find_post`, and its `username` field is used by `check_post_owner`.
- The `check_post_owner` function in `posts/_shared/policies.py` is intentionally
  named differently from `users/_shared/policies.py::check_owner` to remain
  greppable per-feature.
