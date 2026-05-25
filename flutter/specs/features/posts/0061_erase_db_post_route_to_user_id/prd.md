# PRD — 0061 · posts · erase_db_post_route_to_user_id

> **Status:** 📋 Planned
> **Feature:** posts
> **Slice:** erase_db_post_route_to_user_id
> **Part of:** `{username}` → `{user_id}` breaking-API migration. Depends on 0048 (CurrentUser.id).

## Problem Statement

The backend removed `DELETE /{username}/db_post/{id}`. The hard DB-erase of a post now
requires `DELETE /{user_id}/db_post/{id}`. The erase-db-post flow still sends a username
and breaks.

## Solution

Migrate the DB-erase-post path to the integer `id`. The port, adapter, and API-client
`eraseDbPost` method take `int userId` (the post `id` path param is unchanged) and call
`DELETE /{user_id}/db_post/{id}`.

## User Stories

1. As an administrator, I want to permanently erase a post from the database, so that I can satisfy hard-delete/cleanup requirements.
2. As an administrator, I want the erase to succeed against the new API, so that it no longer fails with 422/404.
3. As a developer, I want the erase-db-post port to accept `int userId` (plus the post id), matching the new contract.
4. As a developer, I want HTTP failures mapped to domain `Failure`s, so that the UI reports the correct outcome.

## Implementation Decisions

- **Modules modified:** the erase-db-post **port** (`String username` → `int userId`), its **adapter** (param + API call), and the Posts API client `eraseDbPost` (`/{username}/db_post/{id}` → `/{user_id}/db_post/{id}`).
- Adapter keeps catch-all `catch (e, st)` + `logger.error`.

## Testing Decisions

- **Modules tested (default four-layer policy):**
  - **Adapter** — success + 401/403/404/server + unexpected exception (`logger.error` verified).
  - **Use-case** — delegation + permission enforcement.
  - **Cubit** — in-progress → success/error transitions.
  - **Widget** — destructive-confirmation UI reflects outcome via mocked cubit.

## Out of Scope

- Route path/`@PathParam` changes — slice 0062.
- Soft delete (`/{user_id}/post/{id}`) — slice 0058.

## Further Notes

Source: `handoff_username_to_userid_migration.md` (decisions 3, 4). Route: `DELETE /{user_id}/db_post/{id}`.
