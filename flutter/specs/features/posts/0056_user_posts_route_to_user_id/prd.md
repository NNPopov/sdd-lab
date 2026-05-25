# PRD — 0056 · posts · user_posts_route_to_user_id

> **Status:** 📋 Planned
> **Feature:** posts
> **Slice:** user_posts_route_to_user_id
> **Part of:** `{username}` → `{user_id}` breaking-API migration. Depends on 0048 (CurrentUser.id).

## Problem Statement

The backend removed `GET /{username}/posts`. Listing a user's posts now requires
`GET /{user_id}/posts`. The user-posts list still requests by username and breaks.

## Solution

Migrate the user-posts list path to the integer `id`. The port, adapter, and API-client
`getUserPosts` method take `int userId` (alongside the existing pagination query params)
and call `GET /{user_id}/posts`.

## User Stories

1. As a user, I want to see all posts authored by a given user, so that I can browse their content.
2. As a user, I want the list to page correctly against the new API, so that pagination still works.
3. As a user, I want the list to load against the new API, so that I don't see a 404/422 where posts used to appear.
4. As a developer, I want the user-posts port to accept `int userId` (plus page/perPage), matching the new contract.
5. As a developer, I want HTTP failures mapped to domain `Failure`s, so that the UI shows the correct state.

## Implementation Decisions

- **Modules modified:** the user-posts **port** (`String username` → `int userId`), its **adapter** (param + API call), and the Posts API client `getUserPosts` (`/{username}/posts` → `/{user_id}/posts`, keeping `page`/`items_per_page` queries).
- Adapter keeps catch-all `catch (e, st)` + `logger.error`.

## Testing Decisions

- **Modules tested (default four-layer policy):**
  - **Adapter** — success (incl. pagination) + 401/403/404/server + unexpected exception (`logger.error` verified).
  - **Use-case** — delegation + `Either` propagation.
  - **Cubit** — loading → loaded(page)/error and load-more transitions.
  - **Widget** — list renders loaded/empty/loading/error via mocked cubit.

## Out of Scope

- Route path/`@PathParam` changes — slice 0062.
- Single-post routes — slices 0057–0061.
- The global feed `GET /posts` (not username-keyed).

## Further Notes

Source: `handoff_username_to_userid_migration.md` (decisions 3, 4). Route: `GET /{user_id}/posts`.
