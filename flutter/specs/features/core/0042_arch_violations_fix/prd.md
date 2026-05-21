# PRD 0042 — Architectural Violations Fix

## Problem Statement

Engineers working on the codebase encounter three categories of architectural drift that
violate explicitly documented rules (CLAUDE.md) and produce false or real dart_code_linter
ALARM metrics:

1. **setState alongside Cubits in three widgets.** `CreateTierScreen`,
   `CreateUserScreen`, and `AssignModeratorButton` each maintain a piece of UI-reactive
   state via `setState` while also owning a Cubit. In the form screens, server
   validation errors are stored in a local `_serverErrors` map and piped back into
   `TextFormField.validator`; in `AssignModeratorButton`, moderator status is copied
   into a local `_isModerator` field that can drift from the authoritative value held
   by `UserDetailsCubit`. This creates two reactive systems managing the same UI and
   violates the hard rule against `setState` in widgets that have a Cubit.

2. **Domain entities importing `flutter/foundation.dart`.** `AuthSession` and
   `CurrentUser` import `flutter/foundation.dart` solely for the `@immutable`
   annotation. The domain layer must be pure Dart; any Flutter package dependency is
   forbidden there.

3. **`AppRouter.routes` triggers a false SLOC ALARM.** The `routes` getter is 121
   source lines, exceeding the 50-line threshold. The method contains zero logic — it
   is a declarative composition-root route tree with CC = 0. The SLOC metric misfires
   on inherently long declarative code.

## Solution

A single focused refactor pass that:

- Removes all `setState` usage from the three widgets, routing reactive state through
  the Cubit in each case, so there is one reactive system per widget.
- Replaces `flutter/foundation.dart` with `package:meta/meta.dart` in both domain
  entity files, preserving `@immutable` semantics without introducing a Flutter
  dependency in the domain layer.
- Extracts the `AppRouter` route tree into a `late final` instance field so the
  `routes` getter becomes a one-liner, silencing the false SLOC ALARM without
  suppression config or metric exclusions.

## User Stories

1. As an engineer extending a form screen, I want server validation errors to come from
   Cubit state, so that I have a single reactive source of truth and do not need to
   reason about two independent state systems.

2. As an engineer reading `CreateTierScreen`, I want the `BlocConsumer` listener to
   handle all side effects (navigation, snackbars) and the `BlocBuilder` to handle all
   display, so that the split between "react to events" and "render state" is clear.

3. As an engineer reading `CreateUserScreen`, I want server validation errors to
   disappear automatically when I start editing a field, so that stale server messages
   do not confuse users, and the clearing logic lives in the Cubit, not in widget
   lifecycle methods.

4. As an engineer reading `AssignModeratorButton`, I want the button to derive its
   label and action from a single prop passed by its parent, so that the button and
   the screen can never show contradictory moderator status.

5. As an engineer working on the `moderator_contract` slice, I want `AssignModeratorButton`
   to be decoupled from `UserDetailsCubit`, so that the button does not cross slice
   boundaries and can be reused or tested without that dependency.

6. As an engineer reading `user_details` code, I want moderator status updates to
   propagate through `UserDetailsCubit` via a targeted patch rather than a full reload,
   so that `GetUserTierCubit` is not re-triggered as a side effect of an unrelated
   operation.

7. As an engineer working in the domain layer, I want `AuthSession` and `CurrentUser`
   to have zero Flutter dependencies, so that domain unit tests do not require a Flutter
   test runner and the layer boundary is unambiguous.

8. As an engineer running `dart_code_linter:metrics`, I want `AppRouter.routes` to not
   appear in the ALARM list, so that the metric report surfaces real problems rather than
   false positives on declarative composition roots.

9. As an engineer adding a new feature route to `AppRouter`, I want the full route tree
   to be readable in one place, so that I do not need to navigate across multiple
   methods or files to understand the navigation hierarchy.

10. As an engineer maintaining dart_code_linter config, I want SLOC and CC suppressions
    to be absent or minimal, so that future regressions are caught by the same thresholds
    that exist today.

## Implementation Decisions

### CreateTierCubit and CreateUserCubit

- `CreateTierState` and `CreateUserState` rename their `initial` factory to `idle`.
  `Idle` means "form is ready, no pending operation result". `Initial` implied
  "screen just opened", which is wrong after a failed submission.
- Each Cubit gains a `clearError()` method that emits `Idle`. This is a clean state
  machine operation ("forget the last operation result"), not a UI concern leaking
  into the application layer.
- No per-field error clearing. `clearError()` takes no parameters.

### CreateTierScreen and CreateUserScreen

- `_serverErrors`, `_clearServerError`, and all `setState` calls are removed.
- `TextFormField.validator` handles client-side checks only (empty fields, format).
- `TextFormField.onChanged` calls `cubit.clearError()` for every field — any edit
  makes the previous server response stale.
- A server error text widget is rendered below the submit button via `BlocBuilder`,
  visible when state is `XxxFailure` with a `ValidationFailure`. The message is
  `failure.fieldErrors.values.firstOrNull`, which handles both FastAPI per-field errors
  (single item, real field key) and the fallback single-message path (`'error'` key).
  This also fixes the existing silent-drop bug where `'error'`-keyed validation
  messages were never shown.
- The `BlocConsumer` listener retains cases for `XxxSuccess` (pop + snackbar),
  `ConflictFailure` (snackbar), `PermissionDenied` (snackbar with a specific
  permission-denied message key, not generic), and a default generic snackbar.
  The `ValidationFailure` case is removed from the listener — display is handled
  entirely by the builder.
- `_formKey.currentState?.validate()` is no longer called from the listener.
- Stale server error and re-submit without changes: a server error for unchanged
  fields is still accurate (it reflects the server's response to those exact values).
  The error clears only when input changes (`onChanged`). Pressing submit again with
  the same invalid data does not clear the error before submission.

### AssignModeratorButton

- `AssignModeratorButton` gains a required `onToggled: void Function(bool isModerator)`
  callback parameter.
- `_AssignModeratorButtonInner` becomes a `StatelessWidget`. `_isModerator`, `setState`,
  and `initState` are removed.
- Button label and cubit method invocation are derived from `widget.isModerator` — the
  value passed from the parent, which reads from the authoritative source.
- On `AssignModeratorSuccess`, the `BlocListener` calls `widget.onToggled(state.isModerator)`.
  `state.isModerator` is an echo value (hardcoded true/false in the cubit based on
  which operation was called, not read from the server response body). This is safe
  as long as assign/revoke are idempotent — either the operation fully succeeds or
  the cubit emits `AssignModeratorError`. If the server ever returns a success body
  with the updated user, the cubit should be updated to read from it instead.
- `UserDetailsCubit` gains an `updateIsModerator(bool isModerator)` method that emits
  a new `UserDetailsLoaded` with the user entity patched via `copyWith`. This avoids
  a full reload and does not re-trigger `GetUserTierCubit.load()`.
- In `UserDetailsScreen`, `AssignModeratorButton` is called with
  `onToggled: (val) => context.read<UserDetailsCubit>().updateIsModerator(val)`.
  No direct dependency from `moderator_contract` presentation to `user_details`
  application — the boundary is maintained.

### Domain entities

- `AuthSession` and `CurrentUser` replace
  `import 'package:flutter/foundation.dart'` with `import 'package:meta/meta.dart'`.
- `@immutable` is provided by `package:meta` and behaves identically.
- No behavioral changes.

### AppRouter

- The body of `get routes => [...]` is extracted to a `late final List<AutoRoute>
  _routeTree` instance field. The getter becomes `get routes => _routeTree`.
- `late final` is correct here: the initializer runs lazily on first access, at which
  point `this.authGuard` and `this.permissionCubit` (constructor-injected instance
  fields) are available. `static final` is not viable because these are instance
  dependencies.
- The route tree is cached after the first access — built once, returned on every
  subsequent call. This is correct and desirable: the tree is structurally immutable
  after construction.
- After the change, verify with `dart run dart_code_linter:metrics analyze lib/` that
  the SLOC ALARM no longer fires. If `dart_code_linter 4.0.3` measures SLOC on `late
  final` initializers (unlikely, as these are field expressions, not method bodies),
  the fallback is a scoped `metrics-exclude` for `lib/core/routing/app_router.dart`
  with a TODO to narrow the scope when the tool supports method-level suppression.

## Testing Decisions

**What makes a good test here:** tests verify observable behavior (what the Cubit emits,
what the widget renders) — not implementation details (whether `setState` was called,
which private method was invoked).

### Cubit tests

- `CreateTierCubit` and `CreateUserCubit`: add test cases for `clearError()` — verify
  it emits `Idle` from any non-`Submitting` state.
- Existing submit/success/failure test cases remain valid; update state class names
  from `Initial` to `Idle` where referenced.
- `UserDetailsCubit`: add test case for `updateIsModerator(bool)` — verify it emits
  `UserDetailsLoaded` with the patched `isModerator` value without changing other user
  fields.

### Widget tests

- `CreateTierScreen` and `CreateUserScreen`: add cases verifying that a server
  `ValidationFailure` renders an error message below the submit button; that the
  message disappears after any `onChanged` event on a text field; and that the
  `PermissionDenied` failure triggers the correct snackbar message.
- `AssignModeratorButton`: verify that `onToggled` is called with the correct boolean
  on success; verify that the button label reflects `isModerator` from the prop, not
  from internal state; verify no setState dependency by confirming the widget tree is
  stateless.

### Domain tests

- `AuthSession` and `CurrentUser`: existing unit tests (equality, hashCode) continue
  to pass. No new tests required — this is an import substitution with no behavioral
  change.

### AppRouter

- No new tests. The route tree content is unchanged; only its housing moves from a
  getter body to a field initializer. Existing router integration or navigation tests
  remain valid.

## Out of Scope

- Decomposition of large `build()` methods in `PostDetailsScreen`, `CreateUserScreen`,
  and `UserDetailsScreen` (CC/SLOC ALARMs for those methods). Deferred to a follow-up
  slice.
- Addressing the 26 WARNING-level `_mapHttp`/`_parseValidation` CC metrics in
  adapters. Switch expressions over HTTP status codes are inherently branchy; a
  separate decision is needed on whether to raise the threshold for adapter error-
  mapping functions or introduce a shared mapping utility.
- Changing `ValidationFailure.fieldErrors` from `Map<String, String>` to a single
  `String message`. The current type is correct for the adapter's FastAPI error
  parsing. The widget fix (reading `values.firstOrNull`) is sufficient and does not
  require a type change.
- Any changes to server API contracts or adapter response parsing.

## Further Notes

- The `_parseValidation` silent-drop bug (server errors under key `'error'` were
  never displayed because no field validator checked that key) is fixed as a side
  effect of switching to the `values.firstOrNull` display pattern. No separate issue
  is needed.
- The `PermissionDenied` check in `CreateTierUseCase` is defense-in-depth: the route
  guard (`PermissionGuard({Permission.manageTiers})`) prevents reaching the screen
  without the required permission. The use case check catches any bypass and the
  widget now shows a distinct message rather than the generic adapter error fallback.
- The echo-value assumption for `AssignModeratorSuccess.isModerator` (hardcoded
  `true`/`false` in the Cubit) is safe while the operation contract is idempotent.
  If the backend evolves to return a user object in the response body, the Cubit
  should read `isModerator` from that response rather than hardcoding it.
