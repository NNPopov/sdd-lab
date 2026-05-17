# PRD: Persistent Shell Navigation (0025)

## Problem Statement

When a user navigates from a top-level tab (Users, Posts, Tiers) into a detail page
(e.g., user details, post details, tier details), the application shell — including
the tab bar — disappears entirely. The user loses their orientation within the app.

Worse, after performing a destructive action such as deleting a user or a post, the
app leaves the user stranded on a page that no longer has valid content, with no
visible way to navigate back. There is no back button in the AppBar and no tab bar
to switch sections.

## Solution

Restructure the navigation graph so that the app shell (AppBar + tab bar) is always
visible, regardless of how deep the user has navigated within a tab. Each tab
(Users, Posts, Tiers) becomes an independent nested stack navigator. Navigating into
detail pages, edit pages, or create pages pushes onto the active tab's stack while
the shell remains rendered.

A back-arrow button appears in the AppBar whenever there is a previous page in the
current tab's stack, giving the user a clear, always-visible path back.

After a destructive action (delete user, delete post, delete tier), the tab's stack
is replaced with the corresponding list page, preventing navigation to a
now-invalid resource.

## User Stories

1. As a user browsing the Users tab, I want the tab bar to remain visible when I
   open a user's detail page, so that I can switch to Posts or Tiers at any moment.
2. As a user browsing the Posts tab, I want the tab bar to remain visible when I
   open a post's detail page, so that I always know where I am in the app.
3. As a user browsing the Tiers tab, I want the tab bar to remain visible when I
   open a tier's detail page, so that I can return to another section without
   getting lost.
4. As a user on a detail page, I want a back-arrow in the AppBar, so that I can
   return to the previous page with a single tap.
5. As a user who has navigated several levels deep (e.g., Users → User Details →
   User Posts → Post Details), I want the back-arrow to take me one level back at a
   time, so that I can retrace my steps naturally.
6. As a user on the root page of a tab (e.g., the Users list), I want the back-arrow
   to be hidden, so that I am not presented with a misleading affordance.
7. As a user on Android, I want the hardware back button to navigate one level back
   within the current tab's stack, so that the system gesture behaves consistently
   with the in-app UI.
8. As a user who has just deleted a user, I want to be automatically returned to the
   Users list, so that I am not left on a page representing a resource that no
   longer exists.
9. As a user who has just deleted a post, I want to be automatically returned to the
   Posts list (or User Posts list, depending on entry point), so that I am not
   stranded after the action completes.
10. As a user who has just deleted a tier, I want to be automatically returned to
    the Tiers list, so that I am not left on an orphaned detail page.
11. As a user opening the Create User form, I want it to open inside the Users tab
    stack, so that the tab bar remains visible and I can cancel by pressing back.
12. As a user opening the Edit User form, I want it to open inside the Users tab
    stack, so that the shell remains consistently visible.
13. As a user opening the Create Post form, I want it to open inside the Posts tab
    stack, so that the tab bar remains visible throughout the creation flow.
14. As a user opening the Edit Post form, I want it to open inside the Posts tab
    stack, so that the shell remains visible.
15. As a user opening the Create Tier form, I want it to open inside the Tiers tab
    stack, so that the shell remains visible.
16. As a user opening the Edit Tier form, I want it to open inside the Tiers tab
    stack, so that the shell remains visible.
17. As a user on the User Posts page (posts belonging to a specific user), I want
    the page to render inside the Users tab stack, so that the tab context is
    preserved.
18. As a superuser on the Tiers tab who logs out, I want to be automatically
    redirected to the Users tab, so that I am not left on a tab I no longer have
    access to.

## Implementation Decisions

### Modules to build or modify

**New: Three tab wrapper routers**
Each of the three main tabs is promoted from a simple page to a nested stack
navigator (an `AutoRouter` subclass). Each wrapper router hosts its own
navigation stack:
- `UsersTabRouter` — owns: Users list, User Details, User Posts, Create User,
  Edit User, Post Details (when entered from user context), Create Post (user
  context), Edit Post (user context).
- `PostsTabRouter` — owns: Posts list (global), Post Details (when entered from
  global list), Create Post (global), Edit Post (global).
- `TiersTabRouter` — owns: Tiers list, Tier Details, Create Tier, Edit Tier.

**Modified: App router configuration**
The router configuration moves all detail, create, and edit routes out of the
top-level stack and into the children list of their owning tab router. The
top-level stack retains only the login route and the shell route.

**Modified: App shell screen**
The `AutoTabsRouter` `routes` list is updated to reference the three new tab
router pages instead of the three list pages. The `AutoLeadingButton` widget
is added as the `leading` property of the `AppBar`, so the back-arrow appears
automatically whenever the active tab's stack has a previous entry.

**Modified: Delete-action cubits / use-cases**
After a successful delete, the navigation command changes from a simple `pop`
to a `replaceAll` targeting the root list route of the active tab. This applies
to delete-user, delete-post, and delete-tier flows.

### Architectural decisions

- Each tab router is a thin wrapper; it carries no business logic and no DI
  provision — those remain in the individual route widgets.
- The `AutoLeadingButton` is rendered by the shell, not by individual pages, so
  no page needs to know whether it is at the root of its stack.
- Route ownership is determined by the primary actor of the content: user-scoped
  posts (User Posts, Post Details reached from a user) live in the Users tab;
  globally-scoped posts live in the Posts tab. This assignment can be changed by
  moving routes between tab router children lists without touching any page widget.
- Guards (authGuard, PermissionGuard) remain on individual routes, not on the
  tab router wrappers, preserving the existing guard behaviour.

## Testing Decisions

Good tests for this slice verify observable navigation behaviour — what page is
on screen and which back controls are visible — without asserting on internal
router state or route object types.

**Modules to test:**

- **Router configuration** — integration-level navigation tests confirming that
  navigating to a detail path from within a tab keeps the shell scaffold in the
  widget tree, and that no tab navigation is present after navigating to a
  previously top-level route via its old path.
- **App shell widget** — widget tests confirming that `AutoLeadingButton` is
  present in the AppBar, and that it is hidden on the root of each tab and
  visible when the stack depth is > 1.
- **Delete flows (Cubits)** — unit/bloc tests confirming that on successful
  delete the cubit emits a state that triggers `replaceAll` to the list route,
  rather than `pop`. Prior art: existing delete-post and delete-tier cubit tests.

## Out of Scope

- Changing the visual design of the tab bar or AppBar beyond adding
  `AutoLeadingButton`.
- Deep-link URL structure changes (paths stay the same; only their position in
  the route tree changes).
- Cross-tab navigation (e.g., tapping a username inside the Posts tab and
  landing in the Users tab). Each tab navigates within its own stack only.
- AppBar title changes per page (title remains the static app title).
- Bottom navigation bar (the existing top tab bar is kept as-is).

## Further Notes

- The `auto_route` nested router pattern (`@AutoRouterConfig` on a shell +
  per-tab `AutoRouter` subclasses) is already used for the shell itself; this
  slice applies the same pattern one level deeper.
- Moving a route's tab ownership in the future is a single-file change
  (`app_router.dart`) with no impact on page widgets, cubits, or adapters.
- The logout-to-Users-tab redirect in `AppShellScreen` remains unchanged; it
  operates on tab indices, which are stable after this refactor.
