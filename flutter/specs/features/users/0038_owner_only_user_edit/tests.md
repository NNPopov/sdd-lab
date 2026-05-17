# 0038 · owner_only_user_edit — Outside-in test spec

## Goal

Prove that `UserDetailsScreen` hides the edit button for a non-owner even when
that user holds the `editUsers` permission, and that the button remains visible
for the profile owner.

## Entry point

Render `UserDetailsScreen(username: 'alice')` with the Cubit already in the
`UserDetailsLoaded` state, then inspect the widget tree for the presence or
absence of `Icons.edit`.

Note: this slice is **presentation-only** — there is no new Cubit, UseCase, Port,
or Adapter. The outside-in boundary for this fix is the screen widget itself.
The two scenarios below together form the acceptance gate: one proves the bug is
fixed, one proves the positive case is not regressed.

## Wired real (production code in the test)

- `UserDetailsScreen` — the modified widget; this is the slice's sole production
  artifact and the system under test.

## Mocked (system boundaries only)

- **`UserDetailsCubit`**: `MockCubit<UserDetailsState>`, state stubbed to
  `UserDetailsState.loaded(alice)` where `alice` is
  `User(id: 1, name: 'Alice', username: 'alice', email: 'alice@example.com', isModerator: false)`.
- **`AuthCubit`**: `MockCubit<AuthState>`, state set per scenario (see below).
- **`PermissionCubit`**: `MockCubit<Set<Permission>>`, state set per scenario.
- **`GetUserTierCubit`**: `MockCubit<GetUserTierState>`, stubbed to
  `GetUserTierState.initial()`.
- **`UpdateUserTierCubit`**: `MockCubit<UpdateUserTierState>`, stubbed to
  `UpdateUserTierState.initial()`.
- **`DeleteUserCubit`**: `MockCubit<DeleteUserState>` registered via `getIt`,
  stubbed to `DeleteUserState.initial()`.
- **`EraseDbUserCubit`**: `MockCubit<EraseDbUserState>` registered via `getIt`,
  stubbed to `EraseDbUserState.initial()`.

All mocked cubits expose an empty `stream` (no emissions during the test).

## Test scenarios

### Scenario 1: Non-owner with editUsers permission does not see the edit button

**Setup:**
- `AuthCubit.state` → `AuthState.authenticated(currentUser: bob)` where `bob` is
  `CurrentUser(username: 'bob', email: 'bob@example.com', name: 'Bob', isSuperuser: false, isModerator: false)`.
- `PermissionCubit.state` → `{Permission.editUsers}`.

**Act:**
- Render `UserDetailsScreen(username: 'alice')` inside a `MultiBlocProvider`
  backed by the mocks above, wrapped with `TranslationProvider`.

**Expect:**
- `find.byIcon(Icons.edit)` finds **nothing** in the widget tree.
- `find.byIcon(Icons.delete_outline)` finds nothing (bob is not the owner).

### Scenario 2: Owner sees the edit button (regression guard)

**Setup:**
- `AuthCubit.state` → `AuthState.authenticated(currentUser: alice)` where `alice`
  is `CurrentUser(username: 'alice', email: 'alice@example.com', name: 'Alice', isSuperuser: false, isModerator: false)`.
- `PermissionCubit.state` → `{Permission.viewCatalog}` (no `editUsers`).

**Act:**
- Render `UserDetailsScreen(username: 'alice')` with the same wrapper.

**Expect:**
- `find.byIcon(Icons.edit)` finds **one** widget.
- `find.byIcon(Icons.delete_outline)` finds one widget (owner's delete button).

## Out of scope for this test

- Route navigation triggered by tapping the edit button (covered by the existing
  Posts-navigation widget test group in `user_details_screen_test.dart`).
- The 403 backend rejection on a URL-bypass edit attempt (covered by the existing
  `edit_user` adapter unit tests).
- States other than `UserDetailsLoaded` (loading, error, initial) — those state
  transitions are covered by the existing `UserDetailsCubit` tests.
- Adapter, use-case, or cubit unit tests: this fix introduces no new logic in
  those layers.
