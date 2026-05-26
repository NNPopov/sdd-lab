# PRD — 0052 delete_post_erase_db_post_route_to_user_id

**Feature:** posts
**Status:** 📋 needs-triage
**Part of:** `{username}` → `{user_id}` API migration (second posts route slice)
**Depends on:** 0048 (`CurrentUser.id`) — hard prerequisite (the delete ownership check
compares against the current user's id); 0051 (`post_details`/`edit_post` already
id-keyed and owns the `created_by_user_id` required-field tightening)
**See:** `docs/adr/0002-posts-route-migration-fine-grained-slices.md`,
`docs/adr/0001-merge-user-details-and-edit-user-route-migration.md`, `CONTEXT.md`

## Problem Statement

The backend moved the single-post **delete** and **erase** routes from
`/{username}/post/{id}` and `/{username}/db_post/{id}` to `/{user_id}/post/{id}` and
`/{user_id}/db_post/{id}`. The Flutter client still puts the author's username string in
those URLs, so deleting one's own post and the superuser "erase from DB" action both fail
(422/404) against the migrated backend.

This is also the slice that finishes the post-detail action row. After slice 0051 the row
is **mixed by design**: the Edit button addresses the post by the author's `user_id`,
while the Delete and Erase buttons still take the author's **handle** (the `username`),
sourced from the loaded post — a value that is nullable and is the last reason the screen
reads `post.username` at all. Until this slice lands, the Delete/Erase buttons are
hidden whenever the loaded post carries no handle (the temporary 0051 bridge), so a user
cannot reliably delete their own post from the detail screen.

Per `CONTEXT.md`, the value that selects *whose* post is being deleted/erased is **author
identity** (`created_by_user_id`) and migrates to `user_id`. The post's `username`
remains a **handle** — a displayed/stored property, never the URL key.

## Solution

Migrate the `delete_post` (DELETE) and `erase_db_post` (privileged DELETE) verticals from
username-as-identity to `user_id`, end to end and without behavior change. The two
affected API methods (`deletePost`, `eraseDbPost`), their ports, use-cases, and cubits
switch their target identifier from `String username` to `int userId`, sourced from the
author identity already available on the detail screen (the route `userId`, equal to the
loaded post's `createdByUserId`).

The delete ownership guard in `DeletePostUseCase` ("is this my post?") flips from
comparing `currentUser.username` against the passed handle to comparing `currentUser.id`
against the passed `userId`. The erase use-case keeps its superuser-only guard unchanged
(it never compared a handle); only its identifier parameter changes.

With both buttons keyed by id, the post-detail action row stops depending on
`post.username`: the 0051 handle bridge and its `handle != null` visibility guards are
removed, so Delete (for the author) and Erase (for a non-author superuser) show
unconditionally on the loaded post, exactly as they did before the route migration began.

The confirmation dialogs, success/forbidden snackbar messages, the `PostDeleted` event
published on success, and the pop-on-success navigation are all unchanged. This is a pure
identifier change (username → author id) with no UI string, request body, or behavior
change.

## User Stories

1. As the author of a post, I want to delete my post from its detail screen against the
   id-based route, so that deleting works on the new backend.
2. As the author, I want the delete confirmation dialog, the success message, and the
   automatic return to the previous screen to behave exactly as before, so that only the
   underlying identifier changed.
3. As the author, I want the Delete button to always be visible on my own post's detail
   screen, so that the 0051 limitation (button hidden when the post carried no handle) is
   gone.
4. As a superuser who is not the author, I want to erase someone else's post from the
   database against the id-based route, so that moderation reach is unchanged after the
   migration.
5. As a superuser, I want the erase confirmation dialog, success message, and navigation
   to behave exactly as before, so that only the underlying identifier changed.
6. As a superuser, I want the Erase button to always be visible on another user's post
   detail screen, so that the 0051 handle-bridge limitation is gone.
7. As a non-author, non-superuser, I want to keep seeing no Delete and no Erase action on
   a post that is not mine, so that visibility rules are unchanged.
8. As the author, I want a delete attempt on a post that is not mine to be refused before
   any network call, so that the ownership guard still protects me by identity rather than
   by handle string.
9. As a user, I want delete and erase failures (forbidden, not found, server, network) to
   surface the same messages as before, so that error feedback is unchanged.
10. As a developer, I want the delete and erase API methods declared with an integer
    `user_id` path parameter, so that generated requests hit the correct routes.
11. As a developer, I want `DeletePostPort`/`DeletePostUseCase`/`DeletePostCubit` and
    `EraseDbPostPort`/`EraseDbPostUseCase`/`EraseDbPostCubit` to carry `int userId`
    instead of `String username`, so that the id contract is enforced at every layer
    boundary.
12. As a developer, I want the `DeletePostUseCase` ownership check expressed as
    `currentUser.id == userId`, so that authorship is decided by identity, not by the
    handle string (mirroring the users-side `delete_user` slice 0049).
13. As a developer, I want the Delete and Erase buttons to take `int userId`, sourced
    from the detail screen's route `userId` (the author id), so that they no longer read
    the loaded post's nullable `username`.
14. As a developer, I want the post-detail action row to stop reading `post.username` and
    to drop the `handle != null` guards, so that the 0051 bridge is fully removed and the
    action row is uniformly id-keyed.
15. As a maintainer, I want combined slice outside-in tests verifying
    `deletePost(<int>, id)` and `eraseDbPost(<int>, id)` are called with the integer id,
    so that the migration is provably correct against a mocked API with no live backend.
16. As a maintainer, I want the existing delete/erase cubit, use-case, adapter, and the
    detail-screen widget tests migrated from username to id, so that the suite stays green
    after the signatures change.

## Implementation Decisions

- **Module: Posts API client (`deletePost`, `eraseDbPost`).** `DELETE /{username}/post/{id}`
  and `DELETE /{username}/db_post/{id}` (each with `String username`) → id-based path with
  an `int userId` path parameter. The four other methods on this `_shared` client
  (`getPost`, `patchPost` — already migrated in 0051; `getUserPosts`, `createPost` —
  migrate in 0053) are **not** touched here. **Requires `build_runner`** (retrofit client).
- **Module: `delete_post` vertical.** `DeletePostPort.call`, `DeletePostUseCase.call`, and
  `DeletePostCubit.confirmAndDelete` switch their target from `String username` to
  `int userId`. The use-case ownership guard flips from `currentUser.username != username`
  to `currentUser.id != userId` (returning the same `Failure.forbidden`). The
  `DeletePostAdapter` calls `deletePost(userId, id)`; its existing failure mapping
  (401/403/404 + network + catch-all `logger.error`) and the `PostDeleted` event are
  preserved.
- **Module: `erase_db_post` vertical.** `EraseDbPostPort.call`,
  `EraseDbPostUseCase.call`, and `EraseDbPostCubit.confirmAndErase` switch their target
  from `String username` to `int userId`. The use-case keeps its **superuser-only** guard
  unchanged (it never compared a handle); only the identifier parameter changes. The
  `EraseDbPostAdapter` calls `eraseDbPost(userId, id)`; its existing failure mapping
  (401/403/404 / ≥500 / network + catch-all `logger.error`) and the `PostDeleted` event
  are preserved.
- **Module: Delete/Erase buttons (presentation).** `DeletePostButton` and
  `EraseDbPostButton` change their `String username` field to `int userId` and forward it
  to the cubit.
- **Module: `post_details` screen (bridge removal, in scope).** The action row passes the
  route `userId` (the author id, already used for the row's `isAuthor` check) to
  `DeletePostButton`/`EraseDbPostButton` instead of the loaded post's handle. The
  `final handle = post.username` read and the two `handle != null` visibility guards are
  removed, so the buttons render whenever the author/superuser visibility condition holds.
  No other part of the screen changes.
- **No routing changes.** Unlike slice 0051, `delete_post` and `erase_db_post` have **no**
  auto_route pages of their own — they are buttons hosted inside `post_details`. No path
  string in `core/routing` changes in this slice.
- **No DTO change.** The `created_by_user_id` required-`int` tightening already landed in
  0051; this slice inherits it and adds nothing to the post DTOs.
- **No UI string / request change.** Tooltips, confirmation dialogs, success/forbidden
  messages, and the (body-less) DELETE requests are all unchanged. The migration is a pure
  identifier change (username → author id).

## Testing Decisions

A good test asserts external behavior — that delete/erase hit the API with the correct
**integer id**, that the delete ownership guard refuses by id before any network call, and
that the action row shows the right buttons per role — not internal wiring. Default
coverage applies to all four layers, per CLAUDE.md.

- **Adapters (unit):** `DeletePostAdapter` success calls `deletePost(<int>, id)`; failure
  mapping (401/403/404 + network) and the catch-all `logger.error` preserved.
  `EraseDbPostAdapter` success calls `eraseDbPost(<int>, id)`; failure mapping
  (401/403/404 + ≥500 server + network) and the catch-all `logger.error` preserved.
- **Use-cases (unit):** `DeletePostUseCase` delegates to the port with the integer id when
  `currentUser.id == userId`, and returns `Failure.forbidden` (no port call) otherwise;
  `EraseDbPostUseCase` delegates with the integer id when superuser and returns
  `Failure.permissionDenied` (no port call) otherwise.
- **Cubits (`bloc_test`):** `DeletePostCubit.confirmAndDelete(<int>, id)` → deleting →
  success (publishes `PostDeleted`) / failure; `cancel` and `requestConfirmation`
  transitions unchanged. `EraseDbPostCubit.confirmAndErase(<int>, id)` likewise.
- **Widgets:** the Delete/Erase button widgets drive their cubit with the integer
  `userId`; the `post_details` screen shows Delete (+ Edit) for the author and Erase for a
  non-author superuser, gated by `currentUser.id == userId`, with no dependence on the
  post's handle.
- **Slice outside-in (acceptance gate):** wire the real `delete_post` and `erase_db_post`
  adapter+use-case+cubit, mock the API client and `AuthCubit`, and `verify`
  `deletePost(<int>, id)` and `eraseDbPost(<int>, id)`. Mocked at the API-client boundary;
  no live backend.
- **Downstream re-green:** existing `delete_post`/`erase_db_post` cubit/use-case/adapter
  tests migrated from username to id; the `post_details` screen test updated for the
  bridge removal (Delete/Erase now shown without a handle present).
- **Prior art:** the users-side `delete_user` slice 0049 (delete route migrated to
  `int userId`, ownership by id); slice 0051 (`post_details`/`edit_post` id migration,
  ownership by id, handle-bridge concept);
  `test/features/posts/erase_db_post/data/erase_db_post_adapter_test` (full failure
  mapping + double-catch + `logger.error`).

## Out of Scope

- `user_posts` and `create_post` route migration (slice 0053). The `getUserPosts` and
  `createPost` API methods stay username-keyed until then.
- `getPost` / `patchPost` and the `post_details`/`edit_post` read/update path — migrated
  in 0051; only the detail screen's delete/erase button wiring changes here.
- The `created_by_user_id` DTO contract (made required in 0051) and any other DTO shape.
- `post_uuid`-based routes (`revisePost`, `moderatePost`, `getModerationLog`) — never
  carried a username and do not migrate.
- The DELETE request semantics, the confirmation dialogs, the success/forbidden messages,
  the `PostDeleted` event, and `AuthSession`.

## Further Notes

- This is the second of three posts route slices (0051 read/edit, **0052 delete/erase**,
  0053 by-author); it removes the temporary mixed-key action row introduced by 0051. See
  ADR-0002 for why the posts surface is split into three fine-grained slices.
- The Flutter posts migration must be merged **with or after** the backend posts route
  migration (which lives on a separate, not-yet-merged branch); merging earlier breaks
  posts against the current `dev`, where these routes are still `{username}`.
- The migration mirrors the users-side `delete_user` slice 0049, which already moved its
  delete route and ownership check to `int userId` — use it as the reference shape.
