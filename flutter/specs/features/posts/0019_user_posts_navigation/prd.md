# PRD 0019 — user_posts: navigation to post details

## Problem Statement

On the user posts list page, each post tile is purely presentational — it displays
the post title, a truncated preview of the body, and the creation date, but provides
no way to open the full post. To read a complete article, the user has no direct
navigation path from the list, making the posts list a dead-end screen.

## Solution

Add an explicit action button to each post tile in the user posts list. The button
shows a Material icon followed by a text label ("Open" / "Открыть") and navigates
to the full post details screen. The tile body itself remains non-interactive.
This gives the user a clear, one-tap path from the list to any post's full content.

## User Stories

1. As a user viewing the posts list for a specific user, I want to see an "Open"
   button on each post tile, so that I can navigate to the full post with a single tap.
2. As a user, I want the "Open" button to show both an icon and a text label,
   so that the action is immediately recognisable without guessing.
3. As a user, I want the "Open" icon to visually represent opening or launching content,
   so that the intent of the action is clear at a glance.
4. As a user, I want tapping the post tile body (outside the button) to do nothing,
   so that I am not accidentally navigated somewhere by an imprecise tap.
5. As a user, I want tapping "Open" to take me directly to that post's full details screen,
   so that I can read the complete article without extra steps.
6. As a user, after I finish reading a post and return to the list, I want the list
   to remain unchanged, so that my place in the list is preserved and no unnecessary
   reload occurs.
7. As a Russian-speaking user, I want the button label to read "Открыть",
   so that the interface is consistent with the app's localisation.

## Implementation Decisions

- This change is an **extension of the existing `user_posts` slice** (presentation
  layer only). No new slice, route, domain, data, or application layer is required.
- The `PostTile` widget is modified to accept a required `onOpenTap` callback,
  replacing the current stateless, non-interactive design.
- The `PostTile` body remains non-tappable. The trailing area of the tile contains
  a single `TextButton.icon` widget (`icon` first, then `label`).
- The button uses `Icons.open_in_new` as the icon.
- Navigation and any post-navigation side effects are handled in the parent screen
  widget (`UserPostsScreen`), not inside `PostTile`, to keep the tile presentation-pure.
- `onOpenTap`: pushes `PostDetailsRoute` with the current `username` (available in
  `UserPostsScreen`) and the post's `id`. No list refresh is triggered on return,
  because viewing a post does not affect the list data.
- The target route (`PostDetailsRoute`) already exists in the router; no router
  changes are needed.
- One new i18n key is added under `posts.userPosts`:
  - `openPost` → EN: `"Open"`, RU: `"Открыть"`
- Slang codegen (`dart run slang`) must be run after adding the key.

## Testing Decisions

Good tests verify **observable behaviour from the outside**, not internal widget
structure. Render the widget, interact with it, assert on callback invocations and
navigation calls — not on widget tree internals.

**Modules to test:**

- `PostTile` widget test:
  - Tapping the "Open" button invokes `onOpenTap`.
  - Tapping the tile body does not invoke `onOpenTap`.
  - The button is present and displays the correct icon and label text.

- `UserPostsScreen` widget test (with mocked `UserPostsCubit`):
  - After the "Open" button tap, `router.push(PostDetailsRoute(...))` is called
    with the correct `username` and post `id`.
  - After returning from the post details screen, `UserPostsCubit.refresh()` is
    **not** called.

**Prior art:** existing widget tests in `test/features/posts/user_posts/` and
mocktail-based cubit mocks used throughout the project.

## Out of Scope

- Adding navigation to post details from any screen other than the user posts list
  (`/user/:username/posts`).
- Adding navigation to post details from the global posts list (`/posts`).
- Any changes to `PostDetailsRoute` or any other existing slice.
- Any changes outside the `user_posts` presentation layer (domain, data, application,
  `_shared`, `core`).
- Conditionally hiding the "Open" button based on any post attribute.
- Adding additional actions (edit, delete) to the post tile.

## Further Notes

- `PostTile` currently lives in `user_posts/presentation/widgets/` and is used only
  within the `user_posts` slice — no other slices are affected by its API change.
- `UserPostsScreen` already holds the `username` parameter required by
  `PostDetailsRoute`, so no additional data needs to be threaded through.
- The `PostDetailsRoute` accepts both `username` and post `id` as path parameters,
  both of which are available at the point of navigation in `UserPostsScreen`.
