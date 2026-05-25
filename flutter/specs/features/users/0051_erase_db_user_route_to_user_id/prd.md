# PRD — 0051 · users · erase_db_user_route_to_user_id

> **Status:** 📋 Planned
> **Feature:** users
> **Slice:** erase_db_user_route_to_user_id
> **Part of:** `{username}` → `{user_id}` breaking-API migration. Depends on 0048 (CurrentUser.id).

## Problem Statement

The backend removed `DELETE /db_user/{username}`. The hard DB-erase of a user now
requires `DELETE /db_user/{user_id}`. The erase flow still sends a username and breaks.

## Solution

Migrate the DB-erase path to the integer `id`. The port, adapter, and API-client
`eraseDbUser` method take `int userId` and call `DELETE /db_user/{user_id}`.

## User Stories

1. As an administrator, I want to permanently erase a user from the database, so that I can satisfy hard-delete/cleanup requirements.
2. As an administrator, I want the erase to work against the new API, so that it no longer fails with 422/404.
3. As a developer, I want the erase-db-user port to accept `int userId`, matching the new contract.
4. As a developer, I want HTTP failures mapped to domain `Failure`s, so that the UI reports the correct outcome.
5. As an administrator, I want a clear success/failure signal, given how destructive this action is.

## Implementation Decisions

- **Modules modified:** erase-db-user **port** (`String username` → `int userId`), its **adapter** (param + API call), and the Users API client `eraseDbUser` (`/db_user/{username}` → `/db_user/{user_id}`).
- Adapter keeps catch-all `catch (e, st)` + `logger.error`.

## Testing Decisions

- **Modules tested (default four-layer policy):**
  - **Adapter** — success + 401/403/404/server + unexpected exception (`logger.error` verified).
  - **Use-case** — delegation + permission enforcement.
  - **Cubit** — in-progress → success/error transitions.
  - **Widget** — destructive-confirmation UI reflects outcome via mocked cubit.

## Out of Scope

- Route path/`@PathParam` changes — slice 0062.
- Soft delete (`/user/...`) — slice 0050.

## Further Notes

Source: `handoff_username_to_userid_migration.md` (decisions 3, 4). Route: `DELETE /db_user/{user_id}`.
