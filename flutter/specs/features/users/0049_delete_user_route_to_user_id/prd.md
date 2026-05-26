# PRD — 0049 delete_user_route_to_user_id

**Feature:** users
**Status:** 📋 needs-triage
**Part of:** `{username}` → `{user_id}` API migration (first breaking action-route slice)
**Depends on:** 0048 (`CurrentUser.id`) — hard prerequisite (the ownership guard compares
against the current user's id)

## Problem Statement

The backend removed `DELETE /user/{username}`; deleting a user now requires
`DELETE /user/{user_id}`. The Flutter client still sends the username string, so the
delete action returns 422/404. This flow is a **self-delete**: a user can delete only
their own account. The use-case enforces that by comparing the delete target against the
current user (`username != currentUsername → PermissionDenied`), and on success the cubit
performs a local logout (`forceLogout(notifyUser: false)`) because the server blacklists
the token. After the migration, both the target identifier *and* the ownership comparison
must move from username to id — and the comparison value (`currentUser.id`) only exists
once slice 0048 has landed.

## Solution

Migrate the delete-user vertical from username-as-identity to `user_id`, end to end and
without behavior change. The API method, port, adapter, use-case, cubit, and button all
switch their target identifier from `String username` to `int userId`. The ownership
guard stays in the use-case and becomes an id comparison (`userId != currentUserId`),
with `currentUserId` supplied by the cubit from `AuthCubit.currentUser.id`. The
confirmation dialog, the success logout + snackbar, the failure messages, and the
return to the users list are all unchanged.

Per `CONTEXT.md`, both the delete target and the ownership comparison are **path-identity**
values, so they migrate to id. No **handle** (`username` as a displayed/stored property)
is touched.

## User Stories

1. As a signed-in user, I want to delete my own account via the new id-based route, so
   that account deletion works against the new backend.
2. As a signed-in user, I want deletion of an account that is not mine to be refused by
   the use-case, so that the self-delete rule still holds after the migration.
3. As a signed-in user, I want a successful self-delete to log me out without a
   "session expired" message, so that I instead see the "account deleted" confirmation.
4. As a user, I want the confirmation dialog, success/return-to-list, and error messages
   to behave exactly as before, so that only the underlying identifier changed.
5. As a developer, I want the ownership guard to remain in the use-case and compare ids,
   so that the rule is enforced in the domain layer, not only in the UI.
6. As a developer, I want the delete port and adapter to accept `int userId`, so that the
   id-based contract is enforced at the layer boundary.
7. As a developer, I want the retrofit client to declare `DELETE /user/{user_id}` with an
   integer path parameter, so that the generated request hits the correct route.
8. As a developer, I want the cubit to source `currentUserId` from `CurrentUser.id` (with a
   non-matching sentinel when there is no current user), so that the guard denies safely
   when unauthenticated.
9. As a maintainer, I want the delete-user tests updated to the id contract — including
   the permission-denied branch — and a slice outside-in test that verifies the API is
   called with the integer id, so that the migration is provably correct without a live
   backend.

## Implementation Decisions

- **Module: Users API client (`deleteUser`).** `DELETE /user/{username}` with
  `String username` → `DELETE /user/{user_id}` with `int userId`. **Requires
  `build_runner`** to regenerate the retrofit client.
- **Module: `DeleteUserPort`.** `call(String username)` → `call(int userId)`.
- **Module: delete-user adapter.** Parameter and API call switch to `int userId`; the
  existing failure-mapping (401/403/404/default + catch-all with `logger.error`) is
  preserved unchanged.
- **Module: `DeleteUserUseCase` (guard stays here).** Signature
  `call({String username, String currentUsername})` →
  `call({int userId, int currentUserId})`; guard `userId != currentUserId →
  PermissionDenied`; on pass, delegates `_port(userId)`. The permission check is **not**
  moved to the UI (CLAUDE.md forbids UI-only permission checks) and **not** moved to the
  cubit.
- **Module: `DeleteUserCubit`.** `confirmAndDelete(...)` takes `int userId` and supplies
  `currentUserId: _authCubit.currentUser?.id ?? <non-matching sentinel, e.g. -1>`
  (mirroring today's `currentUser?.username ?? ''`). Success still calls
  `forceLogout(notifyUser: false)` then emits success; the state machine is otherwise
  unchanged. **This is the line that requires `CurrentUser.id` → hard dep on 0048.**
- **Module: delete button (presentation).** `DeleteAccountButton` takes `int userId`
  instead of `String username`, threaded to the inner widget and `confirmAndDelete`.
- **Cross-slice edit (in scope, surgical): user-details actions row.** The button is
  constructed inside `user_details_screen`'s shared actions row. Its construction site
  switches from passing `username` to passing the loaded user's `id`, selected from
  `UserDetailsCubit` state the same way `isModerator` already is. This temporarily yields
  a **mixed-key actions row** — delete by id, sibling buttons still by username — until
  the remaining route migrations land. Accepted, not a regression.
- **Behavior unchanged.** Self-delete only, logout-on-success, same dialog/messages/
  navigation. The migration is a pure identifier change (username → id) across the
  vertical and the guard.

## Testing Decisions

A good test asserts external behavior: that the delete vertical calls the API with the
correct **integer id**, that the guard refuses a non-matching id, and that success logs
out — not how the widgets are wired internally.

- **Use-case (unit):** with `userId == currentUserId`, delegates to the port with that id
  and returns Right; with `userId != currentUserId`, returns
  `Left(PermissionDenied)` and never calls the port. (Direct migration of the two existing
  use-case tests from username to id.)
- **Adapter (unit):** success path calls `deleteUser(<int>)`; 401/403/404 map to the
  correct `Failure`; an unexpected exception maps to `UnknownFailure` and calls
  `logger.error`.
- **Cubit (`bloc_test`):** request-confirmation; confirm→deleting→success (and that
  `forceLogout(notifyUser: false)` is invoked); confirm→deleting→failure; cancel — all
  driven with `int userId` and a stubbed `currentUser.id`.
- **Button (widget):** confirmation dialog appears; confirming triggers delete with the
  id; success shows the snackbar and navigates to the users list; failure shows the error.
- **Slice outside-in (acceptance gate):** wires real adapter+use-case+cubit, mocks the
  API client and `AuthCubit`, and `verify`s `deleteUser(<int>)` is called for the
  matching-id case — mirroring `test/features/tiers/0047_delete_tier_id_contract/`.
  Mocked at the API-client boundary; no live backend.
- **Prior art:** `test/features/tiers/0047_delete_tier_id_contract/` (id-contract outside-in
  shape, including a mocked `AuthCubit` providing `CurrentUser`);
  `test/features/posts/erase_db_post/data/erase_db_post_adapter_test.dart`
  (full failure-mapping + double-catch + `logger.error`).

## Out of Scope

- Migrating the sibling buttons in the user-details actions row (AssignModerator,
  UpdateUserTier, EditUser, EraseDbUser) — they stay username-keyed until their own slices.
- `user_details` route path / `@PathParam` migration — slice 0050.
- `AuthCubit.isMe` and any other route, port, or adapter outside the delete vertical.
- All Posts route migrations.
- Any change to the `username` handle, the logout/token behavior, or the self-delete rule
  itself.

## Further Notes

- This is the migration's first **breaking** slice and a deliberate cost-calibration
  point: a full vertical (API → port → adapter → use-case → cubit → widget), a
  `build_runner` regen, a domain-layer permission guard migrated to id, the 4-layer test
  re-green, and a cross-slice presentation edit. How mechanical this is feeds the
  reassessment gate.
- **Correction vs. the first draft of this PRD:** delete is self-delete with a use-case
  ownership guard and logout-on-success — it is *not* an admin delete, and it **does**
  depend on 0048 (the guard needs `CurrentUser.id`). The base order (0048 → 0049) already
  satisfies this; do not implement 0049 before 0048.
- The mixed-key actions row remains the clearest early signal that the user-details
  presentation is a shared surface several route migrations must each touch.
