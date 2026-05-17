# PRD — 0011: Create Post (`POST /{username}/post`)

## Problem Statement

The `POST /{username}/post` endpoint is implemented as a fat FastAPI handler in
`features/posts/router.py` that calls FastCRUD repositories directly, performs an
ownership check inline, and builds the internal post object in the HTTP layer.
There is no use-case class, no port, no command object, and no DI container
wiring. This violates the project's Vertical Slice + Hexagonal architecture and
makes the business logic (user lookup, ownership enforcement, post creation)
untestable in isolation.

## Solution

Extract the endpoint into a proper vertical slice at `features/posts/create_post/`
following the same structure as `features/users/create_user/` and
`features/users/delete_user/`. The handler becomes a thin router that converts the
HTTP request into a command and delegates to a use-case class via a DI-managed
port. The use-case owns the user lookup, the ownership check, and the creation
logic. The old `write_post` handler is deleted after the new slice is in place.

## User Stories

1. As an authenticated API consumer, I want to create a post under my username,
   so that my content appears on my profile.
2. As an authenticated API consumer, I want to supply a title, body text, and an
   optional media URL when creating a post, so that I have control over the post
   content.
3. As an authenticated API consumer, I want the created post returned immediately
   in the response, so that I can render it without a separate fetch.
4. As an API consumer, I want to receive HTTP 404 when I attempt to create a post
   under a username that does not exist, so that I get a clear error for invalid
   requests.
5. As an API consumer, I want to receive HTTP 403 when I attempt to create a post
   under a username that is not mine, so that other users' profiles are protected.
6. As a developer, I want the ownership check isolated inside the use-case, so
   that it can be unit-tested without a database or HTTP stack.
7. As a developer, I want the data adapter to be injected via a port protocol,
   so that the persistence implementation can be swapped without touching the
   use-case or router.
8. As a developer, I want the slice wired into the DI container, so that
   dependency injection is consistent with all other slices in the project.
9. As a developer, I want the old `write_post` handler deleted after the new
   slice lands, so that there is exactly one implementation of this behaviour.

## Implementation Decisions

### Modules to build

- **Domain command** — `CreatePostCommand` with fields `target_username: str`,
  `requester_username: str`, `title: str`, `text: str`, `media_url: str | None`.
  A second command `CreatePostInternalCommand` adds `created_by_user_id: int` and
  is built by the use-case after resolving the user.
- **Domain entities** — `PostAuthor` carrying `id: int` and `username: str`,
  returned by the port's user-lookup method. `CreatedPost` carrying all fields
  that map to the HTTP response (`id`, `title`, `text`, `media_url`,
  `created_by_user_id`, `created_at`).
- **Port** — `CreatePostPort`, a `@runtime_checkable` Protocol with two methods:
  `get_user_by_username(username: str) -> PostAuthor | None` and
  `create(command: CreatePostInternalCommand) -> CreatedPost`.
- **Use case** — `CreatePostUseCase`, a class with `__init__(port: CreatePostPort)`
  and `async def __call__(command: CreatePostCommand) -> CreatedPost`. Steps:
  (1) call `port.get_user_by_username(command.target_username)`; raise
  `NotFoundDomainError` if None. (2) Compare `command.requester_username` with
  `author.username`; raise `ForbiddenDomainError` if they differ. (3) Build
  `CreatePostInternalCommand` with `created_by_user_id = author.id`. (4) Call
  `port.create(internal)` and return the result.
- **Data adapter** — `CreatePostAdapter(CreatePostPort)`. Receives an
  `async_sessionmaker`. `get_user_by_username` executes a `SELECT` on the `User`
  table filtered by `username` and `is_deleted = false`, returns `PostAuthor` or
  `None`. `create` inserts a `Post` row, commits, refreshes, and maps the ORM
  object to `CreatedPost`. No FastCRUD usage.
- **Presentation schemas** — `CreatePostRequest` (fields: `title`, `text`,
  `media_url`; `extra="forbid"`) and `CreatePostResponse` (fields: `id`, `title`,
  `text`, `media_url`, `created_by_user_id`, `created_at`; `from_attributes=True`).
  These are slice-local and do not reuse `posts/schemas.py` types.
- **Presentation router** — single `POST /{username}/post` endpoint. Reads
  `username` from the path and `current_user["username"]` from the auth
  dependency. Builds `CreatePostCommand`, calls the use-case, maps the returned
  `CreatedPost` to `CreatePostResponse`. No `Request` parameter (no cache
  decorator on this endpoint). Status code 201.

### Modules to modify

- **`features/posts/router.py`** — include the `create_post` sub-router. Delete
  the `write_post` handler. Remove now-unused imports (`PostCreate`,
  `PostCreateInternal`) from the file. The remaining handlers (`read_post`,
  `patch_post`, `erase_post`, `erase_db_post`) are unchanged.
- **`bootstrap/container.py`** — two new providers: `create_post_adapter`
  (Factory, receives `session_factory`) and `create_post_use_case` (Factory,
  receives `create_post_adapter`).

### Architectural decisions

- Ownership is checked by comparing usernames (not numeric IDs), consistent with
  `delete_user` and `update_user`. The `PostAuthor` entity carries both `id` and
  `username`; the use-case uses `username` for the check and `id` for the
  internal command.
- The ownership check is inlined in the use-case (a single `if` comparison). No
  shared `_shared/policies.py` module is created for the posts feature yet;
  extraction is deferred until a second posts slice needs the same check.
- `PostCreate` and `PostCreateInternal` in `posts/schemas.py` are not removed —
  `PostCreateInternal` is still referenced by `posts/repository.py` as a FastCRUD
  type parameter. Only their imports in `router.py` are removed.
- No `@cache` decorator on this endpoint. Post creation is a write operation;
  caching is not applicable.
- No `Request` parameter in the new router function (not needed without cache).

## Testing Decisions

Good tests verify observable behavior through the public interface, not
implementation details. They do not assert which internal methods were called
unless the call itself is the behavior under test.

### Use-case unit test
- Mock `CreatePostPort`. Call `CreatePostUseCase` with a `CreatePostCommand`.
- Assert the use-case calls `port.get_user_by_username` with the target username.
- Assert `NotFoundDomainError` is raised when the port returns `None`.
- Assert `ForbiddenDomainError` is raised when requester username differs from
  the returned author username.
- Assert the use-case calls `port.create` with the correct `CreatePostInternalCommand`
  (including `created_by_user_id`) on the happy path.
- Assert the returned `CreatedPost` matches what the mock port returns.
- Prior art: `tests/features/users/0007_delete_user/` use-case unit test.

### Adapter unit test
- Use a real async session against the test Postgres database (no mocks).
- `get_user_by_username`: assert `PostAuthor` returned for an existing, active
  user; assert `None` returned for a deleted user; assert `None` returned for an
  unknown username.
- `create`: seed a user, call `CreatePostAdapter.create()`, assert the returned
  `CreatedPost` has all expected fields including the correct `created_by_user_id`.
- Prior art: `tests/features/users/0001_create_user/` adapter unit test.

### Endpoint integration test
- Use `httpx.AsyncClient` against the running app with test Postgres.
- Assert HTTP 201 and correct `CreatePostResponse` JSON shape on the happy path.
- Assert HTTP 404 when the username does not exist.
- Assert HTTP 403 when the authenticated user does not match the path username.
- Assert HTTP 422 for a missing required field (`title` or `text`).
- Prior art: `tests/features/users/0001_create_user/` integration test.

### Outside-in test
- Acceptance gate for the slice. Must be RED before implementation, GREEN after.
- Covers the full happy path: authenticate as a user, POST to their username,
  assert HTTP 201 and that the response body matches the created post fields.

## Out of Scope

- Migrating any other post endpoint (`read_post`, `patch_post`, `erase_post`,
  `erase_db_post`) to the vertical slice pattern.
- Adding media upload handling (URL is accepted as a plain string field).
- Rate limiting on the create-post endpoint.
- Removing `PostCreate` or `PostCreateInternal` from `posts/schemas.py`.

## Further Notes

- The `patch_post` and `erase_post` handlers in `router.py` reference
  `crud_posts` cache invalidation patterns that target `{username}_post_cache`.
  These are unaffected by this slice — no cache is set on creation, so no
  invalidation is needed here.
- This slice sets the pattern for future post-write slices (`read_post`,
  `patch_post`, `erase_post`, `erase_db_post`).
