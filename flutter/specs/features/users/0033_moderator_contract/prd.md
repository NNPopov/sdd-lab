# PRD: moderator_contract (0033)

## Problem Statement

The backend now distinguishes moderators from regular users via an `is_moderator`
boolean on every user response. The Flutter client has no concept of this role: the
`User` entity, `CurrentUser` entity, and the permission system are unaware of it. As a
result, superusers cannot assign or revoke moderator status, moderator-only UI (pending
posts tab, moderation screen) cannot be gated correctly, and no badge is shown to
indicate that a user is a moderator.

## Solution

Extend the user data contract (`User` entity, `UserDto`, `CurrentUser`, `CurrentUserDto`)
to carry `isModerator`. Teach `PermissionCubit` to emit two new permissions —
`moderatePosts` (for moderators and superusers) and `manageModerators` (for superusers
only). Add two new API calls — assign moderator and revoke moderator — behind a new
use-case and adapter. Surface this in `user_details`: an `is_moderator` badge visible to
all users, and a toggle button (assign / revoke) visible only to superusers.

## User Stories

1. As any authenticated user, I want to see a moderator badge on a user's profile, so
   that I know at a glance who has moderation authority.
2. As a superuser, I want to see an "Assign Moderator" button on a regular user's
   profile, so that I can promote them to moderator.
3. As a superuser, I want to see a "Revoke Moderator" button on a moderator's profile,
   so that I can remove their moderation privileges.
4. As a superuser, I want the assign/revoke button to reflect the current moderator
   status immediately after the action succeeds, so that I don't need to refresh the
   page.
5. As a superuser, I want to see a loading indicator while the assign or revoke request
   is in flight, so that I know the action is being processed.
6. As a superuser, I want to see an error message if the assign or revoke request fails,
   so that I know the action did not go through.
7. As a superuser, I want a 409-conflict response (user is already a moderator / already
   not a moderator) to be surfaced as a readable error, so that I understand why the
   action was rejected.
8. As a moderator, I want the app to recognise my `is_moderator` flag so that I gain
   access to the moderation tab and moderation screen automatically on next login or
   session refresh.
9. As a developer, I want `Permission.moderatePosts` emitted for all moderators and
   superusers, so that the pending-posts tab and moderation screen can be gated on a
   single permission check.
10. As a developer, I want `Permission.manageModerators` emitted only for superusers, so
    that assign/revoke buttons are gated correctly.
11. As a developer, I want `isModerator` on `CurrentUser` so that `PermissionCubit` can
    derive the new permissions without additional API calls.
12. As a developer, I want `isModerator` on the `User` entity so that the user-details
    screen can render the badge and the assign/revoke button without knowing about
    `CurrentUser`.
13. As any user viewing a profile, I want the moderator badge to be absent when
    `is_moderator` is false, so that the UI stays uncluttered.
14. As a non-superuser authenticated user, I want the assign/revoke button to be
    invisible on any profile, so that I am never presented with an action I cannot
    perform.

## Implementation Decisions

### User entity and DTO

`User` gains a required `isModerator: bool` field. `UserDto` gains `is_moderator: bool`
with a `@Default(false)` soft-failure default (so old responses without the field
deserialise safely). The `UserDtoMapper.toDomain()` extension maps the field through.

### CurrentUser entity and DTO

`CurrentUser` gains `isModerator: bool`. `CurrentUserDto` gains `is_moderator: bool`
with `@Default(false)`. The `toDomain()` extension maps the field through. This is the
signal `PermissionCubit` reads to compute the new permissions.

### Permission enum additions

Two new values are added to the `Permission` enum:
- `moderatePosts` — grants access to the pending-posts tab, moderation screen, and the
  ability to call the moderate-post endpoint.
- `manageModerators` — grants access to the assign/revoke moderator button on user
  details.

### PermissionCubit update

`PermissionCubit._onAuthState()` is extended to handle the moderator case. The emission
logic becomes:

- `isSuperuser == true` → full admin permission set, which includes both
  `moderatePosts` and `manageModerators` (since admin receives all permissions).
- `isModerator == true` (and not superuser) → user permission set plus
  `moderatePosts`.
- Otherwise → existing logic unchanged.

`role_policy.dart` is not changed; the moderator case is handled inline in
`PermissionCubit` because `isModerator` is a per-user flag, not a static role.

### New API endpoints

Two new endpoints are added to `UsersApiClient`:
- `PATCH /user/{username}/assign-moderator` — no request body; 200 on success, 409 on
  conflict (already a moderator), 403 if caller is not a superuser.
- `PATCH /user/{username}/revoke-moderator` — no request body; 200 on success, 409 on
  conflict (not a moderator), 403 if caller is not a superuser.

### Domain port and adapter

A narrow port `IModeratorManagementPort` exposes two methods:
`assignModerator(String username)` and `revokeModerator(String username)`, both
returning `Either<Failure, void>`. A single adapter implements both, with the standard
double-catch error mapping (`DioException` → typed `Failure`; `Object` →
`Failure.unknown()` with `AppLogger`). A `ConflictFailure` (HTTP 409) is mapped to a
new typed `Failure` variant so the UI can show a specific message.

### Use-cases

`AssignModeratorUseCase` and `RevokeModeratorUseCase` delegate directly to the port.
They live in the domain layer with no Flutter dependencies.

### AssignModeratorCubit

A single cubit manages the assign/revoke interaction. States: `initial`, `loading`,
`success(bool isModerator)`, `error(Failure)`. On success, the cubit emits the new
`isModerator` value; the screen uses this to update the locally displayed `User`
without a full reload.

### User details screen changes

**Moderator badge:** displayed in the profile header alongside the username, visible to
all authenticated users when `user.isModerator == true`. Implemented as a small chip or
icon — not a separate widget file, inlined in `UserDetailsView`.

**Assign/revoke button:** a self-contained `AssignModeratorButton` widget, placed in
the AppBar actions next to the existing tier and edit buttons. Visible only when
`permissions.contains(Permission.manageModerators)`. The button label toggles between
"Assign Moderator" and "Revoke Moderator" based on the currently displayed user's
`isModerator` field. The `UserDetailsCubit` is not reloaded on success; instead,
`AssignModeratorCubit.success` carries the new boolean and the screen updates the local
`User` copy.

### Localisation

All new UI strings (badge label, button labels, error messages) are added via `slang`
JSON files. No hardcoded strings.

## Testing Decisions

Good tests assert on observable output — what state the cubit emits, what the widget
renders — not on internal method calls or DTO field names.

**Modules to test:**

- **UserDto mapping** — verify `is_moderator: true` and `is_moderator: false` map
  correctly to `User.isModerator`; verify missing `is_moderator` key defaults to
  `false`.
- **CurrentUserDto mapping** — same coverage as `UserDto`.
- **PermissionCubit** — verify: superuser emits `manageModerators` + `moderatePosts`;
  moderator (non-superuser) emits `moderatePosts` but not `manageModerators`; regular
  user emits neither. Prior art: `test/core/rbac/permission_cubit_test.dart`.
- **AssignModeratorAdapter** — cover: 200 success for assign, 200 success for revoke,
  403 → `ForbiddenFailure`, 409 → `ConflictFailure`, unexpected exception →
  `Failure.unknown()` with log. Prior art: adapter tests in
  `test/features/users/*/data/`.
- **AssignModeratorCubit** — cover: loading → success with correct `isModerator` value,
  loading → error on adapter failure. Prior art: `bloc_test`-based cubit tests in
  `test/features/users/*/application/`.
- **Widget test for AssignModeratorButton** — render with `manageModerators` permission
  present: button visible, label matches `isModerator` value; render without permission:
  button absent. Prior art: widget tests in `test/features/users/*/presentation/`.

## Out of Scope

- The pending-posts tab and its permission guard (slice C, `pending_posts`).
- The moderation screen and its `moderatePosts` permission gate (slice D,
  `moderate_post`).
- Any changes to post entities or post DTOs (slice A, `post_status_contract`).
- `GET /users/me` refresh triggered by role change — the client reflects the new state
  only after the next login or session refresh.

## Further Notes

- `PermissionCubit` listens to `AuthCubit.stream`, which already carries `CurrentUser`.
  Adding `isModerator` to `CurrentUser` is the only hook needed — no new stream or
  service is required.
- The moderator badge is intentionally shown to all users (public information), matching
  the decision made in the discovery interview.
- The 409 conflict case (already moderator / already not moderator) should be rare in
  normal use but must be handled gracefully since the button state could be stale if two
  superusers act simultaneously.
- Slices C (`pending_posts`) and D (`moderate_post`) depend on `Permission.moderatePosts`
  being defined and correctly emitted; this slice must be merged before them.
