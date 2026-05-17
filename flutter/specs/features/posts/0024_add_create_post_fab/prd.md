# PRD — 0024: Add Create Post FAB to User Posts Screen

## Problem Statement

When a user navigates to their own posts page, there is no way to create a new post
from that screen. The only path to post creation requires knowing the direct URL.
Users who arrive at their own posts page expect to see an action to author a new post,
consistent with the creation affordances on other list screens (users, tiers).

## Solution

Add a Floating Action Button (FAB) to the User Posts screen that appears exclusively
when the authenticated user is viewing their own posts. Tapping the FAB navigates to
the existing Create Post screen. On return, the post list is refreshed automatically.

The FAB matches the visual pattern established by the Create Tier FAB on the Tiers
list screen.

## User Stories

1. As an authenticated user viewing my own posts page, I want to see a "New post"
   FAB, so that I can create a new post without needing to know a direct URL.
2. As an authenticated user, I want the FAB to navigate me to the Create Post form,
   so that I can fill in and publish a new post.
3. As an authenticated user, I want the post list to refresh automatically after I
   create a post and return to my posts page, so that the new post appears immediately.
4. As an authenticated user viewing another user's posts page, I want the FAB to be
   hidden, so that I cannot accidentally attempt to create a post on their behalf.
5. As a superuser viewing another user's posts page, I want the FAB to be hidden,
   so that the UI reflects that superusers cannot create posts on behalf of others.
6. As a guest (unauthenticated user), I want the FAB to be hidden, so that I am not
   presented with an action I cannot perform.
7. As an authenticated user, I want a tooltip on the FAB that reads "New post", so
   that the button's purpose is unambiguous on long-press or hover.
8. As a user with the app set to Russian locale, I want the FAB tooltip to read
   "Новый пост", so that the UI is consistent with the selected language.

## Implementation Decisions

### Modules modified

- **User Posts presentation layer** — The User Posts screen gains a
  `floatingActionButton`. Visibility is derived reactively from `AuthCubit` state
  using a `BlocBuilder<AuthCubit, AuthState>`: the FAB renders only when the
  authenticated user's username matches the `username` path parameter. In all other
  cases a zero-size placeholder is rendered.

- **i18n string tables** — A new key `fabTooltip` is added under
  `posts.createPost` in both the English and Russian locale files. Slang codegen
  is re-run after this change.

### Ownership rule

The visibility guard (`currentUser.username == username`) is a UX convenience only.
The authoritative ownership check already lives in `CreatePostUseCase`, which returns
`ForbiddenFailure` if the caller attempts to publish under a different username. No
change to the use-case is required.

### Navigation and refresh

After the FAB is tapped, the router pushes `CreatePostRoute` with the current screen's
`username` parameter. On pop (regardless of whether a post was actually created),
`UserPostsCubit.refresh` is called unconditionally. `context.mounted` is checked
before accessing the cubit post-await.

### Route guard

`CreatePostRoute` is already protected by `authGuard`. No additional permission guard
is required — post creation is open to any authenticated user acting as themselves.

### Superuser behaviour

Superusers can erase posts (existing behaviour) but cannot create posts on behalf of
other users. The FAB is hidden whenever `currentUser.username != username`, which
includes the superuser-viewing-other-profile case.

### FAB style

Standard `FloatingActionButton` with `Icon(Icons.add)` and a localised `tooltip`.
Matches the Create Tier FAB established in the Tiers list screen.

## Testing Decisions

Good tests verify observable UI behaviour, not internal wiring. They pump the widget
with a specific `AuthCubit` state and assert what is (or is not) rendered — they do
not inspect how the cubit is read internally.

### Modules tested

**User Posts screen widget test** (extends the existing test file):

- The test harness (`_wrapWithRouter`) is updated to accept and provide an `AuthCubit`
  mock alongside the existing `UserPostsCubit` mock.
- `T-FAB-1` — When `AuthState` is `authenticated` with `currentUser.username ==
  'alice'` and the screen's `username` is `'alice'`, a `FloatingActionButton` is
  present in the widget tree.
- `T-FAB-2` — When `AuthState` is `authenticated` with `currentUser.username ==
  'bob'` and the screen's `username` is `'alice'`, no `FloatingActionButton` is
  present.
- Existing tests `T-04` and `T-05` are updated to supply the `AuthCubit` mock (with
  a non-owner auth state) so the harness compiles and the FAB does not interfere with
  navigation assertions.

### Prior art

The `user_details_screen_test.dart` demonstrates the `_MockAuthCubit` pattern
(`MockCubit<AuthState>`) and how `AuthAuthenticated` / `CurrentUser` fixtures are
constructed for widget tests. The same approach is applied here.

## Out of Scope

- Creating a new `CreatePostUseCase`, adapter, cubit, or port — all already exist in
  the `create_post` slice.
- Adding a "create post" entry point from the global Posts tab or from a user's
  profile detail screen — separate slices.
- Adding a `createPost` RBAC permission to the permission enum — ownership is
  enforced by the use-case, not by roles.
- Any changes to the Create Post screen itself (form fields, validation, success
  flow).
- Push notification or deep-link entry point for post creation.

## Further Notes

- This slice touches only the presentation layer of `user_posts` and the shared i18n
  files. No domain or data layer changes are required.
- Slang codegen (`dart run build_runner build`) must be run after adding the
  `fabTooltip` key; the generated translations file is committed alongside the JSON.
- The slice is complete when all four spec files exist and the implementation passes
  `dart analyze`, `dart format .`, and the affected widget tests.
