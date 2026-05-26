# PRD — 0051 post_details_edit_post_route_to_user_id

**Feature:** posts
**Status:** 📋 needs-triage
**Part of:** `{username}` → `{user_id}` API migration (first posts route slice)
**Depends on:** 0048 (`CurrentUser.id`) — hard prerequisite (the author/ownership checks
compare against the current user's id)
**See:** `docs/adr/0002-posts-route-migration-fine-grained-slices.md`,
`docs/adr/0001-merge-user-details-and-edit-user-route-migration.md`, `CONTEXT.md`

## Problem Statement

The backend moved the single-post **read** and **update** routes from
`/{username}/post/{id}` to `/{user_id}/post/{id}`. The Flutter client still puts the
author's username string in those URLs, so opening a post's detail screen and saving an
edit both fail (422/404) against the migrated backend. Viewing and editing share the
post's domain identity (the author), and the post-detail screen is the hub the feed and
the author's-posts list navigate into — so it must start being addressed by the author's
`user_id`.

Per `CONTEXT.md`, the value that selects *which* post to read/update is **author
identity** (`created_by_user_id`) and migrates to `user_id`. The post's `username`
remains a **handle** — a displayed/stored property, never the URL key.

## Solution

Migrate the `post_details` (read) and `edit_post` (update) verticals from
username-as-identity to `user_id`, end to end and without behavior change. The two
affected API methods (`getPost`, `patchPost`), their ports, use-cases, cubits, route
pages, and the in-app route paths switch their target identifier from `String username`
to `int userId`, sourced from the post's `createdByUserId`. The PATCH request body is
unchanged (it never carried identity). The two ownership ("is this the author?") checks
in the detail screen become id comparisons.

This slice also owns a shared contract fix: `created_by_user_id` is tightened from a
nullable DTO field with a `?? 0` fallback to a **required** `int`, because the field
becomes load-bearing for routing (the feed and the author's-posts list start navigating
to the detail screen by this id, and a missing value must fail loudly rather than route
to user 0).

Because deleting a post (`delete_post`, `erase_db_post`) is a separate later slice, the
detail screen's action row is **mixed by design** after this slice: the Edit button
addresses the post by `id`, while the Delete/Erase buttons still take the handle
(sourced from the loaded post). This is the accepted intermediate state described in
ADR-0002 (precedent: users slice 0049).

## User Stories

1. As a user, I want to open a post's detail screen via an id-based URL, so that the
   post loads from the new backend route.
2. As a user, I want the detail screen to show exactly the same information as before
   (title, status chip for the author, media, body, date), so that only the underlying
   identifier changed.
3. As the author of a post, I want to open the edit screen and save my changes against
   the id-based update route, so that editing works on the new backend.
4. As the author, I want the edit form, validation, the moderation-log panel, the
   approved-post lock, and the changes-requested revision field to behave exactly as
   before, so that only the post's path identity changed.
5. As a user, I want the post's PATCH body (title, text, media URL) to be sent
   unchanged, so that the update semantics are identical to today.
6. As the author, I want the detail screen to recognise me as the author by id, so that
   I see the Edit (and Delete) actions only on my own posts.
7. As a superuser who is not the author, I want to still see the privileged erase action
   on someone else's post, so that moderation reach is unchanged after the migration.
8. As a user navigating from the global feed, I want tapping a post to open its detail
   screen by the author's id, so that the link targets the new route.
9. As a user navigating from an author's posts list, I want tapping a post to open its
   detail screen by the author's id, so that the link works even though the author's-
   posts route itself is migrated later.
10. As a developer, I want the read and update API methods declared with an integer
    `user_id` path parameter, so that generated requests hit the correct routes.
11. As a developer, I want the detail and edit page params declared as `int userId` via
    `@PathParam('user_id')`, so that auto_route parses the id from the URL.
12. As a developer, I want the `getPost` port/use-case/cubit and the `UpdatedPostData`
    entity to carry `int userId` instead of `username`, so that the id contract is
    enforced at every layer boundary.
13. As a developer, I want the edit screen to source the post's identity from the loaded
    `Post` (`createdByUserId`), so that the update targets the correct user without
    relying on a username in the URL.
14. As a developer, I want `created_by_user_id` to be a required `int` in the post DTOs
    with the `?? 0` fallbacks removed, so that a missing value fails at deserialization
    instead of silently routing to user 0.
15. As a developer, I want the two author checks in the detail screen (the app-bar
    actions check against the route param, and the body check against the loaded post)
    both expressed as `currentUser.id == createdByUserId`, so that authorship is decided
    by identity, not by the handle string.
16. As a developer, I want the detail screen to keep passing the handle to the not-yet-
    migrated Delete/Erase buttons (sourced from the loaded post), so that those buttons
    keep working until slice 0052 migrates them.
17. As a maintainer, I want a combined slice outside-in test verifying `getPost(<int>,
    id)` and `patchPost(<int>, id, body)` are called with the integer id, so that the
    migration is provably correct against a mocked API with no live backend.
18. As a maintainer, I want every existing post DTO construction that omits
    `created_by_user_id` updated to supply it, so that the suite compiles and stays green
    after the field becomes required.

## Implementation Decisions

- **Module: Posts API client (`getPost`, `patchPost`).** `GET /{username}/post/{id}` and
  `PATCH /{username}/post/{id}` (each with `String username`) → id-based path with an
  `int userId` path parameter. The `patchPost` **body is unchanged**. The four other
  username-keyed methods on this `_shared` client (`getUserPosts`, `createPost`,
  `deletePost`, `eraseDbPost`) are **not** touched here. **Requires `build_runner`**
  (retrofit client + auto_route).
- **Module: post DTOs (`_shared`).** `created_by_user_id` becomes a **required `int`** in
  `PostDto` and `PostItemDto`. The `?? 0` fallbacks are removed in the three adapters that
  map it (`get_post`, plus `list_posts` and `user_posts`, which are otherwise unchanged
  here — a one-line dead-code cleanup forced by the now-non-null field). No JSON shape
  change beyond nullability. **Requires `build_runner`** (freezed/json_serializable).
- **Module: `post_details` vertical.** `PostDetailsPort.call`, `GetPostUseCase.call`, and
  `PostDetailsCubit.load` switch their target from `String username` to `int userId`. The
  `GetPostAdapter` calls `getPost(userId, id)` and maps `createdByUserId` directly (no
  `?? 0`); its existing failure mapping (404 / ≥500 / network + catch-all `logger.error`)
  is preserved.
- **Module: `post_details` screen + page.** `PostDetailsPage` changes
  `@PathParam('username') String username` → `@PathParam('user_id') int userId`. The
  screen loads by `userId`. The **two** author checks both migrate to
  `currentUser?.id == <author id>` — the app-bar actions row against the route `userId`,
  and the body against `post.createdByUserId` (dropping the prior `post.username != null`
  guard). The Edit button navigates with `EditPostRoute(post: …, userId:
  post.createdByUserId)`. The Delete/Erase buttons stay handle-keyed and are passed the
  loaded `post`'s handle (temporary bridge → 0052).
- **Module: `edit_post` vertical.** `UpdatedPostData.username` → `userId: int`. The
  `EditPostAdapter` calls `patchPost(data.userId, data.id, body)`; its existing failure
  mapping (401/403/422 + network/server + catch-all `logger.error`) and the body are
  preserved. `EditPostPort`, `EditPostUseCase`, and `EditPostCubit` take `UpdatedPostData`
  and need **no signature change** — only the entity field changes.
- **Module: `edit_post` screen + page.** `EditPostPage` changes
  `@PathParam('username') String username` → `@PathParam('user_id') int userId` (it still
  receives the full `Post`). The screen builds `UpdatedPostData(userId:
  post.createdByUserId, …)`. The moderation-log panel, revision-message field, approved-
  post lock, and `PostRevisedEvent` publication are unchanged.
- **Routing (`core/routing`, in scope).** Four path strings change `:username` →
  `:user_id`: `user/:username/posts/:id` and `user/:username/posts/:id/edit` (Users tab),
  and `:username/posts/:id` and `:username/posts/:id/edit` (Posts tab). The sibling
  `posts/create` and `user/:username/posts` paths are **not** touched (later slices).
- **Navigation call sites (in scope, surgical).** `PostDetailsRoute` constructions switch
  to `userId`: the global feed tile (`list_posts` screen) sources `posts[index]
  .createdByUserId`; the author's-posts tile (`user_posts` screen) likewise sources the
  loaded post's `createdByUserId` — a temporary bridge while `user_posts` itself stays
  username-keyed until slice 0053. The `EditPostRoute` construction in the detail screen
  switches to `userId`.
- **Behavior unchanged.** Same detail content, owner-only edit/delete visibility, edit
  form, PATCH semantics, navigation, and messages. The migration is a pure identifier
  change (username → author id) plus the DTO contract tightening.

## Testing Decisions

A good test asserts external behavior — that read/update hit the API with the correct
**integer id**, that authorship is decided by id, and that DTO mapping carries the
server's `created_by_user_id` — not internal wiring. Default coverage applies to all four
layers, per CLAUDE.md.

- **Adapters (unit):** `GetPostAdapter` success calls `getPost(<int>, id)` and maps a
  required `createdByUserId`; failure mapping (404 / ≥500 / network) and the catch-all
  `logger.error` preserved. `EditPostAdapter` success calls `patchPost(<int>, id, body)`
  with the unchanged body; failure mapping (401/403/422 + network/server) and the catch-
  all `logger.error` preserved.
- **Use-cases (unit):** `GetPostUseCase` delegates to the port with the integer id;
  `EditPostUseCase` delegates the `UpdatedPostData` carrying the integer `userId`.
- **Cubits (`bloc_test`):** `PostDetailsCubit.load(<int>, id)` → loading → loaded/error;
  `EditPostCubit.submit` → loading → success/error.
- **Widgets:** the detail screen renders by id and shows Edit/Delete for the author and
  Erase for a non-author superuser, gated by `currentUser.id == createdByUserId`; the
  edit screen submits an `UpdatedPostData` whose `userId` is the post's author id.
- **DTO mapping (unit):** `PostDto`/`PostItemDto` deserialize a required
  `created_by_user_id`; the adapters surface it without a `?? 0` default.
- **Slice outside-in (acceptance gate):** wire the real `get_post` and `edit_post`
  adapter+use-case+cubit, mock the API client and `AuthCubit`, and `verify` `getPost(<int>,
  id)` and `patchPost(<int>, id, body)`. Mocked at the API-client boundary; no live
  backend.
- **Downstream re-green:** existing `post_details` and `edit_post` cubit/adapter/screen
  tests migrated from username to id; routing/navigation tests that construct
  `PostDetailsRoute`/`EditPostRoute` (and the `list_posts`/`user_posts` screen tests whose
  tiles build them); and every `PostDto`/`PostItemDto` construction across the suite
  updated to supply `created_by_user_id` now that it is required.
- **Prior art:** `test/features/tiers/0047_delete_tier_id_contract/` (id-contract outside-
  in with a mocked `AuthCubit`); the users slice 0050 tests (route migration, ownership by
  id, handle bridges); `test/features/posts/erase_db_post/data/erase_db_post_adapter_test`
  (full failure mapping + double-catch + `logger.error`); slice 0048 (required-field
  fallout re-green).

## Out of Scope

- `delete_post` and `erase_db_post` (slice 0052) — their buttons stay handle-keyed; the
  detail screen's mixed-key action row is the accepted intermediate state.
- `user_posts` and `create_post` route migration (slice 0053). `user_posts` stays
  username-keyed; the only change here is its tile passing the author id into the migrated
  `PostDetailsRoute`.
- The `getUserPosts`, `createPost`, `deletePost`, `eraseDbPost` API methods.
- `post_uuid`-based routes used by the edit screen and elsewhere (`revisePost`,
  `moderatePost`, `getModerationLog`) — these never carried a username and do not migrate.
- The global feed route (`/posts`) and the pending-posts route — not username-based.
- The PATCH body (`UpdatePostRequestDto`), the `username` **handle** (display, `@username`
  labels), and `AuthSession`.

## Further Notes

- This is the first posts route slice and owns the `created_by_user_id` contract
  tightening because `post_details` is the navigation hub other surfaces start routing
  into by id. Subsequent posts slices inherit the required field.
- The Flutter posts migration must be merged **with or after** the backend posts route
  migration (which lives on a separate, not-yet-merged branch); merging earlier breaks
  posts against the current `dev`, where these routes are still `{username}`.
- See ADR-0002 for why the posts surface is split into three fine-grained slices
  (0051 read/edit, 0052 delete/erase, 0053 by-author) rather than one combined change,
  and for the `user_posts` "handle as display-only arg" decision used by slice 0053.
