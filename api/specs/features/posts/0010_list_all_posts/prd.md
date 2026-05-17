# PRD — list_all_posts (0010)

## Problem Statement

Consumers of the API currently have no way to retrieve a paginated feed of all
posts across all authors. The only available endpoint filters posts by a specific
author's username, which forces clients to either know the username in advance or
issue one request per user to assemble a global feed. This makes building a
homepage feed, an admin overview, or any cross-author listing unnecessarily
expensive.

## Solution

Expose a new public endpoint `GET /posts` that returns a paginated list of all
non-deleted posts from all non-deleted users, sorted newest-first. The response
shape is identical to the existing per-author listing so that clients can reuse
the same data models. No authentication is required.

## User Stories

1. As an anonymous visitor, I want to retrieve the first page of all posts, so
   that I can see recent content without needing an account.
2. As an anonymous visitor, I want to paginate through all posts using page and
   items-per-page query parameters, so that I can browse older content
   incrementally.
3. As an API client, I want the response to include the author's username for
   each post, so that I can display attribution without making a separate
   user-lookup request.
4. As an API client, I want the response to include total_count alongside the
   items, so that I can render pagination controls (e.g. "page 3 of 17").
5. As an API client, I want posts sorted newest-first by default, so that I
   always see the most recent content at the top of the feed.
6. As an API client, I want soft-deleted posts to be excluded from the results,
   so that removed content never appears in the feed.
7. As an API client, I want posts whose author has been soft-deleted to be
   excluded from the results, so that orphaned posts from deactivated accounts
   never appear.
8. As an API client, I want the endpoint to return HTTP 200 with an empty items
   array when no posts exist, so that I can handle the empty-state without
   special-casing error codes.
9. As an API client, I want invalid pagination parameters (e.g. page=0,
   items_per_page=200) to return HTTP 422, so that I can detect and correct
   bad requests programmatically.
10. As a mobile client with limited bandwidth, I want responses to be cached at
    the server for 60 seconds, so that repeated identical requests are served
    quickly without hitting the database every time.
11. As a developer integrating the API, I want the response schema to be
    identical to the per-author posts endpoint, so that I can share deserialization
    logic across both endpoints.
12. As a frontend developer, I want items_per_page to be capped at 100, so that
    a single request cannot trigger an unbounded database scan.
13. As a backend developer, I want the shared domain entities (PostItem, PostPage)
    to live in a single location consumed by both listing endpoints, so that a
    field change only needs to be made in one place.

## Implementation Decisions

### New slice
A new vertical slice `list_all_posts` is created under the posts feature,
following the same Vertical Slice + Hexagonal pattern as the existing
`list_posts` slice. It has its own query object, port protocol, use-case class,
data adapter, HTTP router, and response schemas.

### Shared domain entities
`PostItem` and `PostPage` domain entities are extracted into a `_shared/`
folder under the posts feature. Both `list_posts` and `list_all_posts` import
from this shared location. The migration of `list_posts` happens in the same
atomic change as the introduction of `list_all_posts` — no intermediate state
where the two slices carry duplicate copies.

### API contract
- **Method:** GET
- **Path:** `/posts`
- **Auth:** None required — open to all callers including unauthenticated requests
- **Query parameters:**
  - `page` — integer, default 1, minimum 1
  - `items_per_page` — integer, default 10, minimum 1, maximum 100
- **Success response:** HTTP 200
  ```
  {
    "items": [
      {
        "id": integer,
        "title": string,
        "text": string,
        "media_url": string | null,
        "created_at": ISO-8601 datetime,
        "created_by_user_id": integer,
        "username": string
      }
    ],
    "total_count": integer,
    "page": integer,
    "items_per_page": integer
  }
  ```
- **Empty result:** HTTP 200 with `items: []` and `total_count: 0`
- **Invalid params:** HTTP 422

### Sorting
Results are ordered by `post.created_at DESC` (newest first). The existing
`list_posts` endpoint has no explicit ordering; this new endpoint is the first
to guarantee it.

### Data access pattern
Two SQL queries per request: one `COUNT(*)` for the total, one paginated
`SELECT` with a JOIN on the users table to resolve the author username.
Soft-delete filters (`is_deleted = false`) are applied to both the post and
user rows. Offset-based pagination using `(page - 1) * items_per_page`.

### Caching
- Cache key: `all_posts:page_{page}:items_per_page:{items_per_page}`
- TTL: 60 seconds
- Write-side invalidation: **not implemented** — up to 60 seconds of stale data
  is acceptable. Existing write handlers (`patch_post`, `erase_post`) are not
  modified.

### Dependency injection
The new use-case and adapter are registered in the DI container following the
same factory-provider pattern as `list_posts`. The feature aggregator router
includes the new slice router.

## Testing Decisions

A good test for this feature:
- Exercises behavior through the HTTP interface (or the port boundary for unit
  tests), not internal implementation details.
- Seeds real data and asserts on the shape and content of the response, not on
  which SQL statements were executed.
- Covers both the happy path and the edge cases listed in user stories 6–9.

### Layers to test

**Use-case unit test** — mock the port, assert the use-case returns whatever
the port returns unchanged. Minimal; verifies the delegation boundary.

**Adapter unit test** — real async session against the test Postgres. Verifies:
pagination offset, soft-delete filtering on posts and users, JOIN populates
username, ORDER BY newest-first, COUNT reflects total not just the current page.

**Endpoint integration test** — `httpx.AsyncClient` against the running app
with test Postgres. Verifies: HTTP 200, correct schema, correct ordering,
pagination metadata, HTTP 422 on bad params.

**Outside-in test** — full-stack acceptance gate. Seeds multiple users and
posts, calls `GET /posts`, asserts paginated response with correct total_count
and newest-first ordering. The slice is not done until this test is green.

### Prior art
`tests/features/posts/0009_list_posts/` is the canonical reference for all four
test layers.

## Out of Scope

- Filtering by any field other than the implicit soft-delete filter (no search,
  no date-range filter, no author filter — use `GET /{username}/posts` for
  per-author results).
- Cursor-based pagination.
- Sorting options other than `created_at DESC`.
- Write-side cache invalidation for the `all_posts` cache key.
- Authentication or role-based access control.
- Adding `ORDER BY` to the existing `list_posts` endpoint (separate concern).

## Further Notes

The `_shared/` extraction in this slice sets the precedent for how shared domain
types are handled across posts slices. If additional posts slices are added in
the future (e.g. `search_posts`, `list_trending_posts`), they should consume
from `features/posts/_shared/` rather than duplicating entity definitions.
