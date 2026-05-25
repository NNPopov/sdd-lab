# PRD — 0058 · posts · delete_post_route_to_user_id

> **Status:** 📋 Planned
> **Feature:** posts
> **Slice:** delete_post_route_to_user_id
> **Part of:** `{username}` → `{user_id}` breaking-API migration. Depends on 0048 (CurrentUser.id).

## Problem Statement

The backend removed `DELETE /{username}/post/{id}`. Deleting a post now requires
`DELETE /{user_id}/post/{id}`. The delete-post flow still sends a username and breaks.

## Solution

Migrate the delete-post path to the integer `id`. The port, adapter, and API-client
`deletePost` method take `int userId` (the post `id` path param is unchanged) and call
`DELETE /{user_id}/post/{id}`.

## User Stories

1. As a post author (or moderator), I want to delete a post, so that I can remove content that should no longer be visible.
2. As a user, I want the deletion to succeed against the new API, so that it no longer fails with 422/404.
3. As a developer, I want the delete-post port to accept `int userId` (plus the post id), matching the new contract.
4. As a developer, I want HTTP failures mapped to domain `Failure`s, so that the UI reports the correct outcome.

## Implementation Decisions

- **Modules modified:** the delete-post **port** (`String username` → `int userId`), its **adapter** (param + API call), and the Posts API client `deletePost` (`/{username}/post/{id}` → `/{user_id}/post/{id}`).
- Adapter keeps catch-all `catch (e, st)` + `logger.error`.
- Ownership/permission gating is unchanged and remains duplicated in the use-case.

## Testing Decisions

- **Modules tested (default four-layer policy):**
  - **Adapter** — success + 401/403/404/server + unexpected exception (`logger.error` verified).
  - **Use-case** — delegation + permission enforcement.
  - **Cubit** — in-progress → success/error transitions.
  - **Widget** — confirmation UI reflects outcome via mocked cubit.

## Out of Scope

- Route path/`@PathParam` changes — slice 0062.
- DB-level erase (`/{user_id}/db_post/{id}`) — slice 0061.

## Further Notes

Source: `handoff_username_to_userid_migration.md` (decisions 3, 4). Route: `DELETE /{user_id}/post/{id}`.
