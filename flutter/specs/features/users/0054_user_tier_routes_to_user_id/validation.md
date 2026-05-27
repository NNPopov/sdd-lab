# 0054 · user_tier_routes_to_user_id — Validation Checklist

## Manual testing

| # | Step | Expected result |
|---|---|---|
| M1 | As a superuser, open the details screen of another user who has a tier assigned. | The tier panel shows that user's real tier name and created-at — loaded via `GET /user/{user_id}/tier`, no load error. |
| M2 | As a superuser, open the details of a user who has no tier assigned. | The tier panel shows the "Tier not assigned" not-found state (not a generic error). |
| M3 | As a superuser, open the tier bottom sheet, pick a tier, confirm. | The sheet closes, a success snackbar appears, and the tier panel refreshes to the new tier — all via the id-based routes, no 422. |
| M4 | Observe the actual PATCH request fired in M3 (network log). | The request path is `PATCH /user/<integer>/tier`, not `/user/<handle>/tier`. |
| M5 | As a superuser, open the tier sheet and confirm with no tier selected. | The confirm button is disabled; nothing is submitted. |
| M6 | As a superuser, confirm a tier change and watch the in-flight state. | The dropdown and confirm button disable and a spinner shows while submitting, then the sheet closes on success. |
| M7 | Force the update route to return a server error (e.g. backend down), then confirm a tier change. | An error snackbar appears with the generic update-tier message; the sheet handling matches the pre-migration behavior. |
| M8 | As a non-superuser who can reach the tier action, attempt to submit a tier change. | The change is refused with the permission-denied message; no PATCH request is sent. |
| M9 | As a user without the edit-tier permission, open a user-details screen. | The tier button is not shown. |
| M10 | Open a user-details screen and observe the tier button visibility while the user entity is still loading. | The button gates on permission only (no longer hidden merely because a handle is absent), matching the migrated delete button. |
| M11 | On the same screen, confirm the title and post navigation still use the handle. | The app-bar title still shows `@username` and tapping posts still navigates with the username — handle behavior unchanged. |
| M12 | On the same screen, confirm the moderator button still works. | `AssignModeratorButton` still appears and toggles as before (still handle-keyed; slice 0055). |

## Code review

- [ ] `getUserTier` and `patchUserTier` in `users_api_client.dart` declare `@GET`/`@PATCH('/user/{user_id}/tier')` with `@Path('user_id') int userId` (singular `/user/`) (F1, F2, N1).
- [ ] `GetUserTierPort.call(int userId)` and `UpdateUserTierPort.call({int userId, int tierId})` (N2).
- [ ] `GetUserTierUseCase.call(int userId)` delegates to the port with no guard (N3).
- [ ] `UpdateUserTierUseCase.call({int userId, int tierId, bool isSuperuser})` keeps `if (!isSuperuser) → Left(PermissionDenied)` in the use-case and the guard does not compare ids (N4, N5, F6).
- [ ] Both adapters call the API with the `int` id and preserve their exact HTTP failure mapping (get: 404 → "Tier not assigned"; update: default → server) (N6, F7, F8).
- [ ] Each adapter retains the inner `DioException` catch plus the outer catch-all `catch (e, st)` with `logger.error` → `UnknownFailure` (N7).
- [ ] `GetUserTierCubit.load(int userId)` and `UpdateUserTierCubit.submit(int userId)` with `isSuperuser` still sourced from `AuthCubit` (N8).
- [ ] `get_user_tier_state.dart` and `update_user_tier_state.dart` are unchanged; neither carries an identifier (N9).
- [ ] `UpdateUserTierButton`, `UpdateUserTierSheet`, and the inner `_TiersBody` submit call site all take `int userId` (N10, F2).
- [ ] In `user_details_screen.dart`: both `GetUserTierCubit.load(...)` call sites use `user.id`; `UpdateUserTierButton(userId: …)` is constructed with the screen's id; the tier-button gate drops `username != null` and uses `visibility.canEditTier` only (F4, F9, F10).
- [ ] The `username` local in the actions row is kept for `AssignModeratorButton`; no other sibling button is changed (N11, F11).
- [ ] `getTiersForSelection` / `fetch_tiers`, the moderator routes, and all handle behavior are untouched (out of scope).
- [ ] No hardcoded UI strings; all via `context.t.users.updateTier.*` / `context.t.users.details.*`, with no new keys added (N13).
- [ ] No cross-slice imports added; `domain/` imports no Flutter/Dio (N14).
- [ ] An outside-in test asserts `getUserTier(<int>)` and `patchUserTier(<int>, …)` are called at the mocked `UsersApiClient` boundary, no live backend (N15).
- [ ] No new failures in unrelated user/auth/routing tests vs. baseline (N16).
- [ ] `users_api_client.g.dart` regenerated, not hand-edited (N12).
- [ ] `dart run build_runner build --delete-conflicting-outputs` — no errors
- [ ] `dart run slang` — no errors
- [ ] `dart analyze` — no warnings
- [ ] All tests green
