# PRD — 0055 · users · edit_user_route_to_user_id

> **Status:** 📋 Planned
> **Feature:** users
> **Slice:** edit_user_route_to_user_id
> **Part of:** `{username}` → `{user_id}` breaking-API migration. Depends on 0048 (CurrentUser.id).

## Problem Statement

The backend removed `PATCH /user/{username}` (update) and the username-based read used to
pre-fill the edit form (`GET /user/{username}`). Editing a user now requires the integer
`user_id` on both the load and the save. The edit-user flow has two adapters —
update-user and get-user-for-edit — that both address the user by username, so both break.

## Solution

Migrate both edit-user adapters to the integer `id`. The **update-user** adapter switches
its API call to `PATCH /user/{user_id}` (its port already takes a `User` object, which
carries `id`, so the port signature is unchanged — only the call uses `user.id` instead of
`user.username`). The **get-user-for-edit** adapter switches its API call to
`GET /user/{user_id}`. The corresponding API-client methods (`updateUser`, `getUser`)
take `int userId`.

## User Stories

1. As a user (or admin), I want to open the edit screen pre-filled with the current user data, so that I can change the right fields.
2. As a user, I want to save my edits successfully against the new API, so that the update no longer fails with 422/404.
3. As a developer, I want the get-for-edit adapter to load by `int userId`, matching the new contract.
4. As a developer, I want the update adapter to send `PATCH /user/{user_id}` using the `User.id` already on the domain object, so that no username is reconstructed.
5. As a developer, I want HTTP failures (401/403/404/server/unknown) mapped to domain `Failure`s on both load and save, so that the UI shows the correct state.
6. As a user, I want owner-only edit gating to keep working, now keyed off numeric identity (`isMe(userId)`), so that I can only edit what I'm allowed to.

## Implementation Decisions

- **Modules modified:** the **update-user adapter** (API call `→ PATCH /user/{user_id}`, using `User.id`; port unchanged because it already takes a `User`), the **get-user-for-edit adapter** (param + `GET /user/{user_id}`), and the Users API client `updateUser` and `getUser` methods (`/user/{username}` → `/user/{user_id}`).
- The `UpdateUserRequestDto` body is unchanged.
- Owner-only gating (slice 0038) now relies on numeric `isMe(int userId)` from slice 0048.
- Both adapters keep catch-all `catch (e, st)` + `logger.error`.

## Testing Decisions

- **Modules tested (default four-layer policy):**
  - **Adapter** — for **both** load and update: success + 401/403/404/server + unexpected exception (`logger.error` verified).
  - **Use-case** — load and save delegation + permission/ownership enforcement.
  - **Cubit** — loading → prefilled, submitting → success/error transitions.
  - **Widget** — edit form renders prefilled/loading/error and reflects save outcome via mocked cubit.

## Out of Scope

- Route path/`@PathParam` changes — slice 0062.
- Tier changes (`/user/{user_id}/tier`) — slice 0053.
- The shared `getUser` method is also used by user_details (0049); coordinate the single API-client edit, but the user_details behavior is specified there.

## Further Notes

Source: `handoff_username_to_userid_migration.md` (decisions 3, 4; note `update_user_adapter`
"port already uses User object"). Routes: `PATCH /user/{user_id}`, `GET /user/{user_id}`.
