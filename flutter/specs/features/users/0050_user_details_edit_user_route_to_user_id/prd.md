# PRD — 0050 user_details_edit_user_route_to_user_id

**Feature:** users
**Status:** 📋 needs-triage
**Part of:** `{username}` → `{user_id}` API migration (combined navigated-route slice)
**Depends on:** 0048 (`CurrentUser.id`) — hard prerequisite
**See:** `docs/adr/0001-merge-user-details-and-edit-user-route-migration.md`

## Problem Statement

The backend moved the user read and update routes from `/user/{username}` to
`/user/{user_id}`. Viewing a user and editing a user both fail (422/404) because the
client still puts the username string in the URL. These two flows cannot be migrated
separately: they share the `getUser` API method, so changing it for one breaks the other.
On top of the API change, the in-app deep-link paths (`user/:username`,
`user/:username/edit`) and every place that navigates to them still pass a username.

## Solution

Migrate the user-details and edit-user verticals together, in one slice and one commit, so
the shared `getUser` endpoint never sits in a half-migrated state. The two app route paths
become id-based (`user/:user_id`, `user/:user_id/edit`), their page params become
`int userId`, and the read/update API calls, ports, use-cases, and cubits switch their
target identifier to `int`. Ownership is decided by id (`isMe(int)`). All user-facing
behavior — what the detail screen shows, the owner-only edit guard, the edit form, the
PATCH semantics — is unchanged.

This is the migration's clearest application of the `CONTEXT.md` rule: in `edit_user`,
the identity that selects *which* user to read/patch migrates to id, while the
`username` the user types into the edit form (the **handle** in the PATCH body) stays a
string. The two code slices stay structurally separate (two cubits, two route pages); only
the work unit and commit are shared.

## User Stories

1. As a user, I want to open a user's detail screen via an id-based URL, so that the
   detail data loads from the new backend route.
2. As a user, I want the detail screen to show exactly the same information as before, so
   that only the underlying identifier changed.
3. As the owner of a profile, I want to open the edit screen via an id-based URL, so that
   editing works against the new route.
4. As a non-owner, I want to be blocked from editing someone else's profile by id
   comparison, so that the owner-only rule still holds after the migration.
5. As the owner, I want to change my displayed username (handle) in the edit form and save
   it, so that renaming still works — the handle is sent in the request body, not the URL.
6. As a user, I want the edit save to target my account by id, so that the PATCH reaches
   the correct user on the new route.
7. As a user, I want navigation from the users list, the user menu ("my profile"), and the
   detail screen's edit button to pass the id, so that every entry point opens the
   id-based routes.
8. As a user, I want links from the detail screen to a user's posts to keep working, so
   that the not-yet-migrated posts routes still receive what they expect.
9. As a developer, I want `AuthCubit.isMe` to compare by id, so that ownership is decided
   by identity rather than by the handle string.
10. As a developer, I want the read and update API methods declared with an integer
    `user_id` path parameter, so that generated requests hit the correct routes.
11. As a developer, I want the detail and edit page params declared as `int userId` via
    `@PathParam('user_id')`, so that auto_route parses the id from the URL.
12. As a maintainer, I want the owner-only edit outside-in test and a combined slice
    outside-in test that verify read/update are called with the integer id, so that the
    migration is provably correct against mocked APIs.

## Implementation Decisions

- **Routing (`core/routing`, in scope):** in `app_router.dart`, change exactly two path
  strings — `user/:username` → `user/:user_id` (UserDetailsRoute) and
  `user/:username/edit` → `user/:user_id/edit` (EditUserRoute). Sibling
  `user/:username/posts...` paths are independent declarations and are **not** touched.
- **Route pages:** `UserDetailsPage` and `EditUserPage` change
  `@PathParam('username') String username` → `@PathParam('user_id') int userId`.
- **Users API client:** `GET /user/{username}` (`getUser`) and `PATCH /user/{username}`
  (`updateUser`) → id-based path with `int userId` path parameter. The `updateUser`
  **body is unchanged** (it still carries the handle). **Requires `build_runner`** (both
  the retrofit client and the auto_route `app_router.gr.dart`).
- **user_details vertical:** `GetUserPort`/adapter, `UserDetailsCubit.load(...)`, and
  `UserDetailsScreen` switch their target to `int userId`; the screen loads by id and
  reads the rest from the returned `User`.
- **edit_user vertical:** `GetUserForEdit` use-case/adapter and
  `EditUserCubit.loadInitial(...)` switch to `int userId`. `isMe(username)` →
  `isMe(userId)`. In `update_user_adapter`, the PATCH **path** identity
  (`original.username`) → `original.id`; the **body** `username` (the new handle) and the
  result-building `username` are left exactly as they are.
- **`AuthCubit.isMe` (core/auth):** `isMe(String)` → `isMe(int userId)` comparing
  `currentUser?.id == userId`. Sole caller is `EditUserCubit.loadInitial`. This is why
  **0048 is a hard prerequisite**.
- **Action-visibility ownership gate (presentation):** `UserActionVisibility.from(...)`
  computes its **own** inline ownership check — today `isMe = currentUser?.username ==
  username`, driving `showEdit` and `showDelete`. This is a *second* identity comparison
  (independent of `AuthCubit.isMe`) and must migrate to `currentUser?.id == userId`. The
  factory's `username` parameter and the `_UserDetailsAppBarActions(username:)` widget it
  is called from both switch to `int userId`. Also needs `CurrentUser.id` (0048). The
  permission-derived flags (`showErase`, `canEditTier`, `canManageModerators`) are
  unaffected.
- **`updateUser` failure surface:** the update adapter maps **five** HTTP codes —
  401/403/404/409 (conflict)/422 (field validation) — plus the catch-all. The migration
  preserves all of them unchanged; only the path identity changes.
- **Navigation call sites (in scope):** `UserDetailsRoute` and `EditUserRoute`
  constructions switch to `userId`:
  - users list → `UserDetailsRoute(userId: user.id)`.
  - `app_shell` user menu "my profile" → `UserDetailsRoute(userId: currentUser.id)`
    (**core file `app_shell_screen.dart`, in scope; needs `CurrentUser.id`**).
  - detail screen edit button → `EditUserRoute(userId: loadedUser.id)`, and its result
    handling re-loads by id.
- **Handle bridges (temporary, accepted):** because posts routes and the sibling
  user-action buttons (moderator/tier/erase, and the user-posts link) are not yet
  migrated, the re-keyed detail screen sources their `username` from the **loaded `User`
  entity's handle**, and the user menu's "my posts" keeps using `currentUser.username`.
  This yields a mixed id/handle surface until later slices, by design.
- **Combined, not merged code:** `UserDetailsCubit` and `EditUserCubit`, their ports,
  adapters, and screens remain separate. Only the spec, commit, and acceptance gate are
  shared (per ADR-0001).

## Testing Decisions

A good test asserts external behavior — that read/update hit the API with the correct
integer id, and that owner-only access is decided by id — not internal wiring.

- **Adapters (unit):** `getUser(<int>)` and `updateUser(<int>, body)` on success;
  `getUser` failure mapping (401/403/404/default) and `updateUser`'s full mapping
  (401/403/404/409/422 + default) preserved, with the catch-all `logger.error`.
- **Action visibility (unit):** `UserActionVisibility.from(...)` returns `isMe`/
  `showEdit`/`showDelete` true when `currentUser.id == userId`, false otherwise — the
  migrated equivalent of the existing `user_action_visibility_test`.
- **Use-cases (unit):** read-for-edit and update delegate with the integer id; update
  passes the unchanged body (handle) through.
- **Cubits (`bloc_test`):** `UserDetailsCubit` load-by-id transitions; `EditUserCubit`
  `loadInitial` — including the `isMe(id)` forbidden branch — and `submit` transitions.
- **Widgets:** detail screen renders by id; edit screen guards non-owners and submits.
- **`isMe` (unit):** `AuthCubit.isMe(id)` true for the current user's id, false otherwise.
- **Acceptance gates:**
  - Update the existing owner-only outside-in test
    (`test/features/users/0038_owner_only_user_edit/...`) to express ownership by id —
    this is the contract for the `isMe` change and is updated *first*.
  - A combined slice outside-in test that wires real adapters+use-cases+cubits, mocks the
    API client, and `verify`s `getUser(<int>)` and `updateUser(<int>, body)` — mirroring
    `test/features/tiers/0047_delete_tier_id_contract/`. No live backend.
- **Downstream re-green (largest in the base):** detail/edit cubit, adapter, screen, and
  action-visibility tests, plus the routing/navigation tests
  (`app_shell_screen_test`, `tab_navigation_test`, `tab_root_reset_test`,
  `users_screen_test`) that construct these routes — all updated from username to id.

## Out of Scope

- All Posts route migrations (UserPosts, PostDetails, CreatePost, EditPost, ErasePost) and
  their `:username` paths — both the Posts-tab and Users-tab posts paths stay as-is.
- The sibling user-action buttons (AssignModerator, UpdateUserTier, EraseDbUser) and
  GetUserTier — separate slices; they keep the handle for now.
- Any change to the `username` handle itself (login, `@username` display, the edit form
  field, the PATCH body), or to `AuthSession`.
- `delete_user` (slice 0049).

## Further Notes

- This is the heaviest base slice: two verticals, **two** ownership comparisons migrated
  to id (`AuthCubit.isMe` and the inline `UserActionVisibility` check), two route path
  changes, `build_runner` for both generators, several core touches, and the biggest
  test re-green. Its real cost is the decisive input to the reassessment gate — if even
  this slice was mechanical once the id sources were identified, the remaining (easier,
  `createdByUserId`-equipped) posts routes are a strong candidate to batch.
- **Correction after re-reading the implementation:** an initial draft of this PRD named
  only `AuthCubit.isMe`. There is a second, independent ownership comparison inside
  `UserActionVisibility` (`currentUser.username == username`) that gates the edit/delete
  buttons; it also migrates to an id comparison and also needs `CurrentUser.id` (0048).
  The use-cases on the edit path (`update_user`, `get_user_for_edit`) carry **no** hidden
  ownership guard — the only edit-path guard is `isMe` in `EditUserCubit.loadInitial`.
- The mixed id/handle surface on the detail screen is expected and temporary; it
  disappears as the remaining user-action and posts slices migrate.
