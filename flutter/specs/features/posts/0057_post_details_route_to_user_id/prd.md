# PRD — 0057 · posts · post_details_route_to_user_id

> **Status:** 📋 Planned
> **Feature:** posts
> **Slice:** post_details_route_to_user_id
> **Part of:** `{username}` → `{user_id}` breaking-API migration. Depends on 0048 (CurrentUser.id).

## Problem Statement

The backend removed `GET /{username}/post/{id}`. Reading a single post now requires
`GET /{user_id}/post/{id}`. The post-details read still sends a username and breaks.

## Solution

Migrate the get-post path to the integer `id`. The port, adapter, and API-client
`getPost` method take `int userId` (the existing post `id` path param is unchanged) and
call `GET /{user_id}/post/{id}`.

## User Stories

1. As a user, I want to open a single post and read its full content, so that I can see details and status.
2. As a user, I want the post to load against the new API, so that I don't see a 404/422 where the post used to appear.
3. As a developer, I want the post-details port to accept `int userId` (plus the post id), matching the new contract.
4. As a developer, I want HTTP failures mapped to domain `Failure`s, so that the UI shows the correct state.

## Implementation Decisions

- **Modules modified:** the post-details **port** (`String username` → `int userId`), its **adapter** (param + API call), and the Posts API client `getPost` (`/{username}/post/{id}` → `/{user_id}/post/{id}`). The post `id` path param stays an `int` and is unchanged.
- Adapter keeps catch-all `catch (e, st)` + `logger.error`.

## Testing Decisions

- **Modules tested (default four-layer policy):**
  - **Adapter** — success + 401/403/404/server + unexpected exception (`logger.error` verified).
  - **Use-case** — delegation + `Either` propagation.
  - **Cubit** — loading → loaded(post)/error transitions.
  - **Widget** — details screen renders loaded/loading/error via mocked cubit.

## Out of Scope

- Route path/`@PathParam` changes — slice 0062.
- Edit/delete/erase of a post — their own slices.

## Further Notes

Source: `handoff_username_to_userid_migration.md` (decisions 3, 4). Route: `GET /{user_id}/post/{id}`.
