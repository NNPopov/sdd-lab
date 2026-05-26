# 0050 · user_details_edit_user_route_to_user_id — Validation Checklist

## Manual testing

| # | Step | Expected result |
|---|---|---|
| M1 | Open the users list and tap a user's details. | URL becomes `user/<id>` (an integer), and the detail screen loads that user's data. |
| M2 | Open `user/<valid id>` directly via deep link. | The matching user's details load and render. |
| M3 | Open `user/<id of a user that does not exist>`. | The "not found" error state is shown with a working Retry. |
| M4 | Compare a loaded detail screen against the pre-migration version. | The same fields are displayed (name, handle, email, tier, posts link, etc.). |
| M5 | While logged in as the profile owner, tap the edit button on the detail screen. | URL becomes `user/<id>/edit` and the edit form loads pre-filled. |
| M6 | While logged in as a non-owner, open `user/<another user's id>/edit` directly. | Access is blocked with the "you can only edit your own profile" forbidden state. |
| M7 | While logged out, open `user/<id>/edit` directly. | The auth guard redirects to login (route still guarded). |
| M8 | As the owner, change the username (handle) field in the edit form and save. | Save succeeds; the new handle is sent in the PATCH body and reflected after returning. |
| M9 | As the owner, save an edit with no changes. | The "nothing to update" validation message appears; no PATCH is sent. |
| M10 | As the owner, save an edit that the server rejects with 409 (duplicate handle). | The conflict is surfaced inline on the username field. |
| M11 | As the owner, save an edit the server rejects with 422 (invalid field). | The field-level validation error is shown inline. |
| M12 | After a successful edit, return to the detail screen. | The detail screen re-loads by id and shows the updated data. |
| M13 | Open the user menu and tap "my profile". | Navigates to `user/<current user's id>` and loads the current user's details. |
| M14 | Open the user menu and tap "my posts". | Navigates to the posts route using the handle (path still `/<username>/posts...`). |
| M15 | On the detail screen, tap the posts link. | Navigates to that user's posts using the loaded handle; the page loads. |
| M16 | View a detail screen of your own profile vs. another user's. | Edit/delete actions appear only on your own profile (ownership by id). |
| M17 | View a detail screen as a moderator/admin of another user. | Tier/moderator/erase actions still appear per permissions, keyed by the handle (unchanged). |

## Code review

- [ ] No `username` handle was migrated to an id: `User.username`, `CurrentUser.username`, `UpdateUserRequestDto`/`UserUpdate.username`, `@username` labels, login, and create-user form are untouched.
- [ ] `UsersApiClient.getUser` and `updateUser` declare `@Path('user_id')` with an `int` parameter.
- [ ] `updateUser`'s `@Body()` and request DTO are unchanged from before the migration.
- [ ] Route paths in `app_router.dart` are exactly `user/:user_id` and `user/:user_id/edit`; the four sibling `user/:username/posts...` paths are unchanged.
- [ ] `UserDetailsPage` and `EditUserPage` declare `@PathParam('user_id') int userId`.
- [ ] `UserDetailsCubit`/`EditUserCubit`, their ports, adapters, screens, and routes remain separate files (no merge).
- [ ] `AuthCubit.isMe` takes an `int` and compares `currentUser?.id == userId`.
- [ ] `EditUserCubit.loadInitial` guards ownership via `isMe(userId)` and `UserActionVisibility.from` gates edit/delete via `currentUser?.id == userId`.
- [ ] `get_user_adapter`, `get_user_for_edit_adapter`, and `update_user_adapter` each retain the inner `DioException` catch plus the outer catch-all with `logger.error`.
- [ ] `update_user_adapter` passes `original.id` as the PATCH path identity while leaving the body username and `_applyUpdate` unchanged.
- [ ] `updateUser` failure mapping still covers 401/403/404/409/422 + default.
- [ ] `users_screen.dart` builds `UserDetailsRoute(userId: u.id)`; `app_shell_screen.dart` "my profile" uses `currentUser.id` while "my posts" keeps `currentUser.username`.
- [ ] `domain/` files import nothing from Flutter/Dio (dartz/freezed/pure Dart only).
- [ ] No hardcoded UI strings introduced — text still via `context.t.*`.
- [ ] No new entries in `pubspec.yaml`; no slice outside the named scope was modified.
- [ ] `dart run build_runner build --delete-conflicting-outputs` — no errors
- [ ] `dart run slang` — no errors
- [ ] `dart analyze` — no warnings
- [ ] All tests green
