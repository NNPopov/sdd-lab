# PRD — 0055 moderator_routes_to_user_id

**Feature:** users
**Status:** 📋 needs-triage
**Part of:** `{username}` → `{user_id}` API migration (moderator action routes — second and
final user-action slice of the migration gap deferred by 0049)
**Depends on:** none. The moderator use-cases do **not** compare identity (assign/revoke are
gated by the `canManageModerators` permission in the UI and a superuser check on the
backend), so there is **no** dependency on slice 0048 (`CurrentUser.id`). Follows the
verified 0054 as its near-identical template.

## Problem Statement

The backend migrated the moderator routes from `{username}` to `{user_id}`:
`PATCH /user/{user_id}/assign-moderator` (singular `/user/`) and
`PATCH /users/{user_id}/revoke-moderator` (plural `/users/` — intentional). The Flutter
client still sends the username string, so promoting or demoting a moderator from the
user-details screen fails against the migrated backend (FastAPI rejects the string in an
`int` path with 422, or misses the route entirely). The revoke action is doubly wrong: the
client path is still both username-keyed **and** singular (`/user/{username}/revoke-moderator`),
while the backend route is id-keyed and plural.

This is the last un-migrated user-action vertical — the moderator routes that the 0049
PRD's "Out of Scope" explicitly deferred "until their own slices." With 0054 (the tier
routes) green, this slice closes the gap.

## Solution

Migrate the `moderator_contract` vertical from username-as-identity to `int user_id`, end
to end and **without behavior change**. The two API client methods, the shared
`ModeratorManagementPort` (both methods), the single adapter (both methods), the two
use-cases, the `AssignModeratorCubit` (both `assign` and `revoke`), and the
`AssignModeratorButton` all switch their target identifier from `String username` to
`int userId`.

The client mirrors the backend paths **verbatim, including the intentional asymmetry**:
`assignModerator` stays singular `PATCH /user/{user_id}/assign-moderator`, while
`revokeModerator` becomes plural `PATCH /users/{user_id}/revoke-moderator`. The
assign/revoke toggle, the `isModerator` success callback that updates the parent, the
loading spinner, and the error snackbars (`403 → forbidden`, `404 → not-found`,
`409 → conflict`, default → server) are all unchanged.

Per `CONTEXT.md`, the value passed into `assignModerator(...)` / `revokeModerator(...)` is
**path-identity** — it names *which* user is being promoted/demoted, is only fed to the API
call, and is never displayed or stored as a handle — so it migrates cleanly to `int`. No
**handle** is touched: the `@username` title, login, the create/edit-user form, the
post-navigation `username`, and any displayed `@username` label all stay.

Cross-slice, the `AssignModeratorButton` construction site in the shared
`user_details_screen` actions row switches from passing `username` to passing the viewed
user's `id`, and its visibility gate drops the `username != null` clause while keeping
`canManageModerators && isModerator != null` (the button still needs `isModerator` to know
whether to show *assign* or *revoke*). Because the moderator button was the **last**
consumer of the actions-row `username` local that 0054 deliberately kept, that local now
has no remaining reader and is removed — so this slice resolves the accepted **mixed-key**
actions row (introduced by 0049, carried by 0054) into a **fully id-keyed** row. The
app-bar title's `username` (the display handle, in a different scope) is unaffected.

## User Stories

1. As an admin who manages moderators, I want to promote a user to moderator via the new
   id-based route, so that assigning a moderator works against the migrated backend.
2. As an admin who manages moderators, I want to demote a moderator via the new id-based
   **plural** route, so that revoking a moderator works against the migrated backend.
3. As an admin, I want the assign/revoke button to keep toggling between "Assign" and
   "Revoke" based on the user's current moderator status, so that only the underlying
   identifier changed.
4. As an admin, I want a successful promote/demote to update the button to its new state
   via the existing `isModerator` callback, so that the screen reflects the change without
   a reload.
5. As an admin, I want the loading spinner during the in-flight request to behave exactly
   as before, so that the migration is invisible in the UI.
6. As an admin, I want a forbidden (403), not-found (404), conflict (409), or server error
   to surface the same snackbar messages as before, so that failure handling is unchanged.
7. As a user without the manage-moderators permission, I want the moderator button to
   remain hidden, so that the permission gate is unchanged by the migration.
8. As a user viewing a profile whose entity is still loading, I want the moderator button
   to gate on permission and known moderator status only (no longer on a handle being
   present), matching the migrated tier and delete buttons.
9. As a developer, I want the retrofit client to declare
   `PATCH /user/{user_id}/assign-moderator` (singular) and
   `PATCH /users/{user_id}/revoke-moderator` (plural) with `int` path parameters, so that
   the generated requests hit the correct routes and the intentional asymmetry is
   preserved.
10. As a developer, I want `ModeratorManagementPort` (both methods) and the adapter (both
    methods) to accept `int userId`, so that the id-based contract is enforced at the layer
    boundary while the HTTP failure mapping is preserved unchanged.
11. As a developer, I want both use-cases to delegate `int userId` to the port with no
    identity comparison, so that the slice has no dependency on `CurrentUser.id` (slice
    0048).
12. As a developer, I want `AssignModeratorCubit.assign(...)` and `.revoke(...)` to accept
    `int userId`, so that the application layer drives the network with the integer id.
13. As a developer, I want `AssignModeratorButton` to take `int userId` instead of
    `String username`, so that the only cross-slice edit is the construction site in the
    user-details actions row.
14. As a maintainer, I want the now-orphaned `username` local in the user-details actions
    row removed once the moderator button is id-keyed, so that the actions row is fully
    id-keyed and no dead local remains.
15. As a maintainer, I want the existing moderator tests (0033) migrated to the id contract
    and a slice outside-in test that verifies the API is called with the integer id for
    both assign and revoke, so that the migration is provably correct without a live
    backend.
16. As a maintainer, I want the singular/plural asymmetry documented in the plan so that no
    later refactor "tidies" the revoke route back to singular.

## Implementation Decisions

- **Module: Users API client (`assignModerator`, `revokeModerator`).** Both migrate from
  `String username` to `int userId`. `assignModerator` keeps the **singular**
  `/user/{user_id}/assign-moderator`; `revokeModerator` moves to the **plural**
  `/users/{user_id}/revoke-moderator`. **Requires `build_runner`** to regenerate the
  retrofit client. Only these two methods change; no other client method is touched.
- **Module: `ModeratorManagementPort`.** Both methods —
  `assignModerator(...)` and `revokeModerator(...)` — take `int userId`.
- **Module: `ModeratorManagementAdapter`.** Both methods pass the `int userId` to the
  client; the shared HTTP failure mapping (`403 → forbidden`, `404 → not-found`,
  `409 → conflict`, default → server) and the per-method catch-all `catch (e, st)` with
  `logger.error` are preserved unchanged.
- **Module: `AssignModeratorUseCase` / `RevokeModeratorUseCase`.** Each becomes
  `call(int userId)` — pure delegation to the port, no guard, no identity comparison. This
  is why the slice has **no 0048 dependency**; the manage-moderators permission is enforced
  by the UI visibility gate and the backend superuser check, not by the use-case.
- **Module: `AssignModeratorCubit`.** `assign(...)` and `revoke(...)` take `int userId`.
  The state machine (`initial / loading / success(isModerator) / error`) is unchanged; the
  success state still carries the resulting `isModerator` boolean.
- **Module: `AssignModeratorButton` (presentation).** Takes `int userId` instead of
  `String username`, threaded through the inner widget to the cubit's `assign`/`revoke`
  calls. The button still creates its own cubit via `getIt` (`BlocProvider(create: …)`),
  unchanged.
- **Cross-slice edit (in scope, surgical): user-details actions row.** Construct
  `AssignModeratorButton` with the viewed user's `id` (selected from `UserDetailsCubit`
  state, the same source as `isModerator`). The visibility gate drops the `username != null`
  clause, keeping `canManageModerators && isModerator != null`. Remove the now-orphaned
  `username` local in the actions-row widget (its last consumer is gone), leaving the row
  **fully id-keyed**. The app-bar title's `username` (display handle) stays.
- **Asymmetry is load-bearing.** The plural `revoke` segment is intentional and pinned by
  the backend (`api/.../revoke_moderator/.../router.py`). Document it in `plan.md`. Do
  **not** change the backend and do **not** normalize revoke to singular.
- **Behavior unchanged.** Toggle, callback, spinner, snackbars, permission gate — all
  identical. The migration is a pure identifier change (username → id) across the vertical
  plus the one cross-slice construction site.

## Testing Decisions

A good test asserts **external behavior**: that the moderator vertical calls the API with
the correct **integer id** for *both* assign and revoke, that the cubit emits the right
state sequence, and that the button toggles — not how the widgets are wired internally. One
honest limitation to record: because tests mock at the `UsersApiClient` method boundary,
they can verify `revokeModerator(<int>)` is *called with the integer id* but **cannot**
observe the actual URL path string (singular vs plural lives in the generated Dio code).
The plural-revoke / singular-assign path correctness is therefore enforced by the
code-review checklist (`validation.md`) and a manual network-log step, not by a mocked-test
assertion.

- **Use-cases (unit), both:** `assignModerator`/`revokeModerator` delegate the given
  `int userId` to the port and pass its `Right`/`Left` result straight through (no guard).
  Direct migration of the two existing 0033 use-case tests from username to id.
- **Adapter (unit), both methods:** success calls `assignModerator(<int>)` /
  `revokeModerator(<int>)` and returns `Right`; `403 → Forbidden`, `404 → NotFound`,
  `409 → Conflict`, default → `ServerFailure`; an unexpected (non-Dio) exception maps to
  `UnknownFailure` **and** verifies `logger.error` (the outer catch-all). All driven with an
  `int` id.
- **Cubit (`bloc_test`):** `assign(<int>)` → `[loading, success(isModerator: true)]`;
  `revoke(<int>)` → `[loading, success(isModerator: false)]`; failure →
  `[loading, error(<Failure>)]`. Driven with `int userId`.
- **Button (widget):** built with `userId:`; when `isModerator` is false the button shows
  "Assign" and tapping triggers `assign(<int>)`; when true it shows "Revoke" and tapping
  triggers `revoke(<int>)`; the in-flight loading spinner renders; an error state shows the
  snackbar. Mocked cubit injected via `getIt.registerFactory` + `unregister` in tear-down
  (the button creates its cubit through `getIt`).
- **Slice outside-in (acceptance gate):** wires the real adapter + both use-cases + cubit,
  mocks the `UsersApiClient`, and `verify`s `assignModerator(<int>)` and
  `revokeModerator(<int>)` are each called with the integer id — mocked at the API-client
  boundary, no live backend.
- **Prior art:** the existing `test/features/users/0033_moderator_contract/` suite
  (use-case, adapter, cubit, button, and outside-in — migrated in place from username to
  id); the just-verified `test/features/users/0054_user_tier_routes_to_user_id/` outside-in
  test (id-contract shape, mocked at `UsersApiClient`); the 0033 button test for the
  `getIt`-provided-cubit widget pattern.

## Out of Scope

- **Any backend change** — the plural `/users/{user_id}/revoke-moderator` route is
  intentional and stays; this slice only aligns the Flutter client to it.
- **Any `username` handle** — the `@username` title, login, the create/edit-user form, the
  username passed to `UserPostsRoute`, and any displayed `@username` label.
- The tier verticals (`get_user_tier`, `update_user_tier`) — migrated in slice 0054, done.
- The sibling actions-row buttons already migrated (delete, erase-db, edit) — untouched.
- The manage-moderators **permission rule** itself (`canManageModerators`) and the backend
  superuser check — unchanged; only the identifier migrates.
- Roadmap status cleanup for the stale `📋` rows (0049/0050, and 0054 once green) — separate
  bookkeeping, not part of this slice.

## Further Notes

- This is the near-identical sibling of the verified 0054 and the **final** user-action
  route migration; reuse 0054's pipeline (`/feature-spec` → `/feature-requirements` →
  `/feature-validation` → `/feature-tests` → `/slice-test-red`, then implement to green,
  then re-green the 4-layer tests) and its outside-in shape.
- The one structural difference from 0054: a **single** port/adapter/cubit/button serves
  **both** assign and revoke (two methods on one port), rather than two separate verticals.
  Plan and tests must cover both methods.
- The revoke route is corrected on **two axes** at once (username → id *and* singular →
  plural). The validation checklist must explicitly assert the plural segment so a future
  refactor cannot silently normalize it.
- After this slice the user-details actions row is fully id-keyed — the disappearance of
  the actions-row `username` local is the concrete signal that the action-route migration
  gap deferred by 0049 is finally closed.
