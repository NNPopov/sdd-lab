# 0041 · user_header_menu — Outside-in test spec

## Goal

Prove that the `_AuthAppBarAction` widget correctly renders a popup menu anchored
to the username, navigates to the right destination on "My Profile" / "My Posts",
and opens the confirmation dialog on "Sign out".

## Architecture note

This slice introduces no Cubit, adapter, port, or use-case. The change is entirely
within the `_AuthAppBarAction` widget in `app_shell_screen.dart`. The "outside-in"
test is therefore a **widget test** that drives the widget through real user
gestures. There is no Cubit state sequence to assert — the observable outcomes are
what appears on screen after each interaction.

## Entry point

The test pumps the full `AppShellScreen` widget tree (identical to the existing
`app_shell_screen_test.dart` setup), sets the mocked `AuthCubit` state to
`AuthAuthenticated` with a concrete `CurrentUser`, and then interacts with the
widget by tapping the username text in the AppBar.

## Wired real (production code in the test)

- `_AuthAppBarAction` (the widget under test — the only changed component)
- `AppShellScreen` (host; unchanged but needed to render the AppBar in context)
- `AutoTabsRouter` (needed to provide the routing context the widget uses)

## Mocked (system boundaries only)

- **`AuthCubit`** (MockCubit): state returns `AuthAuthenticated(currentUser: alice)`.
  `alice` is a `CurrentUser` fixture with `username: 'alice'`.
- **`PermissionCubit`**: real instance initialized from the mocked `AuthCubit`
  (same as existing tests in `app_shell_screen_test.dart`).
- **Stub cubits via `getIt`**: `UsersListCubit`, `UserDetailsCubit`,
  `GetUserTierCubit`, `UpdateUserTierCubit`, `UserPostsCubit` — registered as
  factory mocks in `getIt` so destination screens do not crash when pushed.
- **`AppRouter`**: real instance with `_PermissiveAuthGuard` (same as existing tests),
  allowing navigation to proceed without auth interception.

## Test scenarios

### Scenario 1: Opening the menu and navigating to "My Profile"

**Setup:**
- `AuthCubit` state: `AuthAuthenticated(currentUser: CurrentUser(username: 'alice', ...))`
- `UserDetailsCubit`, `GetUserTierCubit`, `UpdateUserTierCubit` registered via
  `getIt.registerFactory` with stub streams and initial states
- App pumped and settled via `_buildApp(authCubit: ..., permCubit: ...)`

**Act:**
1. Tap the text `'alice'` in the AppBar.
2. Wait for the popup menu to settle.
3. Tap the menu item labelled `'My Profile'`.
4. Wait for navigation to settle.

**Expect:**
- After step 2: the menu is open; items `'My Profile'`, `'My Posts'`, and `'Sign out'`
  are all visible in the widget tree.
- After step 4: the `UserDetailsScreen` is rendered (identified by `find.text('alice')`
  appearing as the AppBar title of the pushed screen, or by the presence of the
  user-details content widget).
- No `IconButton` with icon `Icons.logout` is present anywhere in the widget tree
  at any point during the scenario.

### Scenario 2: Tapping "Sign out" opens the confirmation dialog

**Setup:**
- Same `AuthCubit` state as Scenario 1.
- No destination-screen stub cubits required (dialog does not navigate).

**Act:**
1. Tap `'alice'` in the AppBar.
2. Wait for the popup to settle.
3. Tap the menu item labelled `'Sign out'`.
4. Wait for the dialog to settle.

**Expect:**
- After step 4: an `AlertDialog` is present in the widget tree.
- The dialog contains a button labelled `'Sign out'` (confirm) and a button
  labelled `'Cancel'` (dismiss).
- The `AuthCubit.logout` method has NOT been called yet (it is called only after
  the confirm button is tapped, which is tested by the existing logout tests).

## Out of scope for this test

- Widget rendering for the unauthenticated state (covered by existing
  `app_shell_screen_test.dart` tests — the sign-in button branch is unchanged).
- "My Posts" navigation (pattern is identical to Scenario 1; covered by unit widget
  test added alongside this outside-in test in `app_shell_screen_test.dart`).
- Locale translation of menu labels (verified manually per M15 in validation.md).
- Null `currentUser` branch (no observable interaction; covered by unit widget test).
- The full sign-out confirmation flow after tapping "Sign out" in the dialog
  (existing `AuthCubit` tests cover that path; it is unchanged).
