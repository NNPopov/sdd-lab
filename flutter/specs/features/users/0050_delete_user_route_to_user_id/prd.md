# PRD — 0050 · users · delete_user_route_to_user_id

> **Status:** 📋 Planned
> **Feature:** users
> **Slice:** delete_user_route_to_user_id
> **Part of:** `{username}` → `{user_id}` breaking-API migration. Depends on 0048 (CurrentUser.id).

## Problem Statement

The backend removed `DELETE /user/{username}`. Deleting an account now requires
`DELETE /user/{user_id}`. The delete-user flow still sends a username and breaks.

## Solution

Migrate the delete-user path to address the target by integer `id`. The port, adapter,
and API-client `deleteUser` method take `int userId` and call `DELETE /user/{user_id}`.

## User Stories

1. As an administrator, I want to delete a user account, so that I can remove accounts that should no longer exist.
2. As an administrator, I want deletion to succeed against the new API, so that the action no longer fails with 422/404.
3. As a developer, I want the delete-user port to accept `int userId`, so that the call matches the backend contract.
4. As a developer, I want HTTP failures (401/403/404/server/unknown) mapped to domain `Failure`s, so that the UI reports the correct outcome.
5. As a user, I want to be informed when a deletion fails versus succeeds, so that I know the account state.

## Implementation Decisions

- **Modules modified:** delete-user **port** (`String username` → `int userId`), its **adapter** (param + API call), and the Users API client `deleteUser` (`/user/{username}` → `/user/{user_id}`, `@Path('user_id') int userId`).
- Adapter keeps the catch-all `catch (e, st)` + `logger.error`.
- Permission/ownership rules are unchanged; any UI permission gate must remain duplicated in the use-case per the universal rule.

## Testing Decisions

- **Modules tested (default four-layer policy):**
  - **Adapter** — success + 401/403/404/server + unexpected exception (`logger.error` verified).
  - **Use-case** — delegates to port, propagates `Either`, enforces any permission check.
  - **Cubit** — in-progress → success and in-progress → error transitions.
  - **Widget** — confirmation UI reflects success/error via mocked cubit.
- Good test = observable result (deletion outcome, failure mapping), not Dio call shape.

## Out of Scope

- Route path/`@PathParam` changes — slice 0062.
- DB-level erase (`/db_user/...`) — slice 0051.

## Further Notes

Source: `handoff_username_to_userid_migration.md` (decisions 3, 4). Route: `DELETE /user/{user_id}`.
