# PRD 0043 — build() CC/Nesting Decomposition

## Problem Statement

Three presentation screens carry `build()` methods with ALARM-level cyclomatic complexity
and SLOC violations as reported by `dart_code_linter:metrics`. The violations are not
cosmetic — each one traces to a concrete structural problem:

- `CreateUserScreen.build()` (CC 17, SLOC 124): a single Cubit screen whose `build()`
  hides two independent problems. First, `_serverErrors: Map<String, String>` is a local
  copy of state that belongs to the Cubit, maintained through `setState` — a violation of
  the hard rule against `setState` in widgets that own a Cubit (already identified in
  0042, deferred from that slice). Second, the `BlocConsumer` listener contains a nested
  switch (`switch(state) { case Failure: switch(failure) { ... } }`) because
  `ValidationFailure` wraps a `Map<String, String>` that is always a single-entry map
  (`{'error': message}`) when the server returns a string, forcing every consumer to
  guess the key and risk a crash on empty maps.

- `UserDetailsScreen.build()` (CC 17, nesting 5, SLOC 151): the AppBar actions section
  chains `BlocBuilder<PermissionCubit>` wrapping `BlocBuilder<AuthCubit>` because the
  fragment needs both sources simultaneously. Using `context.read<AuthCubit>()` inside a
  `BlocBuilder<PermissionCubit>` builder would be a bug (not reactive — Auth changes
  would not trigger a rebuild). The correct fix is not another nested builder but a
  single reactive read of both Cubits that computes visibility in one place.

- `PostDetailsScreen.build()` (CC 14, SLOC 128): `AuthCubit` is read twice inside
  `build()` — once for AppBar actions and once for the body — creating two independent
  rebuild paths for the same source. Each section is complex enough to stand alone.

Enabling these fixes requires resolving the root cause for `CreateUserScreen`: the
`ValidationFailure` type. It currently wraps `Map<String, String>`, but the codebase
has two distinct server contracts under one type: adapters that receive a single-string
error (create_user, create_tier) and adapters that receive per-field errors routed to
individual `TextFormField`s (edit_user). `create_user` and `create_tier` consumers must
guess the map key and risk a `StateError` crash on an empty map; `edit_user` uses the map
correctly for per-field routing, but matches the same type. A single `Map<String, String>`
conflates both contracts. The solution is a sealed type that names each contract
explicitly.

## Solution

A focused refactor with three distinct tools applied where each fits:

1. **Sealed state variants + remove duplicated state** (`CreateUserScreen`):
   `ValidationFailure` becomes a sealed class with two variants —
   `FieldValidationFailure(Map<String, String> fields)` for per-field server errors and
   `MessageValidationFailure(String message)` for single-string server errors. Adapters
   for create_user and create_tier emit `MessageValidationFailure`; the edit_user adapter
   emits `FieldValidationFailure`. The Cubit gains explicit `validationError` and
   `conflict` state variants so the listener switch is flat. `_serverErrors`, `setState`,
   and `_clearServerError` are removed from `CreateUserScreen`. Server error is rendered
   as a `Text` block below the submit button via `BlocBuilder`, not via `errorText` per
   field.

2. **One reactive read of aggregated state** (`UserDetailsScreen` AppBar): a
   `_UserActionVisibility` value object computed from both `PermissionCubit` and
   `AuthCubit` via `context.select` in the body of the extracted AppBar actions widget.
   No nested `BlocBuilder` chain; both sources are reactive; nesting collapses from 5 to 1.

3. **Widget extraction with own Cubit-scope** (`PostDetailsScreen`): AppBar actions and
   body each become separate widgets with their own `BlocBuilder<AuthCubit>`. `AuthCubit`
   is read once per fragment; the double rebuild is eliminated.

## User Stories

1. As an engineer extending `CreateUserScreen`, I want server validation errors to come
   from a Cubit state variant, so that there is one reactive source of truth and no
   reasoning about two state systems.

2. As an engineer reading `CreateUserScreen`, I want the `BlocConsumer` listener to be a
   flat `switch` with one case per state variant, so that I can read the full event
   handling in one pass without following nested branches.

3. As an engineer reading `CreateUserScreen`, I want `TextFormField.validator` to contain
   only client-side checks, so that validators are pure functions of the field value and
   have no dependency on Cubit or widget state.

4. As an engineer working on any adapter that returns `ValidationFailure`, I want
   `ValidationFailure` to be a sealed class with explicit variants for per-field and
   single-string errors, so that the HTTP contract is named at the type level and I
   never need to guess map keys or handle an empty-map crash at the call site.

5. As an engineer reading `_parseValidation` in any adapter, I want the server response
   parsed into the correct `ValidationFailure` variant — `FieldValidationFailure` for
   structured per-field responses, `MessageValidationFailure` for string responses — so
   that the HTTP contract is encapsulated once and each consumer pattern-matches only
   the variant it expects.

6. As an engineer reading `UserDetailsScreen`, I want AppBar action visibility to be
   computed once from a `_UserActionVisibility` value object, so that
   `canErase`, `showEdit`, `showDelete`, `canEditTier`, and `canManageModerators` have a
   single point of computation that rebuilds reactively when either `PermissionCubit` or
   `AuthCubit` changes.

7. As an engineer maintaining `UserDetailsScreen`, I want `context.select` used instead
   of `context.read` for `AuthCubit` data that must stay reactive, so that a user
   authentication state change correctly triggers a rebuild of the AppBar actions.

8. As an engineer reading `PostDetailsScreen`, I want AppBar actions and the body to be
   separate widgets, so that each widget declares exactly the state it depends on and
   `AuthCubit` is not read twice in a single `build()`.

9. As an engineer running `dart_code_linter:metrics`, I want `CreateUserScreen.build()`,
   `UserDetailsScreen.build()`, and `PostDetailsScreen.build()` to have measurably lower
   CC and nesting after this refactor, so that the report surfaces real problems rather
   than structural debt. Whether each exits the ALARM band is verified by re-running
   `dart_code_linter:metrics` after implementation — not asserted in advance.

10. As an engineer writing a widget test for `CreateUserScreen`, I want server errors
    to be injected via Cubit state (emitting `CreateUserValidationError`), so that the
    test does not need to stub HTTP responses to verify error display.

11. As an engineer writing a widget test for `PostDetailsScreen`, I want `_PostDetailsActions`
    and `_PostDetailsBody` to be independently testable widgets, so that AppBar logic and
    body logic can be tested in isolation without rendering the full screen.

12. As an engineer writing a widget test for `UserDetailsScreen`, I want
    `_UserActionVisibility` to be a pure value object with a static factory method, so
    that visibility logic can be unit-tested without rendering any widget.

## Implementation Decisions

### ValidationFailure type change (enabling change)

`ValidationFailure` is replaced by a sealed class with two variants:

```dart
sealed class ValidationFailure extends Failure {}

final class FieldValidationFailure extends ValidationFailure {
  const FieldValidationFailure({required this.fields});
  final Map<String, String> fields;
}

final class MessageValidationFailure extends ValidationFailure {
  const MessageValidationFailure({required this.message});
  final String message;
}
```

This is a breaking change to the core `Failure` sealed class; all adapters that currently
emit `Failure.validation(fieldErrors: {...})` must be updated simultaneously.

In each adapter's `_parseValidation` (or equivalent), the variant is chosen by the server
contract:

- **Adapters whose server returns per-field errors** (currently `update_user_adapter`):
  parse `detail` into `Map<String, String>` (field key → message) and emit
  `FieldValidationFailure(fields: {...})`.
- **Adapters whose server returns a single-string error** (currently `create_user_adapter`,
  `create_tier_adapter`, and any adapter previously using `firstOrNull` extraction): emit
  `MessageValidationFailure(message: detailString)`.
- Fallback for null or unparseable detail: `MessageValidationFailure(message: 'Validation error')`.

Consumers match the variant they expect:

- `create_user_screen` / `create_tier_screen`: match `MessageValidationFailure(:final message)`
  → render `message` as a `Text` block below the submit button.
- `edit_user_screen`: match `FieldValidationFailure(:final fields)` → pass `fields` as
  `serverErrors` to `EditUserForm`; per-field display and `_clearServerError` are unchanged.

After this change, an empty-map `StateError` is structurally impossible and each screen
matches only the variant it expects — no guessing of map keys across consumers.

### CreateUserState new variants

Two explicit state variants replace the generic `failure(Failure)` path for the two
failure cases the screen handles distinctly:

- `validationError({required String message})` — server returned HTTP 422
- `conflict({required String message})` — server returned HTTP 409

The existing `failure(Failure failure)` variant remains for all other failure types
(network, server, unknown). `initial` is renamed to `idle` (consistent with 0042
naming for `CreateTierState`) to reflect that the form is ready for input at any
point, not only on first open.

`CreateUserCubit.submit()` maps each failure type to its state variant in a `switch`
on the `Failure` value. No nested switch.

### CreateUserScreen rewrite

Removed from `_CreateUserScreenState`:

- `Map<String, String> _serverErrors`
- `void _clearServerError(String field)`
- All `setState(...)` calls
- `onChanged` callbacks that called `_clearServerError`

`BlocConsumer.listener` becomes a flat `switch` with cases:
`CreateUserSuccess` (snackbar + pop), `CreateUserConflict` (snackbar),
`CreateUserFailure` (generic snackbar). `CreateUserValidationError` has no listener
case — it is handled entirely in the builder.

`TextFormField.validator` contains only client-side checks (empty/trim/regex/length).
No read of Cubit state or local map.

`BlocConsumer.builder` renders a `Text` error widget below the `FilledButton` when
state is `CreateUserValidationError`, invisible (`SizedBox.shrink`) otherwise.

### UserDetailsScreen AppBar actions

An extracted `_UserDetailsAppBarActions` widget computes visibility using two
`context.select` calls in its `build()` method — one for `PermissionCubit`, one for
`AuthCubit`. Both calls are reactive: a change in either Cubit causes this widget
to rebuild. The computed values are bundled into a `_UserActionVisibility` value
object (a simple `final class` with named boolean fields and a static `from(...)` factory).

`_UserActionVisibility.from(Set<Permission> permissions, AuthState auth, String username)`
is a pure function; it contains all the `isMe`, `canErase`, `canEditTier`,
`canManageModerators`, `showEdit`, `showDelete`, `showErase` derivations that currently
live inline in `build()`.

The existing `BlocBuilder<UserDetailsCubit>` nested inside `BlocBuilder<AuthCubit>`
inside `BlocBuilder<PermissionCubit>` for the `AssignModeratorButton` conditional is
resolved by reading `UserDetailsCubit` state via `context.select` inside the same
`_UserDetailsAppBarActions.build()`.

### PostDetailsScreen widget extraction

Two widgets extracted from `_PostDetailsScreenState.build()`:

- `_PostDetailsActions` — placed in `AppBar.actions`; contains one
  `BlocBuilder<PostDetailsCubit>` wrapping one `BlocBuilder<AuthCubit>`;
  computes `isAuthor`, `isSuperuser`, `showErase` from Cubit states; renders the
  `Row` with `DeletePostButton`, edit `IconButton`, and `EraseDbPostButton`.

- `_PostDetailsBody` — placed in `Scaffold.body`; contains one
  `BlocBuilder<PostDetailsCubit>` for the loading/error/loaded switch; inside the
  `loaded` branch, one `BlocBuilder<AuthCubit>` for `isAuthor` derivation.

After extraction, `_PostDetailsScreenState.build()` contains only the `Scaffold`
skeleton and the two widget placements — no inline business logic, no nested
BlocBuilders.

Both extracted widgets are `StatelessWidget` private to the screen file.

### Scope of ValidationFailure change

The following files currently emit `Failure.validation(fieldErrors: {...})` and must be
updated alongside the type change — each to the variant matching its contract:

- `create_user_adapter.dart` → `MessageValidationFailure`
- `create_tier_adapter.dart` → `MessageValidationFailure`
- `update_user_adapter.dart` → `FieldValidationFailure` (FastAPI `detail` list parsed
  into a keyed map; chain verified: `edit_user_screen` → `EditUserCubit` →
  `UpdateUserUseCase` → `UpdateUserPort` → `UpdateUserAdapter`)
- `update_user_usecase.dart` → `FieldValidationFailure` (client-side guard emits
  `Failure.validation(fieldErrors: {'_form': 'Nothing to update'})`; the `_form` key
  routes to the form-level error slot in `EditUserForm` — must stay `FieldValidationFailure`)
- Any other file with a `_parseValidation` method or an inline `Failure.validation(...)`
  call — inspect the contract to choose the variant.

The following presentation screens must be updated in the same commit:

- `create_user_screen.dart` — migrated as part of the sealed state rewrite (matches
  `MessageValidationFailure`).
- `create_tier_screen.dart` — update the `ValidationFailure` match to
  `MessageValidationFailure`. Note: 0042 already removed `setState`, `_serverErrors`, and
  `_clearServerError` from this screen; what remains is only the match in the listener
  (`case ValidationFailure(): break`) and the builder (`fieldErrors.values.firstOrNull`).
- `edit_user_screen.dart` — update the `ValidationFailure` match to
  `FieldValidationFailure`; `EditUserForm` and `_extractServerErrors` are unchanged.

All must land in the same commit to keep the project compilable.

## Testing Decisions

**What makes a good test here:** tests verify observable behavior — what state the
Cubit emits, what the widget renders — not implementation details such as whether
`setState` was called or which private helper was invoked.

### CreateUserCubit

New cases for the renamed and new state variants:

- `submit()` with a `ValidationFailure` response emits `CreateUserValidationError`
  with the extracted message string.
- `submit()` with a `ConflictFailure` response emits `CreateUserConflict` with the
  conflict message.
- `submit()` with any other failure emits `CreateUserFailure`.

### CreateUserScreen (widget test)

New cases:

- When cubit emits `CreateUserValidationError(message: 'Username taken')`, the text
  `'Username taken'` appears below the submit button.
- When cubit emits `CreateUserValidationError(...)`, no `errorText` appears on any
  `TextFormField`.
- When cubit emits `CreateUserConflict(message: 'Conflict')`, a snackbar appears.
- Validators accept valid input without error when state is `CreateUserValidationError`
  (server error and client-side valid input coexist correctly).

### _UserActionVisibility (unit test)

Pure function — fully testable without widget rendering:

- `from(permissions: {eraseUsers}, auth: authenticated as 'alice', username: 'bob')`
  → `showErase: true`, `showEdit: false`, `showDelete: false`.
- `from(permissions: {}, auth: authenticated as 'alice', username: 'alice')`
  → `showEdit: true`, `showDelete: true`, `showErase: false`.
- `from(permissions: {manageModerators}, auth: unauthenticated, username: 'alice')`
  → `canManageModerators: true`, `isMe: false`.

### _PostDetailsActions and _PostDetailsBody (widget tests)

Each widget tested independently with a mocked `PostDetailsCubit` and `AuthCubit`:

- `_PostDetailsActions` with `PostDetailsLoaded` + `isAuthor: true` → shows edit and
  delete buttons; no erase button.
- `_PostDetailsActions` with `PostDetailsLoaded` + `isSuperuser: true, isAuthor: false`
  → shows erase button; no edit or delete buttons.
- `_PostDetailsBody` with `PostDetailsLoading` → shows `CircularProgressIndicator`.
- `_PostDetailsBody` with `PostDetailsError` → shows retry button.
- `_PostDetailsBody` with `PostDetailsLoaded` + `isAuthor: true` → shows
  `PostStatusChip`; hides it when `isAuthor: false`.

Prior art: existing widget tests in `test/features/posts/` and `test/features/users/`
for similar BlocBuilder-driven screens.

## Out of Scope

- `CreateTierScreen` setState + Cubit fix — covered by slice 0042.
- `AssignModeratorButton` setState fix — covered by slice 0042.
- WARNING-level SLOC violations in other `build()` methods (26 warnings remain; below
  the ALARM threshold and not structurally problematic).
- `_mapHttp` CC warnings in adapters — separate decision on threshold vs. shared utility.
- Any changes to server API contracts or adapter response parsing beyond the
  `ValidationFailure` type change.
- `UserDetailsScreen` body section CC reduction beyond what falls naturally from the
  AppBar extraction.

## Further Notes

- The `ValidationFailure` type change in 0042 was explicitly marked out of scope
  (`"The current type is correct for the adapter's FastAPI error parsing"`). This PRD
  revisits that decision: the type is incorrect because it conflates two distinct server
  contracts under one type — per-field errors (`edit_user`) and single-string errors
  (`create_user`, `create_tier`) — forcing every consumer to pattern-match defensively
  against the wrong contract. The sealed-class correction belongs here rather than as a
  patch to 0042.
- `context.read<AuthCubit>()` inside a `BlocBuilder<PermissionCubit>` builder is a
  latent bug present in the current `UserDetailsScreen` and in `AssignModeratorButton`
  (0042). It is fixed here for `UserDetailsScreen`; the 0042 fix for `AssignModeratorButton`
  does not introduce this pattern and is unaffected.
- The `_UserActionVisibility` static factory is the canonical example in this codebase
  of moving derived visibility logic out of `build()` into a testable value object.
  Future screens with multi-Cubit permission gating should follow this pattern.
