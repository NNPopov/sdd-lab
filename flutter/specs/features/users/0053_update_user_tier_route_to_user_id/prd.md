# PRD — 0053 · users · update_user_tier_route_to_user_id

> **Status:** 📋 Planned
> **Feature:** users
> **Slice:** update_user_tier_route_to_user_id
> **Part of:** `{username}` → `{user_id}` breaking-API migration. Depends on 0048 (CurrentUser.id).
> **Note:** This slice was missing from the handoff doc's file-change list but is in scope per
> decision 3 ("8 Users API methods") — `patchUserTier` uses `{username}`.

## Problem Statement

The backend removed `PATCH /user/{username}/tier`. Changing a user's tier now requires
`PATCH /user/{user_id}/tier`. The update-user-tier port currently takes
`required String username` and the adapter calls `patchUserTier(username, ...)`, so the
action breaks against the new contract.

## Solution

Migrate the change-user-tier path to the integer `id`. The `UpdateUserTierPort.call`
signature changes from `{required String username, required int tierId}` to
`{required int userId, required int tierId}`; the adapter calls
`PATCH /user/{user_id}/tier`; the API-client `patchUserTier` method takes `int userId`.

## User Stories

1. As an administrator, I want to change a user's tier, so that I can grant or revoke tier-based capabilities.
2. As an administrator, I want the tier update to succeed against the new API, so that it no longer fails with 422/404.
3. As a developer, I want `UpdateUserTierPort.call` to accept `int userId`, so that callers pass the identifier the backend now requires.
4. As a developer, I want HTTP failures (401/403/404 "User or tier not found"/server/unknown) mapped to domain `Failure`s, so that the UI reports the correct outcome.
5. As an administrator, I want a clear success/failure signal after submitting a tier change, so that I know whether it took effect.

## Implementation Decisions

- **Modules modified:** `UpdateUserTierPort` (`String username` → `int userId`), `UpdateUserTierAdapter` (param + `patchUserTier` call), and the Users API client `patchUserTier` method (`/user/{username}/tier` → `/user/{user_id}/tier`).
- The `tierId` body parameter and the `UpdateUserTierRequestDto` are unchanged.
- Adapter keeps its existing nested `DioException`/catch-all structure with `logger.error`.
- The tier-options fetch (`getTiersForSelection`, `fetch_tiers_adapter`) is **not** username-based and is unchanged.

## Testing Decisions

- **Modules tested (default four-layer policy):**
  - **Adapter** — success + 401/403/404/server + unexpected exception (`logger.error` verified). Update the existing `update_user_tier_adapter` tests to pass `userId`.
  - **Use-case** — delegation + `Either` propagation.
  - **Cubit** — submitting → success/error transitions.
  - **Widget** — the tier sheet/button reflects success/error via mocked cubit.

## Out of Scope

- Route path/`@PathParam` changes — slice 0062.
- **Reading** a user's tier (`GET .../tier`) — slice 0052.
- The tier-selection list fetch (not username-keyed).

## Further Notes

Source: `handoff_username_to_userid_migration.md` (decision 3; this slice fills the gap in
the doc's file-change list). Route: `PATCH /user/{user_id}/tier`.
