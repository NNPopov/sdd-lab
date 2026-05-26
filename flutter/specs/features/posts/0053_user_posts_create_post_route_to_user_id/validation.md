# 0053 · user_posts_create_post_route_to_user_id — Validation Checklist

## Manual testing

| # | Step | Expected result |
|---|---|---|
| M1 | Open an author's posts list (e.g. tap a user → Posts) | The list loads from `/{user_id}/posts`; the AppBar shows the `@username` title (F1, F3) |
| M2 | On a list with more than one page, scroll to the bottom | The next page loads and appends (infinite scroll preserved) (F2) |
| M3 | Pull down to refresh the list | The list reloads from page 1 (F2) |
| M4 | Open the posts list of an author who has zero posts | The empty state is shown and the AppBar still shows the `@username` title (F2, F3) |
| M5 | Force a load error (backend down), then tap Retry | The error state with a Retry button appears; Retry reloads the list (F2, F12) |
| M6 | View your own posts list while logged in as that user | The create-post FAB is visible (F4) |
| M7 | View another user's posts list while logged in | The create-post FAB is hidden (F4) |
| M8 | Open a posts list while logged out | The create-post FAB is hidden (F4) |
| M9 | Tap the create FAB on your own posts list | The create screen opens; publishing targets your id (F7) |
| M10 | Tap a post tile in the list | The post detail screen opens keyed by that post's author id (F6) |
| M11 | Delete a post from its detail screen, then return to the list | The deleted post is gone from the list (F5) |
| M12 | Fill the create form with valid title/text/media and publish | The post is created, the screen pops, and the new post appears after refresh (F8, F9, F10) |
| M13 | Submit the create form with a title shorter than 2 / longer than 30 chars | A validation error shows; no network call is made (F10) |
| M14 | Submit the create form with an invalid media URL | A media-URL validation error shows; no network call is made (F10) |
| M15 | Submit the create form with text shorter than 100 chars | A text validation error shows; no network call is made (F10) |
| M16 | Tap Publish and observe while the request is in flight | The button shows a spinner and is disabled until the result (F10) |
| M17 | Trigger a 403 on publish (post as a user you are not) | The forbidden message is shown (F11, F12) |
| M18 | Trigger a 422 on publish | The validation message is shown (F12) |
| M19 | Publish with the network unavailable | The network/generic error message is shown (F12) |
| M20 | Open "My posts" from the app header menu | Your posts list opens keyed by your id (F14) |
| M21 | From a user-details screen, tap the Posts action | That user's posts list opens keyed by that user's id (F15) |
| M22 | From the users list, navigate to a user's posts | That user's posts list opens keyed by that user's id (F16) |
| M23 | Tap the create FAB on the global feed | The create screen opens keyed by your id and publishing works (F13) |
| M24 | Attempt to publish as another user (bypass the ownership guard) | The create use-case refuses with a forbidden failure before any network call (F11) |

## Code review

- [ ] `getUserPosts` and `createPost` declare `@Path('user_id') int` on `/{user_id}/posts` and `/{user_id}/post`; the create body type is unchanged (N1, N9)
- [ ] `UserPostsPage` declares `@PathParam('user_id') int userId` plus a required non-path `String username` used only for the AppBar title (N2, N7)
- [ ] `CreatePostPage` declares `@PathParam('user_id') int userId` and carries no display handle (N3)
- [ ] `UserPostsPort`, `UserPostsUseCase`, and `UserPostsCubit` (`load`/`refresh`/`loadMore`) take `int userId`, not `String username` (N4)
- [ ] `NewPostData` carries `int userId`; `CreatePostPort`/`CreatePostUseCase`/`CreatePostCubit` keep their `NewPostData` method signatures (N5)
- [ ] The `user_posts` FAB-visibility check and the `CreatePostUseCase` guard both compare `currentUser.id == userId` (N6)
- [ ] No `username` appears as a URL path segment anywhere in the migrated routes or route constructions (grep `:username` and `UserPostsRoute`/`CreatePostRoute` call sites) (N7, N13)
- [ ] `UserPostsAdapter` and `CreatePostAdapter` keep the inner `DioException` catch and the outer catch-all `catch (e, st)` with `logger.error` returning `Failure.unknown()` (N8)
- [ ] The adapters' HTTP failure mapping is unchanged (user_posts 404/≥500/network; create_post 401/403/422/network/server) (N9)
- [ ] No hardcoded UI strings — all displayed text comes from `context.t.posts.*` (N10)
- [ ] The `users` feature and `core/routing` reach the posts surface only via the shared route classes; neither imports the `posts` feature (grep imports) (N11)
- [ ] No post DTO changed; `created_by_user_id` remains a required `int` (N12)
- [ ] Exactly three path strings changed `:username` → `:user_id`; single-post/feed/pending/`post_uuid` paths untouched (N13)
- [ ] The three `// Posts routes are not migrated` bridge comments (app shell, user-details, users-list) are removed and now pass `userId` (+ `username` for `UserPostsRoute`) (F14–F16)
- [ ] No new dependency added to `pubspec.yaml` (N15)
- [ ] No new screens, routes, states, or behavior introduced (N16)
- [ ] `dart run build_runner build --delete-conflicting-outputs` — no errors
- [ ] `dart run slang` — no errors
- [ ] `dart analyze` — no warnings
- [ ] All tests green
