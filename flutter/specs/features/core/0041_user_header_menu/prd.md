# PRD: User Header Menu (0041)

## Problem Statement

When a user is logged in, their username is displayed in the top-right corner of the app shell. However, there is no quick way to navigate to their own profile or their own posts from that location. The only action available next to the username is a standalone logout button. This forces users to manually find themselves in the users list or navigate to the posts tab and filter, which is unnecessarily indirect.

## Solution

Replace the plain username text and standalone logout button in the AppBar with a `PopupMenuButton` anchored to the username. Tapping the username opens a small dropdown menu with three items: **My Profile**, **My Posts**, and (separated by a divider) **Sign out**. Tapping "My Profile" navigates to the current user's details screen. Tapping "My Posts" navigates to the current user's posts screen. Tapping "Sign out" triggers the existing confirmation dialog. The standalone logout button is removed.

## User Stories

1. As a logged-in user, I want to tap my username in the AppBar and see a menu, so that I can quickly access my account options without searching the app.
2. As a logged-in user, I want to see "My Profile" in the menu, so that I know I can navigate directly to my own profile page.
3. As a logged-in user, I want to tap "My Profile" in the menu, so that I can view my own user details without scrolling through the users list.
4. As a logged-in user, I want to see "My Posts" in the menu, so that I know I can navigate to my own posts from anywhere in the app.
5. As a logged-in user, I want to tap "My Posts" in the menu, so that I can view the list of my own posts without navigating via the posts tab.
6. As a logged-in user, I want to see "Sign out" in the menu separated by a visual divider, so that the destructive action is clearly distinguished from navigation actions.
7. As a logged-in user, I want to tap "Sign out" in the menu and be asked to confirm, so that I cannot accidentally log out while browsing.
8. As a logged-in user, I want the navigation from the menu to push onto the current tab's stack, so that I can press the back button to return to where I was before opening a menu item.
9. As a logged-in user, I want the username in the AppBar to remain visible as a tappable affordance, so that I always know where to find my account options.
10. As a logged-in user who is currently on the Tiers or Pending tab, I want to tap "My Profile" or "My Posts" from the menu, so that the navigation works correctly regardless of the active tab.
11. As a developer, I want the menu labels to be provided via the existing localization system, so that the menu respects the user's selected locale.
12. As a developer, I want all existing logout-confirmation behavior to remain unchanged when triggered from the new menu item, so that no regression is introduced to the sign-out flow.

## Implementation Decisions

- The `_AuthAppBarAction` widget in the app shell is the only component modified. No new feature slices, adapters, use-cases, or cubits are introduced.
- The standalone logout `IconButton` is removed. Its logout-triggering logic is preserved and reused by the "Sign out" menu item.
- A `PopupMenuButton<_UserMenuAction>` (an internal enum with three values: `myProfile`, `myPosts`, `signOut`) wraps the username text, providing the tap target and menu anchor.
- The menu renders: "My Profile" → "My Posts" → `PopupMenuDivider` → "Sign out".
- Tapping "My Profile" calls `context.pushRoute(UserDetailsRoute(username: currentUser.username))`.
- Tapping "My Posts" calls `context.pushRoute(UserPostsRoute(username: currentUser.username))`.
- Tapping "Sign out" calls the existing `_confirmLogout` helper (unchanged).
- Navigation uses `context.pushRoute` on whatever stack is currently active — no tab switching.
- Two new localization keys are added to all locale files: `userMenu.myProfile` and `userMenu.myPosts`. The existing `auth.logout.confirm` key is reused for "Sign out".
- No change to `AuthCubit`, `AuthState`, `CurrentUser`, routing configuration, or any other file.

## Testing Decisions

A good test for this slice verifies only external behavior visible to the user: what appears on screen and what navigation/side-effects occur when the user interacts with the menu. It does not test internal widget structure, widget class names, or how `PopupMenuButton` is parameterized.

**Modules under test:**

- `_AuthAppBarAction` via widget test (the only changed component).

**Test cases:**

1. When `AuthState` is `AuthAuthenticated`, the username is rendered as a tappable widget in the AppBar.
2. Opening the menu (tapping the username) shows "My Profile", "My Posts", and "Sign out" items.
3. Tapping "My Profile" calls `context.pushRoute` with a route pointing to the current user's details screen.
4. Tapping "My Posts" calls `context.pushRoute` with a route pointing to the current user's posts screen.
5. Tapping "Sign out" opens the confirmation dialog.
6. The standalone logout `IconButton` is no longer present.
7. When `AuthState` is not `AuthAuthenticated`, no username or menu is rendered (existing behavior is unchanged).

**Prior art:** existing widget tests for `AppShellScreen` and `_AuthAppBarAction` in `test/core/routing/`.

## Out of Scope

- A dedicated "My Profile" or "My Account" screen with different content from the existing user details view.
- Profile editing accessible directly from the menu (edit is already accessible from the user details screen).
- Avatar or profile image display in the AppBar.
- Notification badges or counts in the menu.
- Any backend API changes.
- Role-based visibility of menu items (all three items are shown to every authenticated user).

## Further Notes

- The existing `UserDetailsRoute` and `UserPostsRoute` already support any username, including the currently logged-in user. No route changes are required.
- The `currentUser` field on `AuthAuthenticated` is nullable. The widget should handle the `null` case gracefully — if `currentUser` is null, the menu should not be shown (same as the current `Text(currentUser?.username ?? '')` fallback, which shows an empty string).
