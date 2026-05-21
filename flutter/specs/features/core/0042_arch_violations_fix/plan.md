# Plan 0042 — Architectural Violations Fix

## Overview

This is a cross-cutting refactor. It touches four independent areas with no shared
dependencies between them; they can be implemented in any order. The recommended order
below minimises cognitive load: start with the trivial one-liner fixes, work up to the
stateful widget rewrites.

---

## Files to read before starting

- `specs/features/core/0042_arch_violations_fix/prd.md` — decisions and assumptions
- `lib/core/errors/failure.dart` — `ValidationFailure.fieldErrors` type
- `lib/features/tiers/create_tier/application/create_tier_state.dart`
- `lib/features/tiers/create_tier/application/create_tier_cubit.dart`
- `lib/features/tiers/create_tier/presentation/create_tier_screen.dart`
- `lib/features/users/create_user/application/create_user_state.dart`
- `lib/features/users/create_user/application/create_user_cubit.dart`
- `lib/features/users/create_user/presentation/create_user_screen.dart`
- `lib/features/users/moderator_contract/application/assign_moderator_state.dart`
- `lib/features/users/moderator_contract/application/assign_moderator_cubit.dart`
- `lib/features/users/moderator_contract/presentation/widgets/assign_moderator_button.dart`
- `lib/features/users/user_details/application/user_details_cubit.dart`
- `lib/features/users/user_details/application/user_details_state.dart`
- `lib/features/users/user_details/presentation/user_details_screen.dart`
- `lib/core/auth/domain/entities/auth_session.dart`
- `lib/core/auth/domain/entities/current_user.dart`
- `lib/core/routing/app_router.dart`

Do **not** read other slices or `core/` files beyond those listed.

---

## Area 1 — Domain entity imports (one-liner, no codegen)

### Files changed

- `lib/core/auth/domain/entities/auth_session.dart`
- `lib/core/auth/domain/entities/current_user.dart`

### Steps

In both files replace:

```
import 'package:flutter/foundation.dart';
```

with:

```
import 'package:meta/meta.dart';
```

`package:meta` is already a transitive dependency (via `freezed_annotation`). No
`pubspec.yaml` change needed. `@immutable` exists in both packages with identical
semantics.

### Verification

`dart analyze` — no warnings. No codegen needed. No tests affected.

---

## Area 2 — AppRouter route tree (no codegen, no state change)

### Files changed

- `lib/core/routing/app_router.dart`

### Steps

Extract the list literal from `get routes => [...]` to a `late final` instance field:

```
late final List<AutoRoute> _routeTree = [ ... /* identical content */ ... ];

@override
List<AutoRoute> get routes => _routeTree;
```

`late final` is required (not `static final`) because the initializer references
`this.authGuard` and `this.permissionCubit` — instance fields injected via the
constructor. The lazy initializer runs on first access when `this` is available.

Caching effect: the route tree is built once and reused on every subsequent `routes`
call. This is correct and desirable for an immutable structure.

### Verification

Run `dart run dart_code_linter:metrics analyze lib/` after the change.

- If SLOC ALARM no longer appears for `AppRouter.routes` → done.
- If SLOC still fires on the field initializer → add a scoped `metrics-exclude` for
  `lib/core/routing/app_router.dart` in `analysis_options.yaml` with a TODO comment
  explaining the constraint.

No codegen. No tests affected (route tree content unchanged).

---

## Area 3 — CreateTierState and CreateTierCubit

### Files changed

- `lib/features/tiers/create_tier/application/create_tier_state.dart`
- `lib/features/tiers/create_tier/application/create_tier_cubit.dart`
- `lib/features/tiers/create_tier/presentation/create_tier_screen.dart`

### Existing tests to update

- `test/features/tiers/create_tier/application/create_tier_cubit_test.dart` (if exists)
- `test/features/tiers/create_tier/presentation/create_tier_screen_test.dart` (if exists)

### Step 1 — Rename Initial → Idle in state

In `create_tier_state.dart`:

```
// Before
const factory CreateTierState.initial() = CreateTierInitial;

// After
const factory CreateTierState.idle() = CreateTierIdle;
```

Run `dart run build_runner build --delete-conflicting-outputs` to regenerate
`create_tier_state.freezed.dart`.

Update every reference to `CreateTierInitial` and `CreateTierState.initial()` across
the cubit and screen.

### Step 2 — Add clearError() to Cubit

In `create_tier_cubit.dart`:

```dart
void clearError() => emit(const CreateTierState.idle());
```

Initial state in the constructor remains `CreateTierState.idle()`.

### Step 3 — Rewrite CreateTierScreen

Remove from the State class:
- `Map<String, String> _serverErrors`
- `void _clearServerError(String field)`
- All `setState(...)` calls

`_submit()` changes:
- Remove `setState(() => _serverErrors = {})`.
- The method stays otherwise identical.

`TextFormField.onChanged` changes:
- Replace `(_) => _clearServerError('name')` with
  `(_) => context.read<CreateTierCubit>().clearError()`.

`TextFormField.validator` changes:
- Remove `return _serverErrors['name'];` from the end.
- Keep only client-side checks (empty / trim).

`BlocConsumer.listener` changes:
- Remove the `ValidationFailure` case entirely.
- Add an explicit `PermissionDenied` case:
  ```dart
  case PermissionDenied():
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(t.tiers.createTier.errors.permissionDenied)),
    );
  ```
- Keep `CreateTierSuccess`, `ConflictFailure`, and default cases unchanged.
- Remove `_formKey.currentState?.validate()` call that was inside the
  `ValidationFailure` handler.

`BlocConsumer.builder` changes:
- After the `FilledButton`, add a server error text widget:
  ```dart
  BlocBuilder<CreateTierCubit, CreateTierState>(
    buildWhen: (_, s) => s is CreateTierFailure || s is CreateTierIdle,
    builder: (context, state) {
      if (state is CreateTierFailure && state.failure is ValidationFailure) {
        final msg = (state.failure as ValidationFailure)
            .fieldErrors.values.firstOrNull;
        if (msg != null) {
          return Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(msg, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          );
        }
      }
      return const SizedBox.shrink();
    },
  ),
  ```

Add a localization key `tiers.createTier.errors.permissionDenied` via slang if not
present.

### Codegen

After changing `create_tier_state.dart`:
```
dart run build_runner build --delete-conflicting-outputs
```

---

## Area 4 — CreateUserState and CreateUserCubit

Mirror of Area 3. Apply identical changes to:

- `lib/features/users/create_user/application/create_user_state.dart`
  → rename `initial` → `idle`, regenerate freezed.
- `lib/features/users/create_user/application/create_user_cubit.dart`
  → add `void clearError() => emit(const CreateUserState.idle())`.
- `lib/features/users/create_user/presentation/create_user_screen.dart`
  → remove `_serverErrors`, `setState`, `_clearServerError`.
  → `onChanged` for all four fields calls `cubit.clearError()`.
  → validators keep only client-side checks.
  → listener: remove `ValidationFailure`, add `PermissionDenied` (note:
    `CreateUserUseCase` has no pre-check today, so `PermissionDenied` will not
    fire in practice, but handle it defensively with a generic key or a dedicated
    `users.create.errors.permissionDenied` key).
  → builder: add server error text widget below submit button (same pattern as Area 3,
    reading from `CreateUserCubit` state).

Add localization key `users.create.errors.permissionDenied` if adding a dedicated
message; otherwise reuse `common.errors.permissionDenied` if such a key exists.

### Codegen

Same `build_runner` invocation after changing the state file.

---

## Area 5 — AssignModeratorButton and UserDetailsCubit

### Files changed

- `lib/features/users/moderator_contract/presentation/widgets/assign_moderator_button.dart`
- `lib/features/users/user_details/application/user_details_cubit.dart`
- `lib/features/users/user_details/presentation/user_details_screen.dart`

### Existing tests to update

- `test/features/users/moderator_contract/presentation/assign_moderator_button_test.dart`
  (if exists)
- `test/features/users/user_details/application/user_details_cubit_test.dart` (if exists)

### Step 1 — Add updateIsModerator to UserDetailsCubit

In `user_details_cubit.dart` add:

```dart
void updateIsModerator(bool isModerator) {
  final current = state;
  if (current is UserDetailsLoaded) {
    emit(UserDetailsLoaded(user: current.user.copyWith(isModerator: isModerator)));
  }
}
```

`User` is a `@freezed` class and has `copyWith`. No codegen needed for the Cubit itself.
This method does not call `load()` and therefore does not re-trigger the
`BlocListener<UserDetailsCubit>` cascade that fires `GetUserTierCubit.load()`.

### Step 2 — Rewrite AssignModeratorButton

Add a required callback parameter:

```dart
class AssignModeratorButton extends StatelessWidget {
  const AssignModeratorButton({
    required this.username,
    required this.isModerator,
    required this.onToggled,
    super.key,
  });

  final String username;
  final bool isModerator;
  final void Function(bool isModerator) onToggled;
```

Remove `_AssignModeratorButtonInner` as a `StatefulWidget`. Replace with a
`StatelessWidget` (rename or inline):

- Remove `_isModerator` field, `initState`, `setState` call.
- Button label and action derived from `widget.isModerator` directly.
- `BlocListener.listener`: on `AssignModeratorSuccess`, call
  `widget.onToggled(state.isModerator)` instead of `setState`.
- `BlocBuilder.builder`: use `widget.isModerator` for the label; it will reflect the
  updated value from the parent after `onToggled` triggers a `UserDetailsCubit` state
  change and the parent `BlocBuilder` rebuilds.

The outer `AssignModeratorButton` (which creates the `BlocProvider`) stays as
`StatelessWidget` — it already was one.

### Step 3 — Wire callback in UserDetailsScreen

Find the `AssignModeratorButton(...)` call inside the `BlocBuilder<UserDetailsCubit>`
and add:

```dart
AssignModeratorButton(
  username: widget.username,
  isModerator: userState.user.isModerator,
  onToggled: (val) =>
      context.read<UserDetailsCubit>().updateIsModerator(val),
),
```

No slice boundary is crossed: `UserDetailsScreen` is in `user_details/presentation`
and `UserDetailsCubit` is in `user_details/application`. The callback keeps
`moderator_contract/presentation` decoupled from `user_details/application`.

---

## New localization keys

Check `lib/core/i18n/i18n/` for the following keys and add them if absent:

- `tiers.createTier.errors.permissionDenied`
- `users.create.errors.permissionDenied` (or reuse a common key)

After editing any `*.json` under `lib/core/i18n/i18n/`:

```
dart run slang
```

---

## Codegen summary

| Trigger | Command |
|---|---|
| `create_tier_state.dart` changed | `dart run build_runner build --delete-conflicting-outputs` |
| `create_user_state.dart` changed | `dart run build_runner build --delete-conflicting-outputs` |
| i18n JSON changed | `dart run slang` |
| Nothing else triggers codegen | — |

---

## Tests to write or update

### CreateTierCubit

File: `test/features/tiers/create_tier/application/create_tier_cubit_test.dart`

New / updated cases:
- `clearError()` from `CreateTierFailure` → emits `[CreateTierIdle]`
- `clearError()` from `CreateTierIdle` → emits `[CreateTierIdle]`
- Rename all references from `CreateTierInitial` to `CreateTierIdle`

### CreateTierScreen (widget test)

File: `test/features/tiers/create_tier/presentation/create_tier_screen_test.dart`

New cases:
- When cubit emits `CreateTierFailure(ValidationFailure(fieldErrors: {'name': 'Too short'}))`,
  the text 'Too short' appears below the submit button.
- When cubit emits `CreateTierFailure(ValidationFailure(...))` and the user types in
  the name field, `cubit.clearError()` is called (i.e. the cubit receives an `Idle`
  emit — stub with `whenListen` or mock `clearError`).
- When cubit emits `CreateTierFailure(PermissionDenied())`, a snackbar with the
  permission-denied message appears.

### CreateUserCubit

Mirror of CreateTierCubit tests. File:
`test/features/users/create_user/application/create_user_cubit_test.dart`

### CreateUserScreen

Mirror of CreateTierScreen widget tests. File:
`test/features/users/create_user/presentation/create_user_screen_test.dart`

### UserDetailsCubit

File: `test/features/users/user_details/application/user_details_cubit_test.dart`

New case:
- Starting from `UserDetailsLoaded(user: user.copyWith(isModerator: false))`,
  `updateIsModerator(true)` emits
  `[UserDetailsLoaded(user: user.copyWith(isModerator: true))]`.
- `updateIsModerator` called when state is not `UserDetailsLoaded` → no state emitted.

### AssignModeratorButton (widget test)

File: `test/features/users/moderator_contract/presentation/assign_moderator_button_test.dart`

New / updated cases:
- Given `isModerator: false`, button shows "Assign" label.
- Given `isModerator: true`, button shows "Revoke" label.
- On `AssignModeratorSuccess(isModerator: true)`, `onToggled` is called with `true`.
- On `AssignModeratorSuccess(isModerator: false)`, `onToggled` is called with `false`.
- On `AssignModeratorError`, a snackbar appears; `onToggled` is not called.
- Widget is a pure `StatelessWidget` — no `State` subclass present.

---

## Verification checklist

Before declaring done:

```
□ dart format .          — no diff
□ dart analyze           — no warnings
□ dart run build_runner build --delete-conflicting-outputs
                         — after state file changes
□ dart run slang         — if i18n JSON changed
□ flutter test           — all existing + new tests pass
□ dart run dart_code_linter:metrics analyze lib/
                         — AppRouter SLOC ALARM gone (or file-exclude added with TODO)
                         — no new ALARMs introduced
□ _serverErrors, setState, _isModerator, initState removed from all three widgets
□ UserDetailsCubit.updateIsModerator exists and is unit-tested
□ No slice imports another slice (moderator_contract ↛ user_details/application)
□ domain/ in core/auth has no flutter/* import
```
