# PRD 0018 — user_details: navigation to user posts

## Problem Statement

On the user detail screen, all information about a user (name, avatar, email, tier) is
visible, but there is no direct way to navigate to that user's posts. To view a user's
posts, the viewer must navigate back to the users list and use the "Posts" button on the
tile — adding unnecessary steps to a common flow when already on the detail screen.

## Solution

Add a single "Posts" action button below the user information on the user detail screen.
The button shows a Material icon followed by a text label (`Icons.article_outlined` +
"Posts" / "Статьи"), matching the visual language established in the users list (0017).
Tapping the button navigates directly to the user posts screen. No data is reloaded on
return, since viewing posts does not affect user profile data.

## User Stories

1. As a user viewing another user's detail screen, I want to see a "Posts" button below
   the user information, so that I can navigate to that user's posts without going back
   to the list.
2. As a user, I want the "Posts" button to show both an icon and a text label, so that
   the destination is immediately clear without having to guess from the icon alone.
3. As a user, I want the "Posts" icon to be the article/document icon, so that it is
   visually consistent with the "Posts" button already present on user tiles in the list.
4. As a user, I want the "Posts" button label to be "Posts" in English and "Статьи" in
   Russian, so that the UI is correctly localised regardless of my language setting.
5. As a user, after tapping "Posts" and returning to the detail screen, I want the user
   details to remain unchanged and not reload, so that I am not shown a loading spinner
   unnecessarily.
6. As a user with any role (guest, user, manager, admin), I want the "Posts" button to
   always be visible on the detail screen, so that I can always navigate to posts without
   needing special permissions.
7. As a user, I want the "Posts" button to be separated from the user info rows by a
   visual divider, so that the navigation action is visually distinct from the profile
   data above it.

## Implementation Decisions

- This change is an **extension of the existing `user_details` slice** (presentation
  layer only). No new slice, route, domain, data, or application layer is required.
- `UserDetailsView` is modified to accept a new `onPostsTap: VoidCallback` required
  parameter. The widget remains presentation-pure and does not import the router.
- Inside `UserDetailsView`, a `Divider` followed by a left-aligned `TextButton.icon`
  (`Icons.article_outlined` + localised label) is appended after the last info row.
- Navigation logic lives in `UserDetailsScreen`: it calls
  `context.router.push(UserPostsRoute(username: username))` as fire-and-forget (no
  `await`, no reload of `UserDetailsCubit`).
- The existing i18n key `users.list.userPosts` ("Posts" / "Статьи") is reused.
  No new keys are added to the JSON files and no codegen run is needed.
- The button is always visible — no `PermissionCubit` check, no `isMe` condition.
- `UserPostsRoute(username: String)` is already registered in `AppRouter`; no router
  changes are needed.

## Testing Decisions

Good tests verify **observable behaviour from the outside**, not internal widget
structure. Render the widget, interact with it, assert on callbacks and navigation —
not on widget tree internals.

**Modules to test:**

- `UserDetailsView` widget test:
  - The "Posts" button is present with `Icons.article_outlined` and the correct label.
  - Tapping the "Posts" button invokes `onPostsTap` exactly once.

- `UserDetailsScreen` widget test (with mocked `UserDetailsCubit`):
  - Tapping the "Posts" button triggers navigation to `UserPostsRoute`.
  - After returning from `UserPostsRoute`, `UserDetailsCubit.load()` is **not** called
    again (no refresh).

**Prior art:** existing widget tests in `test/features/users/list_users/presentation/`
and the `UserTile` / `UsersScreen` test patterns from slice 0017; mocktail-based cubit
mocks used throughout the project.

## Out of Scope

- Adding a posts count or any posts data to the `User` entity or the user details API
  response.
- Conditionally hiding the "Posts" button based on post count or any other condition.
- Any changes to `UserPostsRoute`, `AppRouter`, or any other existing slice.
- Any changes outside the `user_details` presentation layer (domain, data, application,
  `_shared`, `core`).
- Navigation to user posts from anywhere other than the user detail screen (the users
  list already handles this via slice 0017).

## Further Notes

- The visual pattern (icon + text label via `TextButton.icon`) is intentionally
  identical to the "Posts" button introduced in slice 0017, ensuring UI consistency
  between the list and the detail screen.
- `UserDetailsView` is a pure presentation widget consumed only by `UserDetailsScreen`
  within the `user_details` slice; changing its API does not affect other slices.
- The reuse of `users.list.userPosts` is pragmatic: both contexts show exactly the same
  label for the same destination. If the label ever needs to diverge, a dedicated
  `users.details.userPosts` key should be introduced at that point.
