# PRD — 0052 · users · get_user_tier_route_to_user_id

> **Status:** 📋 Planned
> **Feature:** users
> **Slice:** get_user_tier_route_to_user_id
> **Part of:** `{username}` → `{user_id}` breaking-API migration. Depends on 0048 (CurrentUser.id).

## Problem Statement

The backend removed `GET /user/{username}/tier`. Reading a user's tier now requires
`GET /user/{user_id}/tier`. The tier-read path still sends a username and breaks.

## Solution

Migrate the read-user-tier path to the integer `id`. The port, adapter, and API-client
`getUserTier` method take `int userId` and call `GET /user/{user_id}/tier`.

## User Stories

1. As an administrator, I want to see a user's current tier, so that I can decide whether to change it.
2. As a user viewing a profile, I want the tier to load against the new API, so that I don't see an error where the tier used to appear.
3. As a developer, I want the get-user-tier port to accept `int userId`, matching the new contract.
4. As a developer, I want HTTP failures mapped to domain `Failure`s, so that the UI shows the correct state.

## Implementation Decisions

- **Modules modified:** get-user-tier **port** (`String username` → `int userId`), its **adapter** (param + API call), and the Users API client `getUserTier` (`/user/{username}/tier` → `/user/{user_id}/tier`).
- Adapter keeps catch-all `catch (e, st)` + `logger.error`.

## Testing Decisions

- **Modules tested (default four-layer policy):**
  - **Adapter** — success + 401/403/404/server + unexpected exception (`logger.error` verified).
  - **Use-case** — delegation + `Either` propagation.
  - **Cubit** — loading → loaded(tier)/error transitions.
  - **Widget** — tier display reflects loaded/loading/error via mocked cubit.

## Out of Scope

- Route path/`@PathParam` changes — slice 0062.
- **Changing** a user's tier (`PATCH .../tier`) — slice 0053 (update_user_tier).

## Further Notes

Source: `handoff_username_to_userid_migration.md` (decisions 3, 4). Route: `GET /user/{user_id}/tier`.
