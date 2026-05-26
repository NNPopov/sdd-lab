# PRD — 0053 user_posts_create_post_route_to_user_id

**Feature:** posts
**Status:** 📋 needs-triage
**Part of:** `{username}` → `{user_id}` API migration (third and final posts route slice)
**Depends on:** 0048 (`CurrentUser.id`) — hard prerequisite (the create ownership check and
the author-posts owner gating compare against the current user's id); 0051
(`post_details`/`edit_post` already id-keyed; owns the `created_by_user_id` required-field
tightening that the post tiles rely on); 0052 (`delete_post`/`erase_db_post` already
id-keyed)
**See:** `docs/adr/0002-posts-route-migration-fine-grained-slices.md`,
`docs/adr/0001-merge-user-details-and-edit-user-route-migration.md`, `CONTEXT.md`

## Problem Statement

The backend moved the by-author **list** and **create** routes from `/{username}/posts`
and `/{username}/post` to `/{user_id}/posts` and `/{user_id}/post`. The Flutter client
still puts the author's username string in those URLs, so opening an author's posts list
and publishing a new post both fail (422/404) against the migrated backend.

This is also the slice that finishes the whole posts migration. After slices 0051 and 0052
the single-post surface (read/edit/delete/erase) is fully id-keyed, but the by-author
surface is still username-keyed, which leaves temporary handle bridges in three places
outside this slice: the "my posts" menu item in the app shell, the "Posts" action on the
user-details screen, and the per-user navigation in the users list — each carries a
`// Posts routes are not migrated — keep the handle` comment and routes by `username`. Until
this slice lands, those entry points address the author's posts by handle, inconsistent
with the rest of the now id-keyed posts surface.

Per `CONTEXT.md`, the value that selects *whose* posts are listed and *as whom* a post is
created is **author identity** (`created_by_user_id`) and migrates to `user_id`. The
author's `username` remains a **handle** — a displayed property (the `@username` AppBar
title), never the URL key.

## Solution

Migrate the `user_posts` (list-by-author) and `create_post` (publish) verticals from
username-as-identity to `user_id`, end to end and without behavior change. The two
affected API methods (`getUserPosts`, `createPost`), their ports, use-cases, cubits, route
pages, and the in-app route paths switch their target identifier from `String username` to
`int userId`. The create POST body is unchanged (it never carried identity).

Per the ADR-0002 decision, the `user_posts` route is keyed by `user_id`, and the author's
`username` — needed only to render the `@username` AppBar title — is carried as a
**separate, non-path route argument**, never embedded in the URL. This preserves the title
for all in-app navigation (including an author who has zero posts, which yields no handle
from the loaded list) without putting a handle in the path. The `create_post` screen
displays no handle, so it needs only the `int userId`.

The two ownership/visibility checks flip from handle to identity: the `user_posts` FAB
("show the create button only on my own posts") becomes `currentUser.id == userId`, and the
`CreatePostUseCase` guard ("am I posting as myself?") becomes `currentUser.id !=
data.userId` (the exact `username`-comparison example called out in `CONTEXT.md` as an
identity comparison).

With both verticals id-keyed, the three remaining handle bridges in `core/routing` and the
`users` feature are removed: each `UserPostsRoute` construction now passes the author's
`user_id` (plus the display handle), and each `CreatePostRoute` construction passes the
current user's `user_id`. The list content, pagination, pull-to-refresh, post-deleted
event handling, create form, validation, messages, and navigation are all unchanged. This
is a pure identifier change (username → author id) with no UI string or request-body change.

## User Stories

1. As a user, I want to open an author's posts list via an id-based URL, so that the list
   loads from the new backend route.
2. As a user, I want the author-posts list to show exactly the same content, pagination,
   infinite scroll, pull-to-refresh, and empty/error states as before, so that only the
   underlying identifier changed.
3. As a user, I want the author-posts screen to keep showing the `@username` title, so that
   I still see whose posts I am viewing even though the URL is now keyed by id.
4. As the owner of a posts list, I want to see the create-post button on my own posts
   screen and not on anyone else's, so that the create affordance is gated by identity
   exactly as before.
5. As the owner, I want tapping the create button to open the create screen against the
   id-based route, so that publishing targets the new backend.
6. As an author, I want to publish a new post against the id-based create route, so that
   creating works on the new backend.
7. As an author, I want the create form, its validation, the markdown preview, the
   success-pop, and the failure messages to behave exactly as before, so that only the
   post's path identity changed.
8. As an author, I want my new post's request body (title, text, media URL) sent
   unchanged, so that the create semantics are identical to today.
9. As a user, I want a create attempt as another user to be refused before any network
   call, so that the ownership guard still protects the route by identity rather than by
   handle string.
10. As a user, I want list and create failures (forbidden, not found, validation, server,
    network) to surface the same messages as before, so that error feedback is unchanged.
11. As a user navigating from the global feed FAB, I want the create screen to open keyed
    by my id, so that publishing from the feed hits the new route.
12. As a user opening "My posts" from the app header menu, I want my posts list to open
    keyed by my id, so that the temporary handle bridge is gone.
13. As a user opening a person's posts from the user-details screen, I want that list to
    open keyed by that user's id, so that the temporary handle bridge is gone.
14. As a user opening a person's posts from the users list, I want that list to open keyed
    by that user's id, so that the temporary handle bridge is gone.
15. As a developer, I want the list-by-author and create API methods declared with an
    integer `user_id` path parameter, so that generated requests hit the correct routes.
16. As a developer, I want the `user_posts` page declared with `@PathParam('user_id') int
    userId` plus a non-path `username` display argument, so that auto_route parses the id
    from the URL while the handle travels alongside for the title.
17. As a developer, I want the create page declared with `@PathParam('user_id') int
    userId`, so that auto_route parses the id and no handle is needed by that screen.
18. As a developer, I want `UserPostsPort`/`UserPostsUseCase`/`UserPostsCubit` to carry
    `int userId` instead of `String username`, so that the id contract is enforced at every
    layer boundary.
19. As a developer, I want `NewPostData` to carry `int userId` instead of `username`, and
    `CreatePostPort`/`CreatePostUseCase`/`CreatePostCubit` to keep their `NewPostData`
    signatures unchanged, so that the id contract is enforced via the entity without
    churning the orchestration interfaces.
20. As a developer, I want the `user_posts` FAB visibility and the `CreatePostUseCase`
    guard both expressed as `currentUser.id == userId`, so that ownership is decided by
    identity, not by the handle string.
21. As a developer, I want every `UserPostsRoute` construction to pass the author's
    `user_id` (and the display `username`) and every `CreatePostRoute` construction to pass
    the current user's `user_id`, so that the last posts handle bridges in `core/routing`
    and the `users` feature are removed.
22. As a maintainer, I want combined slice outside-in tests verifying `getUserPosts(<int>,
    …)` and `createPost(<int>, body)` are called with the integer id, so that the migration
    is provably correct against a mocked API with no live backend.
23. As a maintainer, I want the existing user_posts/create_post cubit, use-case, adapter,
    and screen tests, plus the routing/navigation tests that construct `UserPostsRoute`/
    `CreatePostRoute`, migrated from username to id, so that the suite stays green after the
    signatures change.

## Implementation Decisions

- **Module: Posts API client (`getUserPosts`, `createPost`).** `GET /{username}/posts` and
  `POST /{username}/post` (each with `String username`) → id-based paths with an `int
  userId` path parameter. The `createPost` **body is unchanged**. The other methods on this
  `_shared` client (`getPost`/`patchPost` — 0051; `deletePost`/`eraseDbPost` — 0052; the
  `/posts` feed, pending, and `post_uuid` moderation/revise routes) are **not** touched
  here. **Requires `build_runner`** (retrofit client + auto_route).
- **Module: `user_posts` vertical.** `UserPostsPort.call`, `UserPostsUseCase.call`, and
  `UserPostsCubit.load`/`refresh`/`loadMore` switch their target from `String username` to
  `int userId`. The `UserPostsAdapter` calls `getUserPosts(userId, …)`; its existing
  paginated mapping, failure mapping (404 / ≥500 / network), and catch-all `logger.error`
  are preserved. The `PostDeleted` event handling is unchanged.
- **Module: `user_posts` screen + page.** `UserPostsPage` changes
  `@PathParam('username') String username` → `@PathParam('user_id') int userId` and gains a
  non-path `String username` display argument. `UserPostsScreen` loads/refreshes/loadMore by
  `userId`, gates the FAB with `currentUser?.id == userId`, and renders the AppBar title
  from the display `username` (handle, unchanged string). The FAB navigates with
  `CreatePostRoute(userId: userId)`. The post tiles already navigate by author id
  (`PostDetailsRoute(userId: post.createdByUserId, …)`, migrated in 0051) and are unchanged.
- **Module: `create_post` vertical.** `NewPostData.username` → `userId: int`. The
  `CreatePostUseCase` ownership guard flips from `currentUser.username != data.username` to
  `currentUser.id != data.userId` (returning the same `Failure.forbidden`). The
  `CreatePostAdapter` calls `createPost(data.userId, body)`; its existing failure mapping
  (401/403/422 + network/server) and catch-all `logger.error`, and the request body, are
  preserved. `CreatePostPort`, `CreatePostUseCase`, and `CreatePostCubit` take `NewPostData`
  and need **no signature change** — only the entity field changes.
- **Module: `create_post` screen + page.** `CreatePostPage` changes
  `@PathParam('username') String username` → `@PathParam('user_id') int userId`. The screen
  builds `NewPostData(userId: userId, …)`. It displays no handle (the AppBar title is a
  static label), so it carries no display argument. The form, validation, markdown preview,
  and success-pop are unchanged.
- **Routing (`core/routing`, in scope).** Three path strings change `:username` →
  `:user_id`: `user/:username/posts` and `user/:username/posts/create` (Users tab), and
  `:username/posts/create` (Posts tab). The single-post paths are already `:user_id`
  (0051/0052) and are not touched; the feed and `post_uuid` paths are not username-based.
- **Navigation call sites (in scope, surgical, cross-feature).** `UserPostsRoute`
  constructions switch to `userId` plus the display `username`, sourced from the user in
  context: the app header "my posts" menu (`core/routing`, from `currentUser`), the
  user-details "Posts" action (`users` feature, from the loaded `user`), and the users-list
  per-row navigation (`users` feature, from each listed user). Their
  `// Posts routes are not migrated` bridge comments are removed. `CreatePostRoute`
  constructions switch to `userId`: the global feed FAB (`list_posts`, from
  `currentUser.id`) and the `user_posts` FAB (in-slice, from the route `userId`). These are
  route-construction changes only — navigation routes live in `core/routing`, so no feature
  imports another feature.
- **Behavior unchanged.** Same list content, pagination, infinite scroll, pull-to-refresh,
  empty/error states, FAB owner-gating, post-deleted handling, create form, validation,
  POST body, navigation, and messages. The migration is a pure identifier change (username
  → author id).
- **No DTO change.** The `created_by_user_id` required-`int` tightening landed in 0051; this
  slice inherits it and adds nothing to the post DTOs.

## Testing Decisions

A good test asserts external behavior — that list/create hit the API with the correct
**integer id**, that the create ownership guard refuses by id before any network call, that
the FAB shows per identity, and that the by-author list title still renders the handle — not
internal wiring. Default coverage applies to all four layers, per CLAUDE.md.

- **Adapters (unit):** `UserPostsAdapter` success calls `getUserPosts(<int>, …)` and maps
  the paginated items; failure mapping (404 / ≥500 / network) and the catch-all
  `logger.error` preserved. `CreatePostAdapter` success calls `createPost(<int>, body)` with
  the unchanged body; failure mapping (401/403/422 + network/server) and the catch-all
  `logger.error` preserved.
- **Use-cases (unit):** `UserPostsUseCase` delegates to the port with the integer id;
  `CreatePostUseCase` delegates the `NewPostData` (carrying the integer `userId`) when
  `currentUser.id == data.userId`, and returns `Failure.forbidden` (no port call) otherwise.
- **Cubits (`bloc_test`):** `UserPostsCubit.load`/`refresh`/`loadMore(<int>)` →
  loading / loaded / error and the load-more transitions; `PostDeleted` removal unchanged.
  `CreatePostCubit.submit` → loading → success/error.
- **Widgets:** `UserPostsScreen` renders the `@username` title from the display handle,
  shows the create FAB only when `currentUser.id == userId`, navigates tiles by author id,
  and pushes `CreatePostRoute(userId: …)`; `CreatePostScreen` submits a `NewPostData` whose
  `userId` is the route id.
- **Slice outside-in (acceptance gate):** wire the real `user_posts` and `create_post`
  adapter+use-case+cubit, mock the API client and `AuthCubit`, and `verify`
  `getUserPosts(<int>, …)` and `createPost(<int>, body)`. Mocked at the API-client boundary;
  no live backend.
- **Downstream re-green:** existing `user_posts`/`create_post` cubit/use-case/adapter/screen
  tests migrated from username to id; routing/navigation tests that construct
  `UserPostsRoute`/`CreatePostRoute` — notably the `user_details` screen test asserting the
  `UserPostsRoute` argument, the `list_posts` screen test asserting the FAB →
  `CreatePostRoute`, and any users-list / app-shell navigation tests.
- **Prior art:** slices 0051 and 0052 (posts read/edit and delete/erase id migrations,
  ownership by id, slice outside-in with a mocked `AuthCubit`); users slice 0050 (route
  migration, handle carried as a display argument, ownership by id);
  `test/features/posts/erase_db_post/data/erase_db_post_adapter_test` (full failure mapping
  + double-catch + `logger.error`).

## Out of Scope

- `getPost` / `patchPost` and the `post_details`/`edit_post` read/update path — migrated in
  0051.
- `deletePost` / `eraseDbPost` and the `delete_post`/`erase_db_post` verticals — migrated in
  0052.
- The global feed route (`/posts`, `getPosts`) and the pending-posts route — not
  username-based.
- `post_uuid`-based routes (`revisePost`, `moderatePost`, `getModerationLog`) — never
  carried a username and do not migrate.
- The `created_by_user_id` DTO contract (made required in 0051) and any other DTO shape.
- The create POST body (`CreatePostRequestDto`), the `username` **handle** (display,
  `@username` AppBar title), and `AuthSession`.

## Further Notes

- This is the **third and final** posts route slice (0051 read/edit, 0052 delete/erase,
  **0053 by-author**). Landing it completes the Flutter posts `{username}` → `{user_id}`
  migration and removes the last handle bridges for posts navigation in `core/routing` and
  the `users` feature — after this slice no posts route is addressed by handle. See ADR-0002
  for the three-fine-grained-slices decision and the `user_posts` "handle as display-only
  route arg" decision implemented here.
- The Flutter posts migration must be merged **with or after** the backend posts route
  migration (which lives on a separate, not-yet-merged branch); merging earlier breaks posts
  against the current `dev`, where these routes are still `{username}`.
- The migration mirrors the users-side `user_details`/`edit_user` slice 0050, which already
  moved its route to `int userId` and carried the handle as a display value — use it as the
  reference shape for the by-author route and the non-path display argument.
