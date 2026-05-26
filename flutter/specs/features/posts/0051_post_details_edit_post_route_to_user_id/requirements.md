# 0051 · post_details_edit_post_route_to_user_id — Requirements

## Functional Requirements

| ID | Requirement |
|---|---|
| F1 | The post detail screen is reachable via an integer `user_id`-keyed route (the `/{user_id}/post/{id}` family) and loads the post from the id-based backend read route. |
| F2 | The detail screen displays the same content as before the migration: title, the author-only status chip, optional media image, markdown body, and formatted creation date. |
| F3 | The author of a post can open the edit screen from the detail screen and save changes against the integer `user_id`-keyed update route. |
| F4 | The edit screen preserves all prior behavior: title/media-URL/text validation, markdown preview, the moderation-log panel, the approved-post save lock, and the changes-requested revision-message field and revise flow. |
| F5 | The post update PATCH request body (title, text, media URL) is sent unchanged. |
| F6 | The detail screen's app-bar Edit action is shown only when the current user's id equals the post's author id (the route `user_id`). |
| F7 | The detail screen's body status chip is shown only when the current user's id equals the loaded post's `createdByUserId`. |
| F8 | The Delete and Erase actions remain handle-keyed and are shown only when the loaded post carries a non-null handle; because the single-post read returns no handle, they are not shown on the detail screen in this slice. |
| F9 | Tapping a post in the global feed opens its detail screen keyed by that post's author id (`createdByUserId`). |
| F10 | Tapping a post in an author's-posts list opens its detail screen keyed by that post's author id (`createdByUserId`). |
| F11 | A post whose API response omits `created_by_user_id` fails at deserialization rather than loading with a fallback author id of 0. |
| F12 | Saving an edit is rejected with a forbidden failure when the current user's id does not equal the target post's author id. |

## Non-functional Requirements

| ID | Requirement |
|---|---|
| N1 | `getPost` and `patchPost` declare an integer `@Path('user_id')` path parameter over `/{user_id}/post/{id}`; the other methods on `PostsApiClient` are unchanged. |
| N2 | `created_by_user_id` is a required, non-nullable `int` on both `PostDto` and `PostItemDto`. |
| N3 | The `?? 0` fallback for `createdByUserId` is removed in the `get_post`, `list_posts`, and `user_posts` adapters. |
| N4 | `PostDetailsPort.call`, `GetPostUseCase.call`, and `PostDetailsCubit.load` take `int userId` (plus `int id`) instead of `String username`. |
| N5 | `UpdatedPostData` carries `int userId` instead of `String username`; the `EditPostPort`/`EditPostUseCase`/`EditPostCubit` method signatures are otherwise unchanged. |
| N6 | The edit screen sources the post's identity from the loaded `Post.createdByUserId`; the edit page declares no `userId`/`@PathParam` parameter (it receives the full `Post`). |
| N7 | The four affected route path strings (two per tab) use `:user_id`; the sibling posts paths (`user/:username/posts`, `.../posts/create`, `:username/posts/create`) remain `:username`. |
| N8 | The ownership check that decides authorship is an id comparison (`currentUser.id == createdByUserId`) in both the detail app-bar actions, the detail body, and the `EditPostUseCase` guard — never a handle-string comparison. |
| N9 | Each affected adapter preserves its full failure mapping and a catch-all `on Object catch (e, st)` with `logger.error` (`getPost`: 404 / ≥500 / network; `patchPost`: 401 / 403 / 422 / network / server). |
| N10 | All UI strings are sourced via `slang`; no hardcoded UI strings are introduced. |
| N11 | State classes remain sealed `freezed` classes; the slice imports no other slice of the same feature (only `_shared`), and `domain/` imports only `dartz`/`freezed`/pure Dart. |
| N12 | The PATCH body DTO (`UpdatePostRequestDto`), the `username` handle (display, `@username` labels), the revise/moderation-log flows, and `CurrentUser`/`AuthSession` are unchanged. |
| N13 | No new dependency, route, or localization key is added; `build_runner` regenerates the retrofit client, both DTO `*.g.dart`/`*.freezed.dart`, and `app_router.gr.dart`. |

## Out of scope

- `delete_post` and `erase_db_post` route migration (slice 0052); their buttons stay handle-keyed.
- `user_posts` and `create_post` route migration (slice 0053); `user_posts` stays username-keyed except for its tile passing the author id into `PostDetailsRoute`.
- The `getUserPosts`, `createPost`, `deletePost`, and `eraseDbPost` API methods.
- `post_uuid`-based routes (`revisePost`, `moderatePost`, `getModerationLog`).
- The global feed route (`/posts`) and the pending-posts route.
- Adding a `username` field to `PostDto` (or otherwise populating `Post.username` from `getPost`) to keep Delete/Erase visible.
- The PATCH body, the `username` handle, and `AuthSession`.
