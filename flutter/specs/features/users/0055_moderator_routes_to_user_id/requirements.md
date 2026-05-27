# 0055 · moderator_routes_to_user_id — Requirements

## Functional Requirements

| ID | Requirement |
|---|---|
| F1 | Promoting a user to moderator shall target `PATCH /user/{user_id}/assign-moderator` (singular `/user/`) with the viewed user's integer id. |
| F2 | Demoting a moderator shall target `PATCH /users/{user_id}/revoke-moderator` (plural `/users/`) with the viewed user's integer id. |
| F3 | An admin who manages moderators shall be able to promote and demote a user successfully against the id-based routes, no longer failing against the migrated backend. |
| F4 | The moderator button shall keep toggling its label between "Assign" and "Revoke" based on the viewed user's current moderator status. |
| F5 | A successful promote/demote shall update the button to its new state via the existing `isModerator` success callback, without a screen reload. |
| F6 | The in-flight loading spinner during a moderator request shall behave exactly as before the migration. |
| F7 | Moderator-request failures shall map to the same outcomes as before: 403 → forbidden, 404 → not-found, 409 → conflict, default → server, unexpected → unknown. |
| F8 | The moderator button shall remain hidden for a user without the manage-moderators permission. |
| F9 | While the viewed user's entity is still loading, the moderator button shall gate on permission and known moderator status only, no longer on a handle being present. |
| F10 | After this slice the user-details actions row shall be fully id-keyed, with no remaining handle-keyed action button. |
| F11 | No handle-keyed behavior shall change: the `@username` app-bar title, login, the create/edit-user form, and the username passed to post navigation remain as they are. |

## Non-functional Requirements

| ID | Requirement |
|---|---|
| N1 | `assignModerator` shall declare singular `PATCH /user/{user_id}/assign-moderator` and `revokeModerator` shall declare plural `PATCH /users/{user_id}/revoke-moderator`, each with an `int` `@Path('user_id')` parameter. |
| N2 | The plural `/users/` segment on revoke and the singular `/user/` segment on assign are intentional and load-bearing; neither shall be normalized to match the other. |
| N3 | `ModeratorManagementPort` shall declare both `assignModerator(int userId)` and `revokeModerator(int userId)`. |
| N4 | `AssignModeratorUseCase` and `RevokeModeratorUseCase` shall each accept `int userId` and delegate to the port with no guard and no identity comparison. |
| N5 | No identity comparison shall exist in the use-cases, so the slice has no dependency on slice 0048's `CurrentUser.id`; the permission rule lives in the UI gate and the backend superuser check. |
| N6 | The adapter shall pass the integer id to the API client for both methods while preserving the shared `_mapHttp` failure mapping (403/404/409/default) unchanged. |
| N7 | Each adapter method shall retain its catch-all `catch (e, st)` that logs via `logger.error` and returns `UnknownFailure`, per `agent_docs/error_handling.md`. |
| N8 | `AssignModeratorCubit.assign(...)` and `.revoke(...)` shall accept `int userId`; the `initial / loading / success(isModerator) / error` state machine shall remain unchanged. |
| N9 | `AssignModeratorState` shall remain unchanged; it carries only `isModerator` and no identifier. |
| N10 | `AssignModeratorButton` (and its inner widget) shall take `int userId` instead of `String username`, threading it through to the cubit's `assign`/`revoke` calls. |
| N11 | The user-details screen is the only cross-slice edit site; the button shall be constructed with the viewed user's id, its visibility gate keeping `canManageModerators && isModerator != null` and dropping `username != null`. |
| N12 | The now-orphaned `username` local in the user-details actions row shall be removed once the moderator button is id-keyed; the separate app-bar-title `username` shall remain. |
| N13 | The regenerated `users_api_client.g.dart` shall be produced via `build_runner`, never hand-edited. |
| N14 | No UI strings shall be hardcoded; all `users.moderator.*` strings continue to come from `slang` with no new keys added. |
| N15 | The slice shall not import another slice of the same feature; only `_shared/` is shared, and `domain/` shall not import Flutter/Dio. |
| N16 | A slice-level outside-in test shall verify, at the mocked `UsersApiClient` boundary, that `assignModerator(<int>)` and `revokeModerator(<int>)` are each called with the integer id, with no live backend. |
| N17 | The plural-revoke / singular-assign path correctness is not assertable through the mocked-method boundary and shall instead be enforced by the validation checklist and a manual network-log step. |
| N18 | The migration shall introduce no new failures in unrelated user/auth/routing tests (route-migration slices ripple; baseline before/after). |

## Out of scope

- Any backend change — the plural `/users/{user_id}/revoke-moderator` route is intentional and stays; this slice only aligns the Flutter client to it.
- The `username` handle anywhere: the `@username` app-bar title, login, the create/edit-user form, the username passed to `UserPostsRoute`, and any displayed `@username` label.
- The tier verticals (`get_user_tier`, `update_user_tier`) — migrated in slice 0054.
- The sibling actions-row buttons already migrated (delete, erase-db, edit).
- The manage-moderators permission rule (`canManageModerators`) and the backend superuser check — unchanged; only the identifier migrates.
- Roadmap status cleanup for stale `📋` rows (0049/0050, and 0054 once green).
