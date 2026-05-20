# 0041 · user_header_menu — Requirements

## Functional Requirements

| ID | Requirement |
|---|---|
| F1 | When `AuthState` is `AuthAuthenticated` and `currentUser` is non-null, the AppBar renders the current user's username as a tappable widget (the popup menu anchor). |
| F2 | Tapping the username opens a dropdown menu containing exactly three items: "My Profile", "My Posts", and "Sign out". |
| F3 | "My Profile" and "My Posts" appear above a visual divider; "Sign out" appears below the divider. |
| F4 | Tapping "My Profile" navigates to the user details screen for the currently authenticated user. |
| F5 | Tapping "My Posts" navigates to the user posts screen for the currently authenticated user. |
| F6 | Tapping "Sign out" opens the existing logout confirmation dialog. |
| F7 | Confirming the logout dialog signs the user out (existing behavior is unchanged). |
| F8 | The standalone logout `IconButton` previously present in the AppBar is no longer rendered. |
| F9 | When `AuthState` is `AuthAuthenticated` and `currentUser` is null, no username, menu, or standalone button is rendered. |
| F10 | When `AuthState` is not `AuthAuthenticated`, no username or menu is rendered and the existing sign-in affordance is unchanged. |
| F11 | All three menu item labels are sourced from the localization system; no label is hardcoded. |
| F12 | "My Profile" navigation uses `UserDetailsRoute(username: currentUser.username)`; no new route is registered. |
| F13 | "My Posts" navigation uses `UserPostsRoute(username: currentUser.username)`; no new route is registered. |
| F14 | Menu item navigation pushes onto the currently active navigation stack without forcing a tab switch. |

## Non-functional Requirements

| ID | Requirement |
|---|---|
| N1 | The only production Dart file modified is `lib/core/routing/app_shell_screen.dart`; no new files are created under `lib/`. |
| N2 | Two new localization keys — `userMenu.myProfile` and `userMenu.myPosts` — are added to all four locale JSON files (`en-US`, `ru-RU`, `es-ES`, `uk-UA`). |
| N3 | The `_confirmLogout` method in `_AuthAppBarAction` is not modified; the "Sign out" item calls it without changes. |
| N4 | `AuthCubit`, `AuthState`, `CurrentUser`, and `app_router.dart` are not modified. |
| N5 | The `_UserMenuAction` enum is a private, file-level enum; it is not exported or visible outside `app_shell_screen.dart`. |
| N6 | No new Cubit, adapter, port, use-case, or route entry is introduced. |
| N7 | All navigation and dispatch logic is contained in a private helper method (`_onMenuAction`); no logic resides in the widget's `build` method. |
| N8 | Widget tests covering all observable behaviors of `_AuthAppBarAction` are added to `test/core/routing/app_shell_screen_test.dart`. |

## Out of scope

- A dedicated "My Profile" or "My Account" screen with content different from the existing user details view.
- Profile editing directly accessible from the menu.
- Avatar or profile image display in the AppBar.
- Notification badges or counts in the menu.
- Any backend API changes.
- Role-based visibility of menu items.
