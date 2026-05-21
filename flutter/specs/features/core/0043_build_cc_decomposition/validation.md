# 0043 · build_cc_decomposition — Validation Checklist

## Manual testing

| # | Step | Expected result |
|---|---|---|
| M1 | Open the Create User form with valid data in all fields and tap Submit. | Success snackbar appears and the screen pops. |
| M2 | Open the Create User form and submit with a username/email that triggers a server HTTP 422 response. | A styled error text block appears **below the Submit button** — not as `errorText` on any `TextFormField`. |
| M3 | After M2, inspect each `TextFormField` on screen. | No field shows `errorText`; the only error visible is the text block below the button. |
| M4 | Open the Create User form and submit where the server returns HTTP 409 (conflict). | A snackbar appears containing the conflict message returned by the server. |
| M5 | Open the Create User form and submit where the network is unreachable. | A generic error snackbar appears; no error text appears below the button. |
| M6 | After M2 (validation error showing), type into any field without re-submitting. | The error text below the button remains visible; it does not clear on each keystroke. |
| M7 | Submit the Create User form with the Name field empty. | Client-side `errorText` appears on the Name `TextFormField`; no error text appears below the Submit button. |
| M8 | Submit the Create User form with a malformed email address. | Client-side `errorText` appears on the Email `TextFormField`; no error text appears below the Submit button. |
| M9 | Submit the Create User form with a password shorter than 8 characters. | Client-side `errorText` appears on the Password `TextFormField`; no error text appears below the Submit button. |
| M10 | Open the Create Tier form and trigger a server HTTP 422 response. | A styled error text block appears below the Submit button showing the server message. |
| M11 | On the Edit User form, trigger a server HTTP 422 response with per-field errors. | `errorText` appears on the specific field that the server indicated; no global text block appears below the button. |
| M12 | Log in as user `alice` and navigate to alice's profile page. | Edit icon and Delete button are visible in the AppBar. |
| M13 | While logged in as `alice`, navigate to a different user's profile. | No Edit, Delete, or DeleteAccount button is visible in the AppBar for that user's profile. |
| M14 | Log out and navigate to any user's profile page. | No Edit, Delete, Erase, or AssignModerator buttons are visible in the AppBar. |
| M15 | Log in as a user with the `eraseUsers` permission and navigate to another user's profile. | The Erase button is visible in the AppBar; no Edit or Delete button is visible. |
| M16 | Log in as a user with `manageModerators` permission and navigate to a user's profile while the user details are still loading. | The AssignModerator button is **not** shown during loading; it appears after `UserDetailsCubit` emits `UserDetailsLoaded`. |
| M17 | Log in as a user with `editUserTier` permission and navigate to another user's profile. | The UpdateUserTier button is visible in the AppBar. |
| M18 | Log in and open a post you authored. | AppBar shows the edit icon and delete button; the body shows `PostStatusChip`. |
| M19 | Log in and open a post you did **not** author (regular user, not superuser). | No edit, delete, or erase buttons in the AppBar; `PostStatusChip` is not shown in the body. |
| M20 | Log in as a superuser and open a post authored by a different user. | Erase button is visible in the AppBar; no edit or delete buttons are shown. |
| M21 | Navigate to a post while it is still loading. | `CircularProgressIndicator` is visible in the body; no action buttons are shown in the AppBar. |
| M22 | Navigate to a post that fails to load. | An error message and a Retry button are shown in the body; no action buttons are in the AppBar. Tap Retry — loading restarts. |

## Code review

- [ ] `lib/core/errors/failure.dart` declares `sealed class ValidationFailure extends Failure` and two `final class` subtypes (`FieldValidationFailure`, `MessageValidationFailure`) — neither uses `@freezed`.
- [ ] `failure.dart` no longer contains `const factory Failure.validation({required Map<String, String> fieldErrors}) = ValidationFailure`.
- [ ] Grep for `Failure.validation(` across the entire project → zero matches.
- [ ] Grep for `ValidationFailure.fieldErrors` across the entire project → zero matches.
- [ ] `create_user_adapter.dart` `_parseValidation` returns `MessageValidationFailure`; no `List`-parsing branch remains for this adapter.
- [ ] `create_tier_adapter.dart` `_parseValidation` returns `MessageValidationFailure`.
- [ ] `update_user_adapter.dart` `_parseValidation` returns `FieldValidationFailure`; the FastAPI `detail` list-parsing branch is preserved and maps items to `fields`.
- [ ] `update_user_usecase.dart` emits `FieldValidationFailure(fields: {'_form': 'Nothing to update'})` for the empty-update guard; no import of `flutter/*` or `dio/*` is present.
- [ ] `create_user_state.dart` contains `validationError({required String message}) = CreateUserValidationError` and `conflict({required String message}) = CreateUserConflict` factory constructors; existing variants are unchanged.
- [ ] `create_user_state.freezed.dart` is regenerated and consistent with the new state definition.
- [ ] `create_user_cubit.dart` `submit()` switches on failure type: `MessageValidationFailure` → `validationError`, `ConflictFailure` → `conflict`, other → `failure`; no nested switch.
- [ ] `create_user_screen.dart` listener switch has no nested `switch` expression; `CreateUserValidationError` has no listener case.
- [ ] Grep for `setState` in `create_user_screen.dart` → zero matches.
- [ ] `TextFormField` `validator` callbacks in `create_user_screen.dart` do not call `context.read`, `context.watch`, or access any map/local variable beyond the field value itself.
- [ ] `BlocBuilder` below the Submit button in `create_user_screen.dart` checks for `CreateUserValidationError` and renders `state.message`; does not cast `ValidationFailure` or call `.fieldErrors`.
- [ ] `create_tier_screen.dart` listener and builder reference `MessageValidationFailure`, not `ValidationFailure`.
- [ ] `edit_user_screen.dart` `_extractServerErrors` matches `FieldValidationFailure(:final fields)` and returns `fields`; no reference to old `ValidationFailure.fieldErrors`.
- [ ] `edit_user_screen.dart` listener matches `case FieldValidationFailure() || ConflictFailure(): break`.
- [ ] `lib/features/users/user_details/presentation/user_action_visibility.dart` exists and defines `final class UserActionVisibility` (no `_` prefix).
- [ ] `UserActionVisibility.from(...)` is a `static` method; the class has no mutable fields.
- [ ] `_UserDetailsAppBarActions.build()` calls `context.select` for `PermissionCubit`, `AuthCubit`, and `UserDetailsCubit`; no `context.read` call appears inside `build()` (only inside `onPressed`/`onToggled` callbacks).
- [ ] `user_details_screen.dart` `AppBar.actions` contains a single `_UserDetailsAppBarActions` widget; no inline `BlocBuilder<PermissionCubit>` or `BlocBuilder<AuthCubit>` nesting remains in the `AppBar`.
- [ ] `post_details_screen.dart` `build()` method contains only the `Scaffold` constructor with `_PostDetailsActions` in `AppBar.actions` and `_PostDetailsBody` as `body`; no inline `BlocBuilder` calls.
- [ ] `_PostDetailsActions` and `_PostDetailsBody` are `StatelessWidget` subclasses with `_` prefix; neither is annotated with `@injectable` or `@lazySingleton`.
- [ ] Each modified adapter (`create_user_adapter`, `create_tier_adapter`, `update_user_adapter`) contains both an inner `on DioException` catch and an outer `on Object catch (e, st)` with `_logger.error(...)`.
- [ ] No hardcoded UI strings in any modified presentation file; all user-visible strings use `context.t.<feature>.<slice>.*`.
- [ ] `user_action_visibility.dart` is imported only in `user_details_screen.dart` — not in other features.
- [ ] `dart run build_runner build --delete-conflicting-outputs` — no errors
- [ ] `dart run slang` — no errors
- [ ] `dart analyze` — no warnings
- [ ] All tests green
