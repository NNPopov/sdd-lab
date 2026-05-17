# PRD — 0009: List Posts (`GET /{username}/posts`)

## Problem Statement

The `GET /{username}/posts` endpoint is implemented as a fat FastAPI handler that
calls FastCRUD and the users repository directly, with no use-case class, no port,
no command object, and no DI container wiring. This violates the project's
Vertical Slice + Hexagonal architecture and makes the endpoint untestable in
isolation. Business logic (user lookup, pagination) is embedded in the HTTP layer.

## Solution

Extract the endpoint into a proper vertical slice at `features/posts/list_posts/`
following the same structure as `features/users/list_users/`. The handler becomes
a thin router that delegates to a use-case class via a DI-managed port. The data
adapter performs a single SQL JOIN between posts and users and returns a paginated
result that includes the username alongside each post. The existing `@cache`
decorator stays in the presentation layer.

## User Stories

1. As an API consumer, I want to retrieve a paginated list of posts for a given
   username, so that I can display a user's post feed.
2. As an API consumer, I want each post in the list to include the author's
   username and user ID, so that I do not need a separate user lookup to display
   attribution.
3. As an API consumer, I want to control page size via `page` and
   `items_per_page` query parameters, so that I can adapt the response to the
   client's display capacity.
4. As an API consumer, I want the response to return an empty list when a
   username has no posts or does not exist, so that I receive a consistent 200
   response for all valid pagination requests.
5. As an API consumer, I want repeated identical requests to be served from
   cache within a 60-second window, so that the service remains fast under load.
6. As a developer, I want the business logic isolated in a use-case class, so
   that I can unit-test it with a mocked port without standing up a database.
7. As a developer, I want the data adapter to be injected via a port protocol,
   so that I can swap the persistence implementation without touching the
   use-case or router.
8. As a developer, I want the SQL query to use a single JOIN between posts and
   users, so that listing posts requires only one database round-trip.
9. As a developer, I want the slice wired into the DI container, so that
   dependency injection is consistent with all other slices in the project.
10. As a developer, I want the existing `posts/router.py` to become an
    aggregator (like `users/router.py`), so that future post slices can be added
    without restructuring the router file again.

## Implementation Decisions

### Modules to build

- **Domain command** — `ListPostsQuery` with fields `username: str`,
  `page: int`, `items_per_page: int`.
- **Domain entities** — `PostItem` carrying post fields plus `username` and
  `created_by_user_id` from the JOIN; `PostPage` wrapping a list of `PostItem`
  with pagination metadata (`total_count`, `page`, `items_per_page`).
- **Port** — `ListPostsPort`, a `@runtime_checkable` Protocol with a single
  method `list(query: ListPostsQuery) -> PostPage`.
- **Use case** — `ListPostsUseCase`, a class with `__init__(port: ListPostsPort)`
  and `async def __call__(query: ListPostsQuery) -> PostPage`. Delegates
  entirely to the port.
- **Data adapter** — `ListPostsAdapter(ListPostsPort)`. Receives a
  `async_sessionmaker`, performs a single `SELECT … FROM posts JOIN users ON
  posts.created_by_user_id = users.id WHERE users.username = :username AND
  users.is_deleted = false AND posts.is_deleted = false` with a separate
  `COUNT(*)` for total_count, returns `PostPage`. Does not raise
  `NotFoundDomainError` for unknown usernames; returns empty pagination.
- **Presentation schemas** — `PostItemSchema` (from_attributes, mirrors
  `PostItem`) and `ListPostsResponse` (from_attributes, mirrors `PostPage`).
- **Presentation router** — single `GET /{username}/posts` endpoint with
  `@cache(key_prefix="{username}_posts:page_{page}:items_per_page:{items_per_page}", expiration=60)`.
  Builds `ListPostsQuery`, calls use-case, maps result to `ListPostsResponse`.

### Modules to modify

- **`features/posts/router.py`** — converted from flat handler file to
  aggregator. The `read_posts` handler is removed. The `list_posts` router is
  included. The remaining five handlers (`write_post`, `read_post`, `patch_post`,
  `erase_post`, `erase_db_post`) stay in place temporarily until they are
  migrated in future slices.
- **`bootstrap/container.py`** — two new providers added:
  `list_posts_adapter` (Factory, receives `session_factory`) and
  `list_posts_use_case` (Factory, receives `list_posts_adapter`).

### Architectural decisions

- Username is part of `ListPostsQuery` (not resolved to `user_id` before the
  use case). The adapter owns the JOIN and the username → data resolution.
- A non-existent username returns an empty paginated response (HTTP 200), not a
  404. The endpoint is a collection query; absence of data is not an error.
- The `@cache` decorator stays in the presentation layer because its key
  template references HTTP-level parameters and the decorator is designed for
  FastAPI handlers.
- No FastCRUD usage in the new slice. The adapter uses raw SQLAlchemy 2.0 async
  selects, consistent with the `list_users` adapter.

## Testing Decisions

Good tests verify observable behavior through the public interface, not
implementation details. They do not assert which internal methods were called
unless the call itself is the behavior under test.

### Use-case unit test
- Mock `ListPostsPort`. Call `ListPostsUseCase` with a `ListPostsQuery`.
- Assert the use-case returns whatever the mock port returns unchanged.
- Prior art: `tests/features/users/0003_list_users/` use-case unit test.

### Adapter unit test
- Use a real async session against the test Postgres database (no mocks).
- Seed users and posts rows, call `ListPostsAdapter.list()`, assert returned
  `PostPage` fields including `username` from the JOIN.
- Assert empty `PostPage` is returned for a username with no posts.
- Assert empty `PostPage` is returned for a username that does not exist.
- Prior art: `tests/features/users/0003_list_users/` adapter unit test.

### Endpoint integration test
- Use `httpx.AsyncClient` against the running app with test Postgres.
- Assert HTTP 200 and correct paginated JSON shape for a user with posts.
- Assert HTTP 200 with empty `items` for a user with no posts.
- Assert HTTP 200 with empty `items` for a non-existent username.
- Assert cache header behaviour (second identical request served from cache).
- Prior art: `tests/features/users/0003_list_users/` integration test.

### Outside-in test
- Acceptance gate for the slice. Must be RED before implementation, GREEN after.
- Covers the full happy path: seed user + posts, call endpoint, assert paginated
  response with correct `username` field in each item.

## Out of Scope

- Migrating any other post endpoint (`write_post`, `read_post`, `patch_post`,
  `erase_post`, `erase_db_post`) to the vertical slice pattern.
- Adding filtering, sorting, or search to the list endpoint.
- Returning HTTP 404 for non-existent usernames on this endpoint.
- Authentication or authorisation checks on `GET /{username}/posts`.

## Further Notes

- The `@cache` invalidation patterns in `patch_post` and `erase_post` (which
  target `{username}_posts:*`) already match the new cache key prefix used in
  this slice, so cache invalidation will continue to work correctly after the
  refactor without any changes to those handlers.
- Future slices for the remaining post endpoints should follow the same
  structure established here.
