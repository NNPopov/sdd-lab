# PRD — 0060 · posts · edit_post_route_to_user_id

> **Status:** 📋 Planned
> **Feature:** posts
> **Slice:** edit_post_route_to_user_id
> **Part of:** `{username}` → `{user_id}` breaking-API migration. Depends on 0048 (CurrentUser.id).

## Problem Statement

The backend removed `PATCH /{username}/post/{id}`. Editing a post now requires
`PATCH /{user_id}/post/{id}`. The edit-post flow still sends a username and breaks.

## Solution

Migrate the edit-post path to the integer `id`. The port, adapter, and API-client
`patchPost` method take `int userId` (the post `id` path param is unchanged) and call
`PATCH /{user_id}/post/{id}`.

## User Stories

1. As a post author, I want to edit my post, so that I can correct or update its content.
2. As a user, I want the edit to save against the new API, so that it no longer fails with 422/404.
3. As a developer, I want the edit-post port to accept `int userId` (plus the post id), matching the new contract.
4. As a developer, I want HTTP failures (401/403/404/422/server/unknown) mapped to domain `Failure`s, so that the form shows the correct errors.
5. As a user, I want owner-only edit gating to keep working, keyed off numeric identity (`isMe(userId)`).

## Implementation Decisions

- **Modules modified:** the edit-post **port** (`String username` → `int userId`), its **adapter** (param + API call), and the Posts API client `patchPost` (`/{username}/post/{id}` → `/{user_id}/post/{id}`).
- The `UpdatePostRequestDto` body is unchanged.
- The uuid-keyed `revisePost` route is unaffected and out of scope.
- Adapter keeps catch-all `catch (e, st)` + `logger.error`.

## Testing Decisions

- **Modules tested (default four-layer policy):**
  - **Adapter** — success + 401/403/404/422/server + unexpected exception (`logger.error` verified).
  - **Use-case** — delegation + permission/ownership enforcement.
  - **Cubit** — loading → prefilled, submitting → success/error transitions.
  - **Widget** — edit form renders prefilled/loading/error and reflects save outcome via mocked cubit.

## Out of Scope

- Route path/`@PathParam` changes — slice 0062.
- Post revision (`PATCH /posts/{post_uuid}/revise`) — uuid-keyed, unaffected.

## Further Notes

Source: `handoff_username_to_userid_migration.md` (decisions 3, 4). Route: `PATCH /{user_id}/post/{id}`.
