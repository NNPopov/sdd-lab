# PRD — 0059 · posts · create_post_route_to_user_id

> **Status:** 📋 Planned
> **Feature:** posts
> **Slice:** create_post_route_to_user_id
> **Part of:** `{username}` → `{user_id}` breaking-API migration. Depends on 0048 (CurrentUser.id).

## Problem Statement

The backend removed `POST /{username}/post`. Creating a post now requires
`POST /{user_id}/post`. The create-post flow carries the author identity as a username on
the `NewPostData` entity and sends it in the path, so it breaks against the new contract.

## Solution

Migrate the create-post path to the integer `id`. `NewPostData.username: String` becomes
`NewPostData.userId: int` (pure rename, no logic change). The create-post adapter reads
`data.userId` and calls `POST /{user_id}/post`; the API-client `createPost` method takes
`int userId`. The author id comes from `CurrentUser.id` (slice 0048) when the current user
creates a post.

## User Stories

1. As a user, I want to create a new post, so that I can publish content.
2. As a user, I want the post to be created against the new API, so that it no longer fails with 422/404.
3. As a developer, I want `NewPostData` to carry `userId: int` instead of `username`, so that the entity matches the new contract.
4. As a developer, I want the create-post adapter to send `POST /{user_id}/post` from `data.userId`, so that no username is reconstructed.
5. As a developer, I want HTTP failures (401/403/422 validation/server/unknown) mapped to domain `Failure`s, so that the form shows the correct errors.
6. As a user, I want the new post to appear after creation, so that I get immediate feedback.

## Implementation Decisions

- **Modules modified:** the `NewPostData` entity (`username: String` → `userId: int`, pure rename), the create-post **adapter** (reads `data.userId`; API call → `POST /{user_id}/post`), and the Posts API client `createPost` (`/{username}/post` → `/{user_id}/post`).
- Whatever populates `NewPostData` now supplies `userId` from `CurrentUser.id` / the target `User.id` rather than a username string.
- The `CreatePostRequestDto` body is unchanged.
- Adapter keeps catch-all `catch (e, st)` + `logger.error`.

## Testing Decisions

- **Modules tested (default four-layer policy):**
  - **Adapter** — success + 401/403/422/server + unexpected exception (`logger.error` verified); assert it reads `userId`.
  - **Use-case** — delegation + `Either` propagation.
  - **Cubit** — submitting → success/error transitions.
  - **Widget** — create form reflects submitting/success/error via mocked cubit.

## Out of Scope

- Route path/`@PathParam` changes for the create route page — slice 0062.
- Editing an existing post — slice 0060.

## Further Notes

Source: `handoff_username_to_userid_migration.md` (decisions 3, 4, 7). Route: `POST /{user_id}/post`.
