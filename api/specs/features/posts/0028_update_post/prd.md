# PRD — 0028: Update Post (`PATCH /{username}/post/{id}`)

## Problem Statement

The `PATCH /{username}/post/{id}` endpoint is implemented as a fat inline handler
in `features/posts/router.py` that calls FastCRUD repositories directly, performs
user lookup, ownership enforcement, and post existence checks all inside the HTTP
layer. There is no use-case class, no port, no command object, and no DI container
wiring. This violates the project's Vertical Slice + Hexagonal architecture and
makes the business logic untestable in isolation.

## Solution

Extract the endpoint into a proper vertical slice at `features/posts/update_post/`
following the same structure as `features/posts/create_post/` and
`features/posts/get_post/`. The handler becomes a thin router that converts the
HTTP request into a command and delegates to a use-case class via a DI-managed
port. The use-case owns the user lookup, the ownership check, the post existence
check, and the update logic. The old `patch_post` inline handler in
`features/posts/router.py` is deleted after the new slice is in place.

## User Stories

1. As an authenticated API consumer, I want to update the title of my post via
   `PATCH /{username}/post/{id}`, so that I can correct or improve the heading.
2. As an authenticated API consumer, I want to update the body text of my post,
   so that I can revise the content after publication.
3. As an authenticated API consumer, I want to update the media URL of my post,
   so that I can change the associated image or video link.
4. As an authenticated API consumer, I want to supply only the fields I wish to
   change in the request body, so that I do not overwrite fields I did not intend
   to modify.
5. As an authenticated API consumer, I want to receive a structured acknowledgment
   response confirming the update succeeded, so that my client can handle the
   result predictably.
6. As an API consumer, I want to receive HTTP 404 when I attempt to update a post
   under a username that does not exist, so that I get a clear error for invalid
   requests.
7. As an API consumer, I want to receive HTTP 403 when I attempt to update a post
   under a username that is not mine, so that other users' posts are protected.
8. As an API consumer, I want to receive HTTP 404 when the post id does not exist
   or has been soft-deleted, so that I cannot update removed content.
9. As an API consumer, I want the post cache to be invalidated after a successful
   update, so that subsequent `GET` requests return fresh data.
10. As an API consumer, I want the user's post list cache to be invalidated after
    a successful update, so that list endpoints also return up-to-date results.
11. As a developer, I want the ownership check isolated inside the use-case, so
    that it can be unit-tested without a database or HTTP stack.
12. As a developer, I want the data adapter to be injected via a port protocol,
    so that the persistence implementation can be swapped without touching the
    use-case or router.
13. As a developer, I want the slice wired into the DI container, so that
    dependency injection is consistent with all other slices in the project.
14. As a developer, I want the old inline `patch_post` handler deleted after the
    new slice lands, so that there is exactly one implementation of this behaviour.
15. As a developer, I want the `PostAuthor` entity promoted to `posts/_shared/`,
    so that both `create_post` and `update_post` share the same user identity type
    without a cross-slice domain import.

## Implementation Decisions

### Modules to build

- **Domain command** — `UpdatePostCommand` with fields `target_username: str`,
  `requester_username: str`, `post_id: int`, `title: str | None`,
  `text: str | None`, `media_url: str | None`. All content fields are optional
  (partial update semantics).
- **Port** — `UpdatePostPort`, a `@runtime_checkable` Protocol with three methods:
  `get_user_by_username(username: str) -> PostAuthor | None`,
  `get_post_by_id(post_id: int) -> PostItem | None`, and
  `update(post_id: int, command: UpdatePostCommand) -> None`.
- **Use case** — `UpdatePostUseCase`, a class with `__init__(port: UpdatePostPort)`
  and `async def __call__(command: UpdatePostCommand) -> None`. Steps:
  (1) call `port.get_user_by_username(command.target_username)`; raise
  `NotFoundDomainError("User not found")` if None.
  (2) Compare `command.requester_username` with `author.username`; raise
  `ForbiddenDomainError` if they differ.
  (3) call `port.get_post_by_id(command.post_id)`; raise
  `NotFoundDomainError("Post not found")` if None.
  (4) call `port.update(command.post_id, command)` and return.
- **Data adapter** — `UpdatePostAdapter(UpdatePostPort)`. Receives an
  `async_sessionmaker`. `get_user_by_username` queries the `User` table filtered
  by `username` and `is_deleted = false`, returns `PostAuthor` or `None`.
  `get_post_by_id` queries the `Post` table filtered by `id` and
  `is_deleted = false`, returns `PostItem` or `None`. `update` executes a
  SQLAlchemy `UPDATE` on the `Post` row for the given `post_id`, setting only the
  non-None fields from the command plus `updated_at = datetime.now(UTC)`. No
  FastCRUD usage.
- **Presentation schemas** — `UpdatePostRequest` (fields: `title: str | None`,
  `text: str | None`, `media_url: str | None`; `extra="forbid"`, same validation
  constraints as the current `PostUpdate`) and `UpdatePostResponse`
  (`message: str`). These are slice-local.
- **Presentation router** — single `PATCH /{username}/post/{id}` endpoint. Reads
  `username` and `id` from the path, `current_user["username"]` from the auth
  dependency. Decorated with `@cache` for invalidation (see below). Builds
  `UpdatePostCommand`, calls the use-case, returns
  `UpdatePostResponse(message="Post updated")` with status 200.

### Modules to modify

- **`posts/_shared/entities.py`** — add `PostAuthor(id: int, username: str)`.
  The `create_post` slice's local `PostAuthor` definition is replaced with an
  import from `_shared/` to avoid duplication.
- **`features/posts/router.py`** — include the `update_post` sub-router. Delete
  the `patch_post` inline handler and its now-unused imports.
- **`bootstrap/container.py`** — two new providers: `update_post_adapter`
  (Factory, receives `session_factory`) and `update_post_use_case` (Factory,
  receives `update_post_adapter`).

### Architectural decisions

- The response follows CQRS: the command (PATCH) returns only an acknowledgment.
  Clients that need the updated post state issue a separate `GET` request. This
  matches the existing `create_post` pattern and avoids conflating write and read
  paths.
- The response is `UpdatePostResponse(message: str)` — a proper Pydantic schema
  rather than a bare `dict[str, str]` — so the endpoint has a typed
  `response_model` and the OpenAPI schema is accurate.
- Cache invalidation uses the same decorator and key patterns as the original
  `patch_post` handler: primary key `{username}_post_cache` with
  `resource_id_name="id"` and extra invalidation of `{username}_posts:*`.
- Ownership is checked by comparing usernames (not numeric IDs), consistent with
  `create_post`, `delete_user`, and `update_user`.
- `updated_at` is set by the adapter at write time (`datetime.now(UTC)`); it is
  an infrastructure concern, not a business rule carried in the command.
- `PostAuthor` is promoted to `posts/_shared/entities.py`. The `create_post`
  slice imports it from there instead of defining its own copy.

### API contract (unchanged from current)

- Method: `PATCH`
- Path: `/{username}/post/{id}`
- Auth: Bearer token required (`get_current_user`)
- Request body: `{ "title": "...", "text": "...", "media_url": "..." }` — all fields optional
- Response 200: `{ "message": "Post updated" }`
- Response 403: user is not the owner of the username
- Response 404: username not found or post not found / soft-deleted

## Testing Decisions

Good tests verify observable behavior through the public interface, not
implementation details. They do not assert which internal methods were called
unless the call itself is the behavior under test.

### Use-case unit test

- Mock `UpdatePostPort`. Call `UpdatePostUseCase` with an `UpdatePostCommand`.
- Assert `NotFoundDomainError` is raised when `get_user_by_username` returns None.
- Assert `ForbiddenDomainError` is raised when `requester_username` differs from
  the returned author's username.
- Assert `NotFoundDomainError` is raised when `get_post_by_id` returns None.
- Assert `port.update` is called with the correct `post_id` and command on the
  happy path.
- Prior art: `tests/features/posts/0011_create_post/` use-case unit test.

### Adapter unit test

- Use a real async session against the test Postgres database (no mocks).
- `get_user_by_username`: assert `PostAuthor` returned for an existing active
  user; `None` for a soft-deleted user; `None` for an unknown username.
- `get_post_by_id`: assert `PostItem` returned for an existing active post;
  `None` for a soft-deleted post; `None` for an unknown id.
- `update`: seed a user and post, call the adapter, assert the ORM row reflects
  the updated fields and that `updated_at` is populated.
- Prior art: `tests/features/posts/0011_create_post/` adapter unit test.

### Endpoint integration test

- Use `httpx.AsyncClient` against the running app with test Postgres.
- Assert HTTP 200 and `{"message": "Post updated"}` on the happy path.
- Assert HTTP 404 when the username does not exist.
- Assert HTTP 403 when the authenticated user does not match the path username.
- Assert HTTP 404 when the post id does not exist.
- Assert HTTP 422 for a request body that violates field constraints (e.g. title
  too short).
- Prior art: `tests/features/posts/0011_create_post/` integration test.

### Outside-in test

- Acceptance gate for the slice. Must be RED before implementation, GREEN after.
- Covers the full happy path: authenticate as a user, PATCH their post, assert
  HTTP 200 and `{"message": "Post updated"}`, then GET the post and confirm the
  field values changed.

## Out of Scope

- Migrating any other post endpoint (`erase_post`, `erase_db_post`) to the
  vertical slice pattern.
- Returning the full updated post in the PATCH response (CQRS: reads go through
  `get_post`).
- Changing the post's `status` field via this endpoint (status transitions are
  handled by the moderation flow).
- Rate limiting on the update-post endpoint.
- Removing `PostUpdate` or `PostUpdateInternal` from `posts/schemas.py`
  (still referenced by `posts/repository.py`).

## Further Notes

- `PostAuthor` is currently defined locally inside `create_post/domain/entities.py`.
  Promoting it to `posts/_shared/entities.py` is a prerequisite for this slice;
  it must be done as part of the implementation without changing `create_post`
  behavior.
- The cache invalidation key `{username}_post_cache` is shared with `get_post`.
  No change to the `get_post` cache decorator is needed — after a PATCH the cache
  entry is invalidated and the next GET repopulates it.
- `erase_post` and `erase_db_post` remain inline in `features/posts/router.py`
  after this slice lands; they are candidates for future slice extraction.
