# 0049 · delete_user_route_to_user_id — Validation Checklist

## Manual testing

| # | Step | Expected result |
|---|---|---|
| M1 | Signed in, open your own user-details screen and tap the delete (trash) icon. | The delete confirmation dialog appears. |
| M2 | In the confirmation dialog, cancel or dismiss it. | Dialog closes, no request is sent, you stay on the details screen and remain signed in. |
| M3 | In the confirmation dialog, confirm the deletion (against a fresh test account). | You are logged out locally and redirected to the public users list with an "account deleted" snackbar — **not** a "session expired" message. |
| M4 | With a network inspector open, confirm the deletion and read the outgoing request. | The request is `DELETE /user/{user_id}` carrying the **integer** user id, not the username string. |
| M5 | Tap delete, confirm, and watch the button while the request is in flight. | The delete button shows a spinner and is disabled, so it cannot be tapped again. |
| M6 | Trigger a delete that the server answers with 404 (e.g. an already-removed account). | The "not found" error snackbar is shown and you remain signed in. |
| M7 | Trigger a delete that the server answers with 403 (attempt to delete an account that is not yours). | The "forbidden" error snackbar is shown and you remain signed in. |
| M8 | Trigger a delete that the server answers with 401. | The "unauthorized" error snackbar is shown and you remain signed in. |
| M9 | Drive `confirmAndDelete` with an id that does not match the current user's id (bypass attempt). | The use-case returns `PermissionDenied`, the failure snackbar is shown, and **no** `DELETE` request is sent. |
| M10 | With no current user present, attempt the delete flow. | The guard denies (sentinel `-1` ≠ any real id) and no `DELETE` request is sent. |
| M11 | On the same user-details screen, use a sibling action (edit / assign moderator / update tier / erase). | The sibling buttons still work as before (still username-keyed) — the mixed-key actions row functions correctly. |

## Code review

- [ ] `UsersApiClient.deleteUser` is `@DELETE('/user/{user_id}')` with `@Path('user_id') int userId`, and `users_api_client.g.dart` was regenerated (not hand-edited) (N1).
- [ ] `DeleteUserPort.call` takes a single `int userId` (N2).
- [ ] The ownership guard (`userId != currentUserId → PermissionDenied`) lives in `DeleteUserUseCase`, not in the cubit or the UI (N3).
- [ ] `DeleteUserUseCase.call` signature is `{ required int userId, required int currentUserId }` (N4).
- [ ] `DeleteUserAdapter.call` takes `int userId`, calls `_api.deleteUser(userId)`, and keeps both the inner `DioException` switch (401/403/404/default) and the outer catch-all `catch (e, st)` with `logger.error` (N5).
- [ ] `DeleteUserCubit.confirmAndDelete` takes `int userId` and passes `currentUserId: _authCubit.currentUser?.id ?? -1` (N6).
- [ ] `DeleteUserState` is still a sealed `freezed` class with no user identifier added (N7).
- [ ] No hardcoded UI strings — all via `context.t.users.delete.*`, with no new slang keys (N8).
- [ ] The slice imports only `_shared/` and `core/`; no import of another `users` slice (N9).
- [ ] The only changed construction site is `DeleteAccountButton(userId: …)` in `user_details_screen.dart`; sibling buttons remain `username`-keyed (N10).
- [ ] The dialog, success snackbar, navigation target (`UsersRoute`), `forceLogout(notifyUser: false)`, and the self-delete rule are unchanged (N11).
- [ ] Tests exist on all four layers plus the outside-in test verifying `deleteUser(<int>)` is called (N12).
- [ ] No file under `core/` was modified; `AuthCubit` is read-only (N13).
- [ ] `dart run build_runner build --delete-conflicting-outputs` — no errors
- [ ] `dart run slang` — no errors
- [ ] `dart analyze` — no warnings
- [ ] All tests green
