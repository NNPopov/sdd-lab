# 0055 · moderator_routes_to_user_id — Validation Checklist

## Manual testing

| # | Step | Expected result |
|---|---|---|
| M1 | As an admin who manages moderators, open the details screen of a non-moderator user and tap the moderator button. | The user is promoted via `PATCH /user/{user_id}/assign-moderator`; the button flips to "Revoke" with no reload. |
| M2 | As an admin who manages moderators, open the details screen of a moderator user and tap the moderator button. | The user is demoted via `PATCH /users/{user_id}/revoke-moderator`; the button flips to "Assign" with no reload. |
| M3 | Observe the actual PATCH request fired in M1 (network log). | The path is `PATCH /user/<integer>/assign-moderator` (singular `/user/`), with an integer where the handle used to be. |
| M4 | Observe the actual PATCH request fired in M2 (network log). | The path is `PATCH /users/<integer>/revoke-moderator` — **plural** `/users/` and an integer id (corrected on both axes). |
| M5 | Open a moderator user's details and watch the moderator button while a revoke is in flight. | A loading spinner replaces the button while the request runs, then the label updates on success — exactly as before. |
| M6 | Force the assign route to return 403, then tap "Assign". | An error snackbar shows the forbidden message; the button state is unchanged. |
| M7 | Force the assign route to return 409 (already a moderator), then tap "Assign". | An error snackbar shows the conflict message. |
| M8 | Force a route to return 404, then tap the moderator button. | An error snackbar shows the not-found / generic message; no crash. |
| M9 | As a user without the manage-moderators permission, open any user-details screen. | The moderator button is not shown. |
| M10 | Open a user-details screen and observe the moderator button while the user entity is still loading. | The button stays hidden until `isModerator` is known, gating on permission and moderator status only (no longer on a handle being present). |
| M11 | On the same screen, confirm the title and post navigation still use the handle. | The app-bar title still shows `@username` and tapping posts still navigates with the username — handle behavior unchanged. |
| M12 | After this slice, inspect the full user-details actions row (tier, edit, delete, erase, moderator). | Every action button is keyed by the integer id; no button is keyed by the handle. |

## Code review

- [ ] `assignModerator` declares `@PATCH('/user/{user_id}/assign-moderator')` (singular) with `@Path('user_id') int userId` (F1, N1).
- [ ] `revokeModerator` declares `@PATCH('/users/{user_id}/revoke-moderator')` (**plural** `/users/`) with `@Path('user_id') int userId` — the plural segment is present and not normalized to singular (F2, N1, N2, N17).
- [ ] `ModeratorManagementPort` declares `assignModerator(int userId)` and `revokeModerator(int userId)` (N3).
- [ ] `AssignModeratorUseCase.call(int userId)` and `RevokeModeratorUseCase.call(int userId)` delegate to the port with no guard and no id comparison (N4, N5).
- [ ] No `CurrentUser.id` / slice-0048 dependency is introduced in the use-cases (N5).
- [ ] The adapter calls `_api.assignModerator(userId)` / `_api.revokeModerator(userId)` with the `int` id and preserves `_mapHttp` (403 → Forbidden, 404 → NotFound, 409 → Conflict, default → ServerFailure) unchanged (N6, F7).
- [ ] Each adapter method retains the inner `DioException` catch plus the outer catch-all `catch (e, st)` with `logger.error` → `UnknownFailure` (N7).
- [ ] `AssignModeratorCubit.assign(int userId)` and `.revoke(int userId)`; the `initial / loading / success(isModerator) / error` state machine is unchanged (N8, F4, F5, F6).
- [ ] `assign_moderator_state.dart` is unchanged; it carries only `isModerator` (N9).
- [ ] `AssignModeratorButton` and `_AssignModeratorButtonInner` take `int userId`; tap calls `cubit.revoke(userId)` / `cubit.assign(userId)`; the `getIt`-provided cubit, `onToggled`, spinner, label toggle, and `_errorMessage` are unchanged (N10, F4, F5).
- [ ] In `user_details_screen.dart`: `AssignModeratorButton(userId: …)` is constructed with the viewed user's id; the gate keeps `canManageModerators && isModerator != null` and drops `username != null` (N11, F8, F9).
- [ ] The now-orphaned `username` local in `_UserDetailsAppBarActions` is removed; the separate app-bar-title `username` `context.select` is kept (N12, F10, F11).
- [ ] No sibling button (tier, edit, delete, erase) and no handle behavior (title, post nav, login, create/edit form) is changed (out of scope, F10, F11).
- [ ] No hardcoded UI strings; all via `context.t.users.moderator.*`, with no new keys added (N14).
- [ ] No cross-slice imports added; `domain/` imports no Flutter/Dio (N15).
- [ ] An outside-in test asserts `assignModerator(<int>)` and `revokeModerator(<int>)` are each called at the mocked `UsersApiClient` boundary, no live backend (N16).
- [ ] No new failures in unrelated user/auth/routing tests vs. baseline (N18).
- [ ] `users_api_client.g.dart` regenerated, not hand-edited (N13).
- [ ] `dart run build_runner build --delete-conflicting-outputs` — no errors
- [ ] `dart run slang` — no errors
- [ ] `dart analyze` — no warnings
- [ ] All tests green
