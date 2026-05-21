# 0042 · arch_violations_fix — Validation Checklist

## Manual testing

| # | Step | Expected result |
|---|---|---|
| M1 | Open Create Tier screen, fill in a valid name, submit, and have the server return a 422 with a field-level message for `name`. | An inline error message appears below the submit button; no snackbar; the TextFormField name decoration itself shows no server error text. |
| M2 | Repeat M1 but with a 422 whose `detail` is a plain string (general error, not a list). | The plain string appears below the submit button; no silent drop. |
| M3 | With a server validation error visible below the submit button, type any character in the name field. | The error below the submit button disappears immediately; no snackbar; the field's own validator is unaffected. |
| M4 | Submit Create Tier form with the name field empty (do not submit to server). | The name TextFormField shows a "required" error message inline (from the local validator); no inline server error text below the button appears. |
| M5 | Trigger a 422 on Create Tier, observe the inline error, then do not edit anything and press Submit again (form is still client-valid). | The inline error disappears (state transitions to Submitting); no duplicate snackbar; a fresh server response is awaited. |
| M6 | Trigger a 422 on Create Tier, observe the inline error, then clear the name field (making it empty) and press Submit. | Client validation fires and the name field shows "required"; the inline server error text from the previous submission remains visible alongside it. |
| M7 | Submit Create Tier with a name that already exists (server returns 409 Conflict). | A snackbar appears with the server's conflict message; no inline error below the button. |
| M8 | Submit Create Tier with valid, unique data. | The screen pops (navigates back) and a success snackbar is shown. |
| M9 | Open Create User screen, fill all four fields with valid data, submit, and have the server return a 422 with a field-level message. | An inline error appears below the submit button; each of the four TextFormField decorations shows no server error text. |
| M10 | With a server error visible on Create User, edit any one of the four text fields. | The inline error below the button disappears; the edited field's local validator is unaffected. |
| M11 | Submit Create User with email field in invalid format (e.g. `not-an-email`) without submitting to server. | The email field shows a format-invalid error from the local validator; no inline server error text appears. |
| M12 | Submit Create User with password shorter than 8 characters. | The password field shows a "too short" error from the local validator; no inline server error text appears. |
| M13 | Open User Details for a user who is not a moderator, logged in as a user with `manageModerators` permission. | The `AssignModeratorButton` shows "Assign". |
| M14 | Open User Details for a user who is already a moderator, logged in as a user with `manageModerators` permission. | The `AssignModeratorButton` shows "Revoke". |
| M15 | Click "Assign" on a non-moderator user; server responds with success. | The button label changes to "Revoke" without any full-page loading indicator or tier section reload. |
| M16 | Click "Revoke" on a moderator user; server responds with success. | The button label changes to "Assign"; no loading indicator; tier section is unchanged. |
| M17 | Click "Assign"; server responds with an error (e.g. 403 Forbidden). | A snackbar with the appropriate error message appears; the button label does not change; no navigation occurs. |
| M18 | After a successful assign/revoke, scroll the User Details screen or navigate away and back. | The isModerator status in the user details view reflects the updated value (not the stale pre-toggle value). |
| M19 | Run `dart run dart_code_linter:metrics analyze lib/` against the post-change codebase. | `AppRouter.routes` does not appear in the ALARM section of the report. |
| M20 | Open `AppRouter` source file. | The full route tree is readable in one place (inside `_routeTree` field initializer); `get routes` is a one-liner. |

## Code review

- [ ] `lib/core/auth/domain/entities/auth_session.dart` imports `package:meta/meta.dart`, not `package:flutter/foundation.dart`.
- [ ] `lib/core/auth/domain/entities/current_user.dart` imports `package:meta/meta.dart`, not `package:flutter/foundation.dart`.
- [ ] No `setState(...)` call exists in `create_tier_screen.dart`, `create_user_screen.dart`, or `assign_moderator_button.dart`.
- [ ] `CreateTierState` sealed hierarchy contains `idle()` factory; no `initial()` factory exists.
- [ ] `CreateUserState` sealed hierarchy contains `idle()` factory; no `initial()` factory exists.
- [ ] `CreateTierCubit` exposes `clearError()` method that emits `CreateTierState.idle()`.
- [ ] `CreateUserCubit` exposes `clearError()` method that emits `CreateUserState.idle()`.
- [ ] Every `TextFormField.onChanged` callback in both form screens calls `cubit.clearError()`.
- [ ] No `TextFormField.validator` in either form screen returns a value from a local `_serverErrors` map.
- [ ] Neither form screen's `BlocConsumer.listener` contains a `ValidationFailure` case.
- [ ] Both form screens' `BlocConsumer.listener` contain an explicit `PermissionDenied` case with a localised snackbar message.
- [ ] Both form screens' `BlocBuilder` renders an error text widget below the submit button when state is `XxxFailure` with `ValidationFailure`; the text is derived from `failure.fieldErrors.values.firstOrNull`.
- [ ] `_AssignModeratorButtonInner` (or its replacement) is a `StatelessWidget`; no `State` subclass in `assign_moderator_button.dart`.
- [ ] `AssignModeratorButton` has a required `onToggled: void Function(bool isModerator)` parameter.
- [ ] `assign_moderator_button.dart` contains no `import` referencing `user_details/application`.
- [ ] `UserDetailsCubit` has `updateIsModerator(bool isModerator)` method that emits a new `UserDetailsLoaded` with the user patched via `copyWith`.
- [ ] `UserDetailsCubit.updateIsModerator` is guarded — it is a no-op when the current state is not `UserDetailsLoaded`.
- [ ] `UserDetailsScreen` passes `onToggled: (val) => context.read<UserDetailsCubit>().updateIsModerator(val)` to `AssignModeratorButton`.
- [ ] `AppRouter._routeTree` is declared `late final` (not `static`).
- [ ] `AppRouter.routes` getter body is `=> _routeTree` (single expression, no inline list literal).
- [ ] No hardcoded strings in any modified widget file — all user-facing text references a `context.t.*` key.
- [ ] New i18n keys (`tiers.createTier.errors.permissionDenied`, `users.create.errors.permissionDenied` or equivalent) are present in the slang JSON source files.
- [ ] `dart run build_runner build --delete-conflicting-outputs` — no errors
- [ ] `dart run slang` — no errors
- [ ] `dart analyze` — no warnings
- [ ] All tests green
