# PRD 0017 — list_users: explicit navigation to user details and user posts

## Problem Statement

On the users list page, each user tile responds to a tap by navigating to the user's
detail page. There is no way to navigate directly to a user's posts from the list.
To view a user's posts, the user must first open the detail page and then find a
secondary navigation path — adding unnecessary steps to a common flow.

Additionally, the single-tap model hides the distinction between two fundamentally
different destinations (profile vs. content), making the interface ambiguous.

## Solution

Replace the implicit single-tap navigation on each user tile with two explicit,
labelled action buttons placed in the trailing area of the tile. Each button
shows a Material icon followed by a text label:

- **Details** (`Icons.person_outline` + "Details" / "Детали") — navigates to the
  user detail screen.
- **Posts** (`Icons.article_outlined` + "Posts" / "Статьи") — navigates to the
  user posts screen.

The tile body itself becomes non-tappable. Both actions are immediately visible,
removing ambiguity and providing a one-tap path to either destination.

## User Stories

1. As a user browsing the user list, I want to see a "Details" button on each
   user tile, so that I can navigate to a user's profile with a single tap.
2. As a user browsing the user list, I want to see a "Posts" button on each
   user tile, so that I can navigate directly to a user's posts without first
   opening their profile.
3. As a user, I want each action button to show both an icon and a text label,
   so that I can understand the destination without having to guess from the icon alone.
4. As a user, I want the "Details" icon to visually represent a person/profile,
   so that the action is immediately recognisable.
5. As a user, I want the "Posts" icon to visually represent an article/content,
   so that the action is immediately recognisable.
6. As a user, after returning from the user detail screen, I want the user list
   to be refreshed automatically, so that any changes made on the detail screen
   (e.g. edits, deletions) are reflected in the list.
7. As a user, after returning from the user posts screen, I want the user list
   to remain unchanged, so that the list does not reload unnecessarily when no
   user data has been modified.
8. As a user, I want the tile body to no longer respond to a generic tap, so
   that I am not accidentally taken to an unintended destination.

## Implementation Decisions

- This change is an **extension of the existing `list_users` slice** (presentation
  layer only). No new slice, route, domain, data, or application layer is required.
- The `UserTile` widget is modified to accept two callbacks — `onDetailsTap` and
  `onPostsTap` — replacing the existing single `onTap` parameter.
- The `ListTile.onTap` is set to `null`; the trailing area contains a `Row` of two
  `TextButton.icon` widgets (`icon` first, then `label`).
- Navigation and post-navigation side effects (refresh) are handled in the parent
  screen widget (`UsersScreen`), not inside `UserTile`, to keep the widget
  presentation-pure.
- `onDetailsTap`: pushes `UserDetailsRoute` and calls `UsersListCubit.refresh()`
  on return (preserves existing behaviour).
- `onPostsTap`: pushes `UserPostsRoute` and does **not** trigger a list refresh on
  return (posts do not affect user list data).
- Both target routes (`UserDetailsRoute`, `UserPostsRoute`) already exist in the
  router; no router changes are needed.
- Two new i18n keys are added under `users.list`:
  - `userDetails` → EN: "Details", RU: "Детали"
  - `userPosts` → EN: "Posts", RU: "Статьи"
- Slang codegen (`dart run slang`) must be run after adding the keys.

## Testing Decisions

Good tests verify **observable behaviour from the outside**, not internal widget
structure. For widget tests: render the widget, interact with it, assert on
navigation calls and cubit method calls — not on widget tree internals.

**Modules to test:**

- `UserTile` widget (unit/widget test):
  - Tapping the "Details" button invokes `onDetailsTap` and does not invoke
    `onPostsTap`.
  - Tapping the "Posts" button invokes `onPostsTap` and does not invoke
    `onDetailsTap`.
  - Tapping anywhere else on the tile body does not invoke either callback.
  - Both buttons are present and display the correct icon and label text.

- `UsersScreen` widget (widget test with mocked `UsersListCubit`):
  - After "Details" button tap and route return, `UsersListCubit.refresh()` is
    called.
  - After "Posts" button tap and route return, `UsersListCubit.refresh()` is
    **not** called.

**Prior art:** existing widget tests in `test/features/users/list_users/` and
mocktail-based cubit mocks used throughout the project.

## Out of Scope

- Adding a posts count or any data from the posts feature to the `User` entity or
  the users list API response.
- Conditionally hiding the "Posts" button based on post count or any other condition.
- Any changes to `UserDetailsRoute`, `UserPostsRoute`, or any other existing slice.
- Any changes outside the `list_users` presentation layer (domain, data, application,
  `_shared`, `core`).
- Navigation to user posts from anywhere other than the user list.

## Further Notes

- The `UserTile` widget lives in `list_users/presentation/widgets/` and is used only
  within the `list_users` slice — no other slices are affected by its API change.
- The existing default `onTap` logic inside `UserTile` (which fell back to
  `UserDetailsRoute` when no callback was provided) is removed entirely; the
  callbacks become required parameters.
