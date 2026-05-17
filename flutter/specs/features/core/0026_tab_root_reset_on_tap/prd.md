# PRD — 0026: Tab Root Reset on Tap

## Problem Statement

When a user navigates deep within a tab (e.g., Users → UserDetails → UserPosts → PostDetails) and then taps another tab and returns, or taps the same tab again, the app resumes at the last visited child page rather than the root list for that tab. This violates the standard mobile tab-bar contract and surprises users who expect tapping a tab to always bring them back to the top-level screen of that section.

## Solution

Tapping any tab button — Users, Posts, or Tiers — always navigates instantly to the root screen of that tab, regardless of how deep the inner navigation stack is and regardless of whether the user is switching from another tab or re-tapping the currently active tab.

## User Stories

1. As a user, I want tapping the Users tab to always show the Users list, so that I can start fresh without manually pressing Back multiple times.
2. As a user, I want tapping the Posts tab to always show the Posts list, so that I can quickly return to top-level content.
3. As a user, I want tapping the Tiers tab to always show the Tiers list, so that I do not have to navigate back through tier detail screens I previously opened.
4. As a user, I want tapping the currently active tab again to reset it to its root, so that the tab button acts as a reliable "go to top" shortcut.
5. As a user, I want the reset to happen instantly with no slide-back animation, so that the experience feels like a mode switch rather than a back-navigation.
6. As a user navigating deep into Users (Users → UserDetails → UserPosts → PostDetails), I want tapping the Posts tab and then Users to show the Users list (not PostDetails), so that switching tabs always gives me a clean starting point.
7. As a user who switches from the Users tab to the Posts tab and back, I want the Users tab to reset to the Users list on return, so that re-tapping a tab is always predictable.
8. As a superuser on TierDetails, I want tapping the Tiers tab button to reset to the Tiers list, so that the root-reset behaviour is consistent across all tabs.
9. As a user who opens a post from the Posts tab, I want tapping Users and then Posts again to take me to the Posts list, so that I do not resume in the middle of a detail page unexpectedly.
10. As a user, I want the background tab's stack to persist in memory while I am on another tab, so that switching between tabs is fast and does not discard data until I explicitly reset by tapping.

## Implementation Decisions

- **Single change site.** Only the three user-initiated `onTap` callbacks on the tab buttons inside the shell's navigation bar widget need to change. The `BlocListener`-driven forced switch (logout while on the Tiers tab) is explicitly out of scope and must not be modified.
- **Reset mechanism.** Each tab's inner `StackRouter` is reset by calling `replaceAll` with a single-element list containing that tab's root route. This clears the page list and rebuilds declaratively, producing no pop transition animation. It is preferred over `popUntilRoot` (which triggers reverse-slide transitions through each intermediate page).
- **Root routes per tab.**
  - Users tab root: the Users list route.
  - Posts tab root: the global Posts list route.
  - Tiers tab root: the Tiers list route.
- **Null-safe inner router access.** The inner `StackRouter` for a tab may be `null` if that tab has never been activated. In that case, `replaceAll` is skipped (null-safe call) and `setActiveIndex` switches to the tab, which shows the initial route automatically.
- **Call order.** `replaceAll` is called before `setActiveIndex`. Both are synchronous at the page-list mutation level; the widget rebuild for both changes lands in the same frame, preventing any visible intermediate state.
- **No animation.** The `replaceAll` approach replaces the page stack declaratively. The root page, which was already in the stack at position zero, is matched and kept in place; child pages are removed without a reverse-slide transition.
- **Background stack preservation.** Non-active tabs remain in the `IndexedStack` and their routers are untouched between taps. Only the tap gesture triggers the reset.

## Testing Decisions

- **What makes a good test.** Tests must assert observable widget-tree state — which text labels, page titles, and widget types are present — rather than internal router state. They should not inspect `_pages` lists or controller internals.
- **Module under test.** The shell's navigation bar widget (`AppShellScreen` / `_AppNavBar`). Specifically, the `onTap` callback behaviour for each tab button.
- **Test cases.**
  1. Tapping the Users tab while deep in the Users stack (e.g., UserDetails pushed) shows the Users list and hides UserDetails.
  2. Tapping the currently active Users tab again (same-tab re-tap) resets to the Users list.
  3. Tapping the Posts tab while deep in the Posts stack shows the Posts list.
  4. Tapping the Tiers tab while deep in the Tiers stack (superuser) shows the Tiers list.
  5. After a cross-tab navigation sequence, re-tapping any tab shows that tab's root and not a child page from a prior visit.
- **Prior art.** The existing `app_shell_screen_test.dart` and `tab_navigation_test.dart` demonstrate the pattern: real `AppRouter` with `_PermissiveAuthGuard`, `getIt`-registered mock cubits, `AutoLeadingButton` element as context anchor for `AutoTabsRouter.of()`, `navigate` (not `push`) for inner-stack navigation to avoid awaiting the pop future.

## Out of Scope

- The logout-forced tab switch (`BlocListener` → `setActiveIndex(0)`) is not modified.
- Deep-link or URL-based navigation that may land on a child route directly is not affected.
- Scroll-position restoration within the root list screen is not addressed.
- Any change to the tab switching animation between tabs (currently an `IndexedStack` with no cross-tab transition) is not in scope.
- Per-tab "remember scroll position" or "smart reset" (e.g., reset only if already at root) is not in scope.

## Further Notes

- This slice is a small, targeted follow-up to 0025 (persistent shell navigation), which introduced the nested-stack tab structure that makes per-tab `replaceAll` possible.
- The change touches only the presentation layer (shell navigation bar `onTap` callbacks); no cubit, use-case, adapter, or domain code is involved.
- The `replaceAll` call is `unawaited`-safe: its async tail (navigation-guard evaluation) is irrelevant here because the root routes carry no guards within the tab stacks.
