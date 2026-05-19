# PRD — Slice 0030: erase_db_post

## Problem Statement

The `DELETE /{username}/db_post/{id}` endpoint exists as a bare function in the
flat `posts/router.py` file. It bypasses the Vertical Slice + Hexagonal
architecture that all other post endpoints follow: it calls `crud_users` and
`crud_posts` (FastCRUD) directly from the router function, it has no use-case
class, no port, and no adapter. This makes the business logic impossible to
test in isolation.

Additionally, the current implementation contains an authorization gap: it
verifies that the authenticated caller is a superuser and that the user
identified by `{username}` exists, but does not verify that the post identified
by `{id}` actually belongs to that user. A superuser can therefore permanently
delete any post in the system by supplying any valid `{username}` in the path
and any post's numeric id, as long as they know the id.

## Solution

Extract the `DELETE /{username}/db_post/{id}` endpoint into a proper
`erase_db_post` vertical slice, consistent with `erase_post` (0029),
`delete_db_user` (0008), and other completed slices.

The slice:

- Introduces an `EraseDbPostCommand` domain command with two fields: `username`
  and `post_id`.
- Introduces an `EraseDbPostPort` protocol with three methods: look up the user
  by username, look up the post verifying ownership, and hard-delete the post.
- Introduces an `EraseDbPostUseCase` that owns the existence-check logic,
  raising `DomainError` subclasses only.
- Introduces an `EraseDbPostAdapter` (implements `EraseDbPostPort`) using raw
  SQLAlchemy 2.0 async queries.
- Fixes the ownership gap: the post lookup query includes a
  `created_by_user_id` filter so only the genuine author's post is found through
  the given username namespace.
- Preserves the exact cache-invalidation contract so that the existing Redis
  cache for the `get_post` and `list_posts` endpoints continues to be
  invalidated on deletion.
- Keeps the HTTP contract identical: same path, same auth requirement
  (`get_current_superuser`), same response body
  `{"message": "Post deleted from the database"}`, same status code 200.

## User Stories

1. As a superuser, I want `DELETE /{username}/db_post/{id}` to permanently
   remove the post row from the database and return HTTP 200 with
   `{"message": "Post deleted from the database"}`, so that I can fully purge
   content when required.
2. As a superuser, I want `DELETE /{username}/db_post/{id}` to return HTTP 404
   when `{username}` does not correspond to a known, non-deleted user, so that
   the endpoint does not silently operate on an invalid namespace.
3. As a superuser, I want `DELETE /{username}/db_post/{id}` to return HTTP 404
   when the post identified by `{id}` does not exist, is soft-deleted, or does
   not belong to `{username}`, so that I cannot accidentally operate across user
   namespaces.
4. As a superuser, I want `DELETE /{username}/db_post/{id}` to return HTTP 404
   when the post is already soft-deleted, so that the hard-delete path is
   reserved for live posts only and data-purge of soft-deleted records is a
   separate, explicit operation.
5. As an authenticated non-superuser, I want `DELETE /{username}/db_post/{id}`
   to return HTTP 403, so that permanent deletion is restricted to superusers
   only.
6. As an unauthenticated caller, I want `DELETE /{username}/db_post/{id}` to
   return HTTP 401, so that deletion without a valid token is rejected at the
   auth layer.
7. As a client relying on the existing cache-invalidation contract, I want the
   `get_post` cache entry for the deleted post to be invalidated when the post
   is hard-deleted, so that subsequent reads return 404 rather than stale cached
   data.
8. As a client relying on the existing cache-invalidation contract, I want the
   `list_posts` cache entries for the author to be invalidated when a post is
   hard-deleted, so that the author's post list no longer includes the deleted
   post.
9. As a developer, I want the hard-delete endpoint to follow the same slice
   structure as `erase_post`, so that any engineer familiar with one slice can
   navigate the other without re-learning conventions.

## Implementation Decisions

### Slice structure

A new `erase_db_post` slice is created under `features/posts/erase_db_post/`
with the standard subdirectory layout: `domain/`, `data/`, `presentation/`.

### Domain command

`EraseDbPostCommand` carries two fields:

- `username: str` — path parameter identifying the resource owner's namespace.
- `post_id: int` — path parameter identifying the post to hard-delete.

No `requester_username` field. Superuser authorization is enforced at the
FastAPI router layer via `get_current_superuser` before the use case runs. The
use case has no caller-identity policy to enforce.

### Port

`EraseDbPostPort` is a `@runtime_checkable` `Protocol` with three methods:

- `get_user_by_username(username: str) -> PostAuthor | None` — returns the
  author entity (`id` + `username`) or `None` if the user does not exist or is
  soft-deleted. Reuses `PostAuthor` from `posts/_shared/entities.py`.
- `find_post(post_id: int, owner_id: int) -> EraseDbPostRecord | None` —
  returns `EraseDbPostRecord(id: int)` if a non-soft-deleted post with the
  given id exists and its `created_by_user_id` matches `owner_id`; returns
  `None` otherwise.
- `hard_delete(post_id: int) -> None` — issues a permanent `DELETE` against
  the post row.

### Domain entity

`EraseDbPostRecord(id: int)` is defined in `erase_db_post/domain/entities.py`.
It is structurally identical to `ErasePostRecord` from the `erase_post` slice
but is defined independently: the two slices must not share types across slice
boundaries.

### Use case

`EraseDbPostUseCase.__call__` applies existence checks in order:

1. Call `get_user_by_username(command.username)`. If `None`, raise
   `NotFoundDomainError("User not found")`.
2. Call `find_post(command.post_id, owner_id=user.id)`. If `None`, raise
   `NotFoundDomainError("Post not found")`.
3. Call `hard_delete(command.post_id)`.

The use case raises only `NotFoundDomainError`. No `ForbiddenDomainError` is
raised from the use case — the superuser gate is already enforced at the router
layer. A superuser who uses the wrong username namespace receives 404 (post not
found for that namespace), not 403.

### Adapter

`EraseDbPostAdapter` (implements `EraseDbPostPort`) uses SQLAlchemy 2.0 async:

- `get_user_by_username`: `SELECT ... FROM user WHERE username=:u AND is_deleted=False`.
- `find_post`: `SELECT ... FROM post WHERE id=:id AND created_by_user_id=:owner_id AND is_deleted=False`.
- `hard_delete`: `DELETE FROM post WHERE id=:id`, followed by `session.commit()`.

No `try/except` in the adapter — there are no business-meaningful infrastructure
exceptions to translate for a hard-delete. Unknown failures propagate to the
global exception handler.

### Response schema

`EraseDbPostResponse(message: str)` in `presentation/schemas.py`. The router
returns `EraseDbPostResponse(message="Post deleted from the database")`.
Serializes as `{"message": "Post deleted from the database"}`, identical to the
current response. The distinct message text (vs. `erase_post`'s
`"Post deleted"`) is preserved deliberately: it is the only observable signal
to a caller that a hard delete occurred.

### Router

The presentation router:

- Requires the caller to be a superuser via `get_current_superuser` (no
  `current_user` dict is passed into the command).
- Constructs `EraseDbPostCommand(username=username, post_id=id)`.
- Calls the use case.
- Returns `EraseDbPostResponse(message="Post deleted from the database")` with
  `status_code=200`.

The `@cache` decorator is preserved verbatim from the current flat endpoint:

```
key_prefix="{username}_post_cache", resource_id_name="id",
to_invalidate_extra={"{username}_posts": "{username}"}
```

### DI container

Two new entries in `bootstrap/container.py`:

- `erase_db_post_adapter` — `providers.Factory(EraseDbPostAdapter, session_factory=session_factory)`
- `erase_db_post_use_case` — `providers.Factory(EraseDbPostUseCase, port=erase_db_post_adapter)`

### Flat router cleanup

The `erase_db_post` function and its `@cache` decoration are removed from
`features/posts/router.py`. The new slice's router is included via
`router.include_router(erase_db_post_router)`.

### Authorization fix

The current implementation's ownership gap is closed: `find_post` filters by
`created_by_user_id = user.id`, so a post can only be hard-deleted through the
endpoint of the user who created it.

## Testing Decisions

Good tests verify observable behaviour through the public interface — HTTP status
codes, response bodies, and database state — not which internal methods were
called or which SQL queries were issued.

### Use-case unit test

Required. The use case contains branching logic across two steps. Test with a
mocked `EraseDbPostPort`:

- `get_user_by_username` returns `None` → `NotFoundDomainError("User not found")`.
- User found, `find_post` returns `None` → `NotFoundDomainError("Post not found")`.
- Both checks pass → `hard_delete` called, no exception raised.

Prior art: `tests/features/posts/0029_erase_post/domain/test_use_case.py`.

### Adapter unit test

Using a real async session against the test Postgres database:

- `get_user_by_username`: user exists and is not deleted → `PostAuthor` returned;
  user does not exist → `None`; user is soft-deleted → `None`.
- `find_post`: post exists, owned by user, not soft-deleted → `EraseDbPostRecord`
  returned; post does not exist → `None`; post exists but owned by a different
  user → `None`; post is soft-deleted → `None`.
- `hard_delete`: after call, the row no longer exists in the database.

Prior art: `tests/features/posts/0029_erase_post/data/test_adapter.py`.

### Endpoint integration test

`httpx.AsyncClient` against the running app with test Postgres:

- Authenticated as superuser, correct user and post → HTTP 200,
  `{"message": "Post deleted from the database"}`.
- Authenticated as superuser, unknown username → HTTP 404.
- Authenticated as superuser, post does not exist → HTTP 404.
- Authenticated as superuser, post belongs to a different user (wrong namespace)
  → HTTP 404.
- Authenticated as superuser, post is soft-deleted → HTTP 404.
- Authenticated as a non-superuser → HTTP 403.
- Unauthenticated → HTTP 401.

Prior art: `tests/features/posts/0029_erase_post/presentation/test_router.py`.

### Outside-in test

One outside-in acceptance test covering the end-to-end flow:

1. Seed `alice` (regular user) and a superuser `admin`.
2. Alice creates a post.
3. Admin attempts `DELETE /api/v1/bob/db_post/{alice_post_id}` (wrong username
   namespace) → HTTP 404.
4. A non-superuser attempts `DELETE /api/v1/alice/db_post/{alice_post_id}`
   → HTTP 403.
5. Admin hard-deletes: `DELETE /api/v1/alice/db_post/{alice_post_id}` → HTTP
   200, `{"message": "Post deleted from the database"}`.
6. DB assertion: the post row no longer exists (not soft-deleted — gone).
7. Subsequent `GET /api/v1/alice/post/{alice_post_id}` → HTTP 404.

The slice is not done until this test is green and all pre-existing outside-in
tests remain green.

## Out of Scope

- Soft-delete of posts (`erase_post`, slice 0028) — separate slice.
- Hard-deletion of already-soft-deleted posts — a future data-purge slice if
  needed.
- Rate-limit configuration for this endpoint — handled cross-cuttingly by
  existing middleware.
- Moderation-status-based deletion gates — out of scope.
- Cache key rotation or invalidation strategy changes — the existing contract is
  preserved deliberately.
- Any changes to the `posts/_shared/policies.py` — `erase_db_post` does not
  need `check_post_owner` because no caller-identity check is performed in the
  use case.

## Further Notes

- The `find_post` + `hard_delete` split (rather than a single atomic adapter
  method) is consistent with `erase_post` and deliberate: future slices may need
  to inspect post state between the existence check and the deletion without
  changing the port interface.
- `PostAuthor` from `posts/_shared/entities.py` is reused as the return type of
  `get_user_by_username`. Its `id` field is required to pass `owner_id` to
  `find_post`.
- `EraseDbPostRecord(id: int)` is defined independently in this slice's
  `domain/entities.py` and is not shared with `erase_post`. The structural
  similarity is coincidental; cross-slice type sharing via `_shared` is
  reserved for types that encode reusable policy or richer structure.
- The use case raises only `NotFoundDomainError`. There is no 403 path from the
  use case itself. A superuser who uses a mismatched username namespace receives
  404 ("Post not found") because `find_post` filters by `owner_id` and simply
  returns `None` — the same response as for a genuinely missing post.
