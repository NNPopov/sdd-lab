# 0052 · delete_post_erase_db_post_route_to_user_id — Validation Checklist

## Manual testing

| # | Step | Expected result |
|---|---|---|
| M1 | As the author, open your own post's detail screen | Delete button and Edit button are both visible (no handle dependency); Erase is absent. |
| M2 | As the author, tap Delete and confirm in the dialog | Request hits `DELETE /{user_id}/post/{id}` with your integer id; success snackbar shows; screen pops to the previous one. |
| M3 | As the author, tap Delete and cancel in the dialog | No request is made; the screen stays; the button returns to its idle state. |
| M4 | As the author, observe the Delete button while the request is in flight | Button shows a spinner and is disabled until the result returns. |
| M5 | As a superuser who is NOT the author, open someone else's post detail screen | Erase button is visible (no handle dependency); Delete and Edit are absent. |
| M6 | As a superuser, tap Erase and confirm in the dialog | Request hits `DELETE /{user_id}/db_post/{id}` with the author's integer id; success snackbar shows; screen pops. |
| M7 | As a superuser, tap Erase and cancel in the dialog | No request is made; the screen stays. |
| M8 | As a non-author, non-superuser, open someone else's post detail screen | Neither Delete nor Erase nor Edit is shown. |
| M9 | Trigger a delete that the server rejects with 403 | Forbidden error message is shown via snackbar; the screen does not pop. |
| M10 | Trigger a delete/erase against a post the server returns 404 for | The not-found-mapped error message is shown; the screen does not pop. |
| M11 | Trigger a delete/erase with the network unavailable | The network/generic error message is shown; the screen does not pop. |
| M12 | Attempt to delete a post whose author id differs from the current user's id (ownership bypass) | The use-case refuses with a forbidden failure before any network call is made. |
| M13 | Attempt to erase as a non-superuser (permission bypass) | The use-case refuses with a permission-denied failure before any network call is made. |
| M14 | After a successful delete or erase, observe the list/feed that subscribes to post events | The deleted post is reflected as removed (the `PostDeleted` event still fires with the post id). |

## Code review

- [ ] `deletePost`/`eraseDbPost` in `posts_api_client.dart` use `@Path('user_id') int userId` on `/{user_id}/post/{id}` and `/{user_id}/db_post/{id}`; all other methods unchanged.
- [ ] `DeletePostPort` / `DeletePostUseCase` / `DeletePostCubit.confirmAndDelete` take `int userId`, not `String username`.
- [ ] `EraseDbPostPort` / `EraseDbPostUseCase` / `EraseDbPostCubit.confirmAndErase` take `int userId`, not `String username`.
- [ ] Delete guard reads `currentUser == null || currentUser.id != userId` and returns the existing `Failure.forbidden(message: "Cannot delete another user's post")` (not `permissionDenied`).
- [ ] Erase superuser guard is unchanged and returns `Failure.permissionDenied()` for a non-superuser.
- [ ] `DeletePostButton` / `EraseDbPostButton` (and their `_Inner` widgets) expose `int userId` and forward it to the cubit.
- [ ] `post_details_screen.dart` action row passes the route `userId` to both buttons; the `final handle = postState.post.username` read and the two `handle != null` guards are gone.
- [ ] No change to `post_details` beyond the action row; the read path is untouched.
- [ ] Both DELETE requests remain body-less; no UI string added or changed (tooltips, dialogs, snackbars unchanged via `context.t.posts.deletePost.*` / `context.t.posts.eraseDbPost.*`).
- [ ] No `auto_route` page, route path, or `@PathParam` added/changed for delete/erase.
- [ ] Each adapter keeps inner `DioException` mapping plus an outer `on Object catch (e, st)` with `logger.error` returning `UnknownFailure`.
- [ ] Slice imports only `_shared/` and `core/`; no import of another posts slice.
- [ ] No `username` field added to `PostDto`; no handle migrated to an id.
- [ ] `dart run build_runner build --delete-conflicting-outputs` — no errors
- [ ] `dart run slang` — no errors
- [ ] `dart analyze` — no warnings
- [ ] All tests green
