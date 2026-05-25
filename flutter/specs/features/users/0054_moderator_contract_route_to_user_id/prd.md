# PRD — 0054 · users · moderator_contract_route_to_user_id

> **Status:** 📋 Planned
> **Feature:** users
> **Slice:** moderator_contract_route_to_user_id
> **Part of:** `{username}` → `{user_id}` breaking-API migration. Depends on 0048 (CurrentUser.id).

## Problem Statement

The backend removed the username-based moderator routes. Granting and revoking the
moderator role now require `PATCH /user/{user_id}/assign-moderator` and
`PATCH /user/{user_id}/revoke-moderator`. The moderator-management port exposes two
methods that both take a username, so both break against the new contract.

## Solution

Migrate both moderator operations to the integer `id`. The moderator-management **port**
changes both method signatures from `String username` to `int userId`; the **adapter**
updates both API calls; the API-client `assignModerator` and `revokeModerator` methods
take `int userId`.

## User Stories

1. As a superuser, I want to grant moderator rights to a user, so that they can help moderate content.
2. As a superuser, I want to revoke moderator rights from a user, so that I can remove that capability.
3. As a superuser, I want both actions to succeed against the new API, so that they no longer fail with 422/404.
4. As a developer, I want both port methods to accept `int userId`, so that calls match the backend contract.
5. As a developer, I want HTTP failures mapped to domain `Failure`s for both operations, so that the UI reports the correct outcome.
6. As a superuser, I want the moderator badge/state to reflect the new role after the action succeeds.

## Implementation Decisions

- **Modules modified:** the moderator-management **port** (both methods `String username` → `int userId`), its **adapter** (both API calls), and the Users API client methods `assignModerator` and `revokeModerator` (`/user/{username}/...` → `/user/{user_id}/...`).
- Both methods migrate together because they share one port and one adapter (the moderator contract).
- Adapter keeps catch-all `catch (e, st)` + `logger.error` on both calls.
- Permission gating (superuser-only) is unchanged and remains duplicated in the use-case.

## Testing Decisions

- **Modules tested (default four-layer policy):**
  - **Adapter** — for **each** of assign and revoke: success + 401/403/404/server + unexpected exception (`logger.error` verified).
  - **Use-case(s)** — delegation + permission enforcement for both operations.
  - **Cubit** — submitting → success/error transitions for assign and revoke.
  - **Widget** — moderator toggle/buttons reflect both outcomes via mocked cubit.

## Out of Scope

- Route path/`@PathParam` changes — slice 0062.
- Post moderation routes (`/posts/{post_uuid}/moderate`, etc.) — those are uuid-keyed, not username-keyed, and are unaffected.

## Further Notes

Source: `handoff_username_to_userid_migration.md` (decisions 3, 4). Routes:
`PATCH /user/{user_id}/assign-moderator`, `PATCH /user/{user_id}/revoke-moderator`.
