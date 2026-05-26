# 0051 · post_details_edit_post_route_to_user_id — Validation Checklist

## Manual testing

| # | Step | Expected result |
|---|---|---|
| M1 | From the global feed, tap a post tile | Detail screen opens (id-based route) showing the post's title, markdown body, media image (if any), and formatted date. |
| M2 | Open a post detail while logged in as its author | The post-status chip is shown above the title. |
| M3 | Open a post detail while logged in as a different (non-author) user | No status chip; no Edit/Delete/Erase actions in the app bar. |
| M4 | Open a post detail while not logged in | Content renders; no Edit/Delete/Erase actions in the app bar. |
| M5 | As the author, tap the Edit action on the detail screen | Edit screen opens with title, media URL, and text pre-filled from the post. |
| M6 | As the author, change the title/text and tap Save | PATCH succeeds against the id-based route; the screen pops back to the detail, which shows the updated content. |
| M7 | As the author, clear the title (or enter <2 chars) and tap Save | Title validation error is shown; no request is sent. |
| M8 | As the author, enter a title longer than 30 chars and tap Save | Title-too-long validation error is shown; no request is sent. |
| M9 | As the author, enter an invalid media URL and tap Save | Media-URL validation error is shown; no request is sent. |
| M10 | As the author of an **approved** post, open Edit | The Save button is disabled and the approved hint is shown. |
| M11 | As the author of a **changes-requested** post, open Edit and Save with an empty revision message | Revision-message-required validation error is shown; no request is sent. |
| M12 | As the author of a **changes-requested** post, Save with a valid revision message | The revise flow succeeds and the screen pops back to the detail. |
| M13 | On a wide screen open Edit; on a narrow screen open Edit and switch to the Log tab | The moderation-log panel loads (beside the form on wide; under the Log tab on narrow). |
| M14 | Open a post id that does not exist (404 on read) | The detail screen shows the load-error message with a Retry button; Retry re-requests the post. |
| M15 | Force a network failure on the detail read | The detail screen shows the load-error message with a working Retry button. |
| M16 | From an author's-posts list, tap a post tile | Detail screen opens keyed by **that post's** author id (not the list owner's handle). |
| M17 | While saving an edit (in flight) | The Save button shows a spinner and is disabled until the result returns. |
| M18 | As a non-author, attempt to submit an edit for another user's post (e.g. via a stale form) | The save is rejected with a forbidden failure message; no successful update. |
| M19 | As the author or a non-author superuser, view a post detail | Delete and Erase actions are **not** shown on the detail screen in this slice (handle unavailable from the single-post read; deferred to 0052). |
| M20 | Browse the feed and author's-posts lists and open several posts | Every tile navigates to the correct author; no post routes to user id 0. |

## Code review

- [ ] `getPost` and `patchPost` use `@Path('user_id') int userId` over `/{user_id}/post/{id}`; the other six `PostsApiClient` methods are unchanged. (N1)
- [ ] `created_by_user_id` is a required, non-nullable `int` on both `PostDto` and `PostItemDto`. (N2)
- [ ] No `?? 0` fallback for `createdByUserId` remains in `get_post_adapter`, `list_posts_adapter`, or `user_posts_adapter` (grep). (N3)
- [ ] `PostDetailsPort.call`, `GetPostUseCase.call`, and `PostDetailsCubit.load` take `int userId` (plus `int id`). (N4)
- [ ] `UpdatedPostData.userId` is `int`; `EditPostPort`/`EditPostUseCase`/`EditPostCubit` method signatures are otherwise unchanged. (N5)
- [ ] `EditPostScreen` builds `UpdatedPostData(userId: post.createdByUserId, …)`; `EditPostPage` declares no `userId`/`@PathParam` parameter. (N6)
- [ ] The four affected route path strings use `:user_id`; sibling posts paths (`user/:username/posts`, `.../posts/create`, `:username/posts/create`) still use `:username` (grep `app_router.dart`). (N7)
- [ ] Authorship is decided by id comparison (`currentUser.id == createdByUserId`) in the detail app-bar actions, the detail body, and the `EditPostUseCase` guard — no `username ==` ownership comparison remains. (N8)
- [ ] `get_post_adapter` and `edit_post_adapter` keep both the inner `DioException` catch and the outer `on Object catch (e, st)` with `logger.error`, with failure mapping preserved (getPost 404/≥500/network; patchPost 401/403/422/network/server). (N9)
- [ ] No hardcoded UI strings introduced — all via `context.t.posts.*`. (N10)
- [ ] State classes remain sealed `freezed`; the slice imports no other slice of the same feature (only `_shared`); `domain/` imports only `dartz`/`freezed`/pure Dart. (N11)
- [ ] `UpdatePostRequestDto` body, the `username` handle / `@username` labels, the revise/moderation-log flows, and `CurrentUser`/`AuthSession` are unchanged. (N12)
- [ ] Delete/Erase are wired to a null-guarded loaded `post.username` (hidden this slice); `PostDto` was **not** given a `username` field. (accepted intermediate state)
- [ ] No new dependency, route, or localization key added. (N13)
- [ ] `dart run build_runner build --delete-conflicting-outputs` — no errors
- [ ] `dart run slang` — no errors
- [ ] `dart analyze` — no warnings
- [ ] All tests green
