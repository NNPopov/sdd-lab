# PRD — Fix Duplicate Back Arrow in Shell AppBar

## Problem Statement

When navigating to any detail screen (post details, user details, user posts, post
create/edit, tier create/edit/details), the user sees **two back arrows** stacked
vertically:

1. One in the shell AppBar (the top bar that also shows the app title, locale
   selector, and auth action).
2. One in the screen's own AppBar (shown just below the tab navigation bar).

Both arrows correctly navigate back, but their simultaneous presence is confusing
and visually broken.

## Solution

Remove the back-navigation responsibility from the shell AppBar entirely. The shell
AppBar becomes a purely global bar (app title + global actions). Each detail screen's
own AppBar retains its back arrow, which Flutter renders automatically whenever there
is a route to pop.

The shell AppBar must also opt out of Flutter's automatic leading-button inference
(`automaticallyImplyLeading: false`) so that the framework does not re-introduce a
back arrow even after `AutoLeadingButton` is removed.

## User Stories

1. As a user, I want to see exactly one back arrow when I open a detail screen, so
   that the navigation intent is unambiguous.
2. As a user, I want the back arrow to appear in the detail screen's own AppBar
   (next to the screen title), so that the arrow and the title form a coherent unit.
3. As a user, I want the shell AppBar (app title row) to be free of navigation
   arrows, so that it is clearly a global bar rather than a per-screen control.
4. As a user, I want pressing the back arrow on any detail screen to return me to
   the previous screen, so that navigation remains fully functional after the fix.
5. As a user on a top-level tab screen (Users, Posts, Tiers), I want no back arrow
   in either AppBar, so that the absence of history is correctly communicated.
6. As a user, I want the locale selector and auth action in the shell AppBar to
   remain unchanged, so that global controls are not affected by this fix.

## Implementation Decisions

- **Only one widget is modified:** `AppShellScreen` (the root shell that wraps
  `AutoTabsRouter`).
- **Two properties are changed on its `AppBar`:**
  - Remove the explicit `leading: AutoLeadingButton()`.
  - Add `automaticallyImplyLeading: false` to prevent Flutter from re-introducing
    an auto-inferred back button.
- All detail screens (`PostDetailsScreen`, `UserDetailsScreen`, `UserPostsScreen`,
  `CreatePostScreen`, `EditPostScreen`, `CreateTierScreen`, `EditTierScreen`,
  `TierDetailsScreen`, `CreateUserScreen`, `EditUserScreen`) are **not touched**.
  They already rely on Flutter's default `automaticallyImplyLeading: true`, which
  correctly shows a back arrow in their own AppBar whenever there is a route to pop.
- No routing configuration changes are required.
- No Cubit, use-case, adapter, or domain changes are required.

## Testing Decisions

Only the presentation layer is affected, so only a widget test is needed.

**What makes a good test here:** verify observable UI state (presence or absence of
a back-button widget in the shell AppBar) rather than implementation details
(whether `AutoLeadingButton` is in the widget tree).

**Modules to test:**
- `AppShellScreen` widget test — assert that the shell `AppBar` contains no
  leading icon/button when a detail route is active, and that the detail screen's
  own AppBar does contain a back button.

**Prior art:** existing widget tests under `test/features/` that pump a screen
widget with a mocked router and assert on rendered icons.

## Out of Scope

- Changing the visual design or position of the back arrow in detail screens.
- Updating the shell AppBar title dynamically to reflect the current screen name.
- Any changes to detail-screen AppBars themselves.
- Modifications to routing configuration, guards, or deep-link handling.

## Further Notes

The `AutoLeadingButton` widget (from `auto_route`) was originally added to the
shell to handle back navigation at the shell level. In this architecture, where
every detail screen owns its own `Scaffold` and `AppBar`, that responsibility
correctly belongs to each screen — not to the shell. Removing `AutoLeadingButton`
from the shell aligns the code with Flutter's standard navigation pattern.
