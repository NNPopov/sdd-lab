# 0054 · user_tier_routes_to_user_id — Requirements

## Functional Requirements

| ID | Requirement |
|---|---|
| F1 | The read of a user's current tier shall target `GET /user/{user_id}/tier` with the viewed user's integer id. |
| F2 | The update of a user's tier shall target `PATCH /user/{user_id}/tier` with the viewed user's integer id and the unchanged `{tier_id}` body. |
| F3 | A superuser shall be able to change another user's tier successfully against the id-based route, no longer receiving a 422. |
| F4 | The tier panel on the user-details screen shall load and display the viewed user's current tier via the id-based read route. |
| F5 | The tier bottom-sheet flow — open, fetch tiers, pick a tier, confirm, see the success snackbar, see the panel refresh — shall behave exactly as before the migration. |
| F6 | A non-superuser's tier-change attempt shall be refused with the same permission-denied outcome as before. |
| F7 | Read-path failures shall map to the same outcomes as before: 401 → unauthorized, 403 → forbidden, 404 → "Tier not assigned" not-found, default → network/server, unexpected → unknown. |
| F8 | Write-path failures shall map to the same outcomes as before: 401 → unauthorized, 403 → forbidden, 404 → not-found, default → server failure, unexpected → unknown. |
| F9 | The initial tier load on `UserDetailsLoaded` and the refresh after a successful tier update shall both use the viewed user's integer id. |
| F10 | The tier button's visibility shall gate on the edit-tier permission only, no longer requiring a handle to be present. |
| F11 | No handle-keyed behavior shall change: the `@username` title, the username passed to post navigation, and the moderator button's identifier remain as they are. |

## Non-functional Requirements

| ID | Requirement |
|---|---|
| N1 | `getUserTier` and `patchUserTier` shall declare singular `/user/{user_id}/tier` routes with an `int` `@Path('user_id')` parameter. |
| N2 | `GetUserTierPort` shall accept `int userId`, and `UpdateUserTierPort` shall accept `{int userId, int tierId}`. |
| N3 | `GetUserTierUseCase` shall accept `int userId` and delegate to its port with no guard. |
| N4 | `UpdateUserTierUseCase` shall accept `{int userId, int tierId, bool isSuperuser}` and keep the `isSuperuser` guard in the use-case, returning `PermissionDenied` for a non-superuser without calling the port. |
| N5 | The `isSuperuser` guard shall not compare identities, so the slice has no dependency on slice 0048's `CurrentUser.id`. |
| N6 | Both adapters shall pass the integer id to the API client while preserving their existing HTTP failure mapping unchanged. |
| N7 | Each adapter shall retain its catch-all `catch (e, st)` that logs via `logger.error` and returns `UnknownFailure`, per `agent_docs/error_handling.md`. |
| N8 | `GetUserTierCubit.load(...)` shall accept `int userId`; `UpdateUserTierCubit.submit(...)` shall accept `int userId`, sourcing `isSuperuser` from `AuthCubit` as before. |
| N9 | The `update_user_tier` state machine and the `get_user_tier` states shall remain unchanged; neither state carries an identifier. |
| N10 | `UpdateUserTierButton` and `UpdateUserTierSheet` (incl. inner submit call site) shall take `int userId` instead of `String username`. |
| N11 | The user-details screen is the only cross-slice edit site; the `username` local shall remain for `AssignModeratorButton` (slice 0055), leaving the accepted mixed-key actions row. |
| N12 | The regenerated `users_api_client.g.dart` shall be produced via `build_runner`, never hand-edited. |
| N13 | No UI strings shall be hardcoded; all tier and details strings continue to come from `slang` with no new keys added. |
| N14 | The slice shall not import another slice of the same feature; only `_shared/` is shared, and `domain/` shall not import Flutter/Dio. |
| N15 | A slice-level outside-in test shall verify, at the mocked `UsersApiClient` boundary, that `getUserTier(<int>)` and `patchUserTier(<int>, …)` are called with the integer id, with no live backend. |
| N16 | The migration shall introduce no new failures in unrelated user/auth/routing tests (route-migration slices ripple; baseline before/after). |

## Out of scope

- The moderator routes (`assignModerator` / `revokeModerator`) and the plural `/users/{user_id}/revoke-moderator` asymmetry — slice 0055.
- The `username` handle anywhere: the `@username` title, the username passed to `UserPostsRoute`, the create/edit-user form, login, and any displayed `@username` label.
- `getTiersForSelection` / the `fetch_tiers` half — `/tiers` carries no user identity.
- All Posts route migrations and any other route, port, or adapter outside the two tier verticals.
- The `tier_id` value itself (already an integer).
- Backend changes of any kind.
- Roadmap status cleanup for stale `📋` rows (0049/0050).
