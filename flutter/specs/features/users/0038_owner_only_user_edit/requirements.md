# 0038 · owner_only_user_edit — Requirements

## Functional Requirements

| ID | Requirement |
|---|---|
| F1 | The edit button on the user details screen is visible only when the signed-in user's username matches the profile username (`isMe = true`). |
| F2 | The edit button is hidden when the signed-in user's username does not match the profile username, regardless of which permissions the signed-in user holds (including `editUsers`). |
| F3 | The edit button is hidden when the user is unauthenticated. |
| F4 | The edit button is hidden when the user is authenticated but `currentUser` is `null`. |
| F5 | The delete button, erase button, tier management control, and moderator assignment control retain their existing visibility rules and are unaffected by this change. |

## Non-functional Requirements

| ID | Requirement |
|---|---|
| N1 | The change is confined entirely to the presentation layer of the `user_details` slice; no domain, data, or application layer files are modified. |
| N2 | No new source files are created; the fix is a single-file modification of `user_details_screen.dart`. |
| N3 | The widget test suite for `UserDetailsScreen` must contain a test case asserting that a non-owner who holds `Permission.editUsers` does not see the edit button (regression guard for the exact bug described in the PRD). |
| N4 | The `canEdit` local variable must be removed from `build()` if it is no longer referenced after the fix; dead code is not permitted. |
| N5 | All user-visible strings remain routed through `slang`; no hardcoded UI strings are introduced. |
| N6 | The `user_details` slice does not import any other slice of the `users` feature; `_shared/` is the only permitted cross-slice dependency. |

## Out of scope

- No changes to the `edit_user` slice (use-case, adapter, cubit, screen).
- No API contract or HTTP endpoint changes.
- No changes to routing, route guards, or `AppRouter`.
- No changes to RBAC permission definitions or `PermissionCubit`.
- No changes to delete, erase, tier management, or moderator assignment controls.
