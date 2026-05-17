# PRD — 0030: Adapt Paginated Posts Contract

## Problem Statement

The backend has updated the `GET /{username}/posts` endpoint response shape.
The client-side data layer was built against the old contract and will silently
misparse paginated responses — `items` will deserialize as an empty list,
`hasMore` will always be `false`, and the new `username` field on each item
will be discarded. Users see an empty post list and infinite scroll stops
working even when the server returns data.

## Solution

Update the data layer of the `user_posts` slice to match the new backend
contract — keeping all behavior (infinite scroll, pull-to-refresh, load-more
spinner, error retry) identical. No visible UI changes. Introduce a new shared
`PostItemDto` for paginated-list items so that the `username` field returned
by this endpoint is available for future reuse, without touching the existing
`PostDto` used by single-post endpoints.

## User Stories

1. As a visitor, I want to see a user's post list load correctly, so that I
   am not shown an empty list due to a mismatched API contract.
2. As a visitor, I want infinite scroll to reach the last page and stop, so
   that I am not stuck in an infinite loading loop caused by a wrong `hasMore`
   value.
3. As a visitor, I want pull-to-refresh to reload from page 1 correctly, so
   that the refreshed list reflects the current backend state.
4. As a visitor, I want the load-more spinner to disappear when the last page
   is reached, so that I know there are no more posts to load.
5. As a developer, I want `PostItemDto` stored in the shared DTO folder, so
   that future slices (e.g. list_posts) can reuse it without duplication.
6. As a developer, I want the `Post` entity to carry an optional `username`
   field, so that the domain layer does not silently drop data that may be
   needed in future screens.
7. As a developer, I want `PostDto` (used by single-post endpoints) to remain
   unchanged, so that `create_post`, `post_details`, and `edit_post` adapters
   are not affected.
8. As a developer, I want `hasMore` to be a computed getter on `PaginatedPosts`
   (not a stored field), so that the value is always consistent with
   `totalCount`, `page`, and `itemsPerPage` and cannot drift out of sync.
9. As a developer, I want the adapter test suite to cover both `hasMore=true`
   and `hasMore=false` cases with the new formula, so that the pagination
   boundary condition is verified automatically.

## Implementation Decisions

### Contract changes (backend → client)

| Old field | New field | Notes |
|---|---|---|
| `data` (list) | `items` | List field renamed |
| `has_more: bool` | _(removed)_ | Replaced by totals |
| _(absent)_ | `total_count: int` | Total record count |
| _(absent)_ | `items_per_page: int` | Page size from server |
| `page: int` | `page: int` | Unchanged |

Per-item changes:

| Old field | New field | Notes |
|---|---|---|
| _(absent)_ | `username: String` | Author username, new |
| All other fields | unchanged | `id`, `title`, `text`, `media_url`, `created_at`, `created_by_user_id` |

### Modules modified

**`PaginatedPostsDto`** — fields updated to match new contract. All four fields
(`items`, `total_count`, `page`, `items_per_page`) are `required` — a
response missing any of them is semantically invalid and should fail
deserialization loudly. List type changes from `PostDto` to `PostItemDto`.

**`PostItemDto`** _(new, in `_shared/data/dto/`)_ — mirrors all `PostDto`
fields and adds `username: String` (required). Named distinctly from `PostDto`
because it represents the richer shape returned by list endpoints, not the
shape of a single-post endpoint. Stored in the shared DTO folder for reuse
by future list-oriented slices.

**`PaginatedPosts` entity** — removes the stored `hasMore: bool` field.
Adds `totalCount: int` and `itemsPerPage: int`. Exposes
`bool get hasMore => page * itemsPerPage < totalCount` as a computed getter.
Follows the pattern established by `PaginatedUsers` in slice 0029.

**`Post` entity** — gains `String? username` (nullable). Single-post
endpoints do not return `username`, so the field is optional. The cubit and
state are unchanged; `username` is available if any future widget needs it.

**`UserPostsAdapter`** — updated to map `dto.items` (instead of `dto.data`),
construct `PaginatedPosts` with `totalCount`, `page`, `itemsPerPage`, and
map `p.username` onto the `Post`. The double-catch structure, logger calls,
and HTTP failure mapping are unchanged.

### `hasMore` formula

`hasMore = page * itemsPerPage < totalCount`

| Scenario | totalCount | page | itemsPerPage | result |
|---|---|---|---|---|
| Mid-pagination | 100 | 1 | 10 | `10 < 100` → `true` |
| Last page exactly full | 10 | 1 | 10 | `10 < 10` → `false` |
| Last page partial | 12 | 1 | 10 | `10 < 12` → `true` |
| Empty list | 0 | 1 | 10 | `10 < 0` → `false` |

### Unchanged modules

- `PostDto` and its generated files — single-post endpoint shape is unaffected.
- `UserPostsUseCase`, `UserPostsPort` — no signature change.
- `UserPostsCubit`, `UserPostsState` — `hasMore` remains available via the
  entity getter; no cubit logic changes.
- All presentation files — no visible behavior change.
- `PostsApiClient` — endpoint path and query parameters unchanged.
- All other post slices (`list_posts`, `create_post`, `post_details`,
  `edit_post`, `delete_post`, `erase_db_post`).

## Testing Decisions

A good test verifies **external behavior** of a module through its public
interface, not its internal implementation. For the adapter, that means
asserting what `Either` is returned for a given API response — not how the
mapping is done internally. For the entity, a good test asserts the
`hasMore` formula at its boundary values.

### Modules to test

**`UserPostsAdapter`** (unit test):

- Success path, `hasMore = true` — `items: [item]`, `totalCount: 100`,
  `page: 1`, `itemsPerPage: 10` → `Right(PaginatedPosts)` where
  `hasMore == true`.
- Success path, `hasMore = false` (last page) — `totalCount: 10`, `page: 1`,
  `itemsPerPage: 10` → `Right(PaginatedPosts)` where `hasMore == false`.
- `DioException` (network) → `Left(NetworkFailure)`.
- `DioException` with 404 → `Left(NotFoundFailure)`.
- `DioException` with 500 → `Left(ServerFailure)`.
- Unexpected exception → `Left(UnknownFailure)` and `logger.error` called
  with the stack trace.

**`UserPostsCubit`** — the fixture helper `_page(...)` that constructs
`PaginatedPosts` must be updated to accept `totalCount` instead of a
`hasMore` boolean.

Prior art for both test files: `test/features/users/list_users/data/`
and `test/features/users/list_users/application/` (slice 0029).

## Out of Scope

- Any change to the presentation layer or user-visible behavior.
- Adding `username` display to `PostTile` or any other widget.
- Adapting `list_posts` to a new contract (separate task if needed).
- Changing `PostDto` or any single-post endpoint adapter.
- Adding or removing pagination parameters from `UserPostsPort`.

## Further Notes

This slice is structurally identical to `0029_adapt_paginated_users_contract`.
When in doubt about a pattern decision, treat that slice as the authoritative
reference.

The `PostItemDto` introduced here is intentionally placed in
`posts/_shared/data/dto/` so that a future `list_posts` contract adaptation
can import it directly without creating a duplicate definition.
