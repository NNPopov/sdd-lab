# 0033 · moderator_contract — Validation Checklist

## Manual testing

| # | Step | Expected result |
|---|---|---|
| M1 | Log in as any authenticated user. Open the profile of a user whose `isModerator` flag is `true`. | A moderator badge is visible in the profile header. |
| M2 | Log in as any authenticated user. Open the profile of a user whose `isModerator` flag is `false`. | No moderator badge appears in the profile header. |
| M3 | Log in as a superuser. Open the profile of a user with `isModerator: false`. | An "Assign Moderator" button is visible in the AppBar actions. |
| M4 | Log in as a superuser. Open the profile of a user with `isModerator: true`. | A "Revoke Moderator" button is visible in the AppBar actions alongside the moderator badge. |
| M5 | Log in as a regular (non-moderator, non-superuser) user. Open any user profile. | No assign/revoke button appears in the AppBar. |
| M6 | Log in as a moderator (`isModerator: true`, `isSuperuser: false`). Open any user profile. | No assign/revoke button appears in the AppBar (moderators cannot manage other moderators). |
| M7 | As superuser, tap "Assign Moderator". Observe the AppBar while the request is in flight. | A circular loading indicator replaces the button until the response arrives. |
| M8 | As superuser, tap "Assign Moderator" on a regular user. Wait for a successful response. | The button label immediately changes to "Revoke Moderator" without the user-details page reloading. |
| M9 | As superuser, tap "Revoke Moderator" on a moderator. Wait for a successful response. | The button label immediately changes to "Assign Moderator" without the user-details page reloading. |
| M10 | As superuser, disable the network, then tap the assign or revoke button. | An error snackbar appears; the button returns to its previous label. |
| M11 | As superuser, trigger a 409 response (e.g. send the assign request for a user who is already a moderator via a proxy or a second superuser acting simultaneously). | The conflict snackbar message is displayed and is visibly distinct from the generic error text. |
| M12 | Trigger a 403 response via a proxy or test stub. | The forbidden snackbar message is displayed and is visibly distinct from the generic error text. |
| M13 | Log in as a moderator (`isModerator: true`, `isSuperuser: false`). | The pending-posts tab is visible and accessible (`Permission.moderatePosts` is active). |
| M14 | Log in as a regular user (`isModerator: false`, `isSuperuser: false`). | The pending-posts tab is not accessible; navigating to it directly is blocked by the permission guard. |
| M15 | Log in as a superuser. | Both the pending-posts tab is accessible AND the assign/revoke button is visible on user profiles. |
| M16 | As superuser, successfully assign moderator status to a user. Navigate away, then return to that user's profile. | The moderator badge is shown and the button reads "Revoke Moderator". |

## Code review

- [ ] `UserDto` has `@JsonKey(name: 'is_moderator') @Default(false) bool isModerator` — field deserialises safely when absent from JSON response.
- [ ] `CurrentUserDto` has `@JsonKey(name: 'is_moderator') @Default(false) bool isModerator` — same safe-deserialise default.
- [ ] `User` freezed factory includes `required bool isModerator`; no `@Default` on this field.
- [ ] `CurrentUser` includes `isModerator` in the `==` comparison and in `Object.hash(...)`.
- [ ] `UserDtoMapper.toDomain()` passes `isModerator: isModerator`.
- [ ] `CurrentUserDtoX.toDomain()` passes `isModerator: isModerator`.
- [ ] `Permission` enum contains `manageModerators`; no other enum or policy file is changed.
- [ ] `PermissionCubit._onAuthState()` has a moderator branch (`isModerator == true && isSuperuser == false`) that emits `{...kRolePolicy[UserRole.user]!, Permission.moderatePosts}`.
- [ ] The moderator branch does **not** include `Permission.manageModerators`.
- [ ] `role_policy.dart` is unmodified.
- [ ] `UsersApiClient` has `assignModerator(@Path username)` and `revokeModerator(@Path username)` annotated with `@PATCH`.
- [ ] `ModeratorManagementAdapter` has the double-catch pattern: inner `on DioException` maps HTTP codes; outer `on Object` calls `_logger.error` and returns `Failure.unknown()`.
- [ ] `_mapHttp` covers: 403 → `ForbiddenFailure`, 404 → `NotFoundFailure`, 409 → `ConflictFailure`, fallthrough → `ServerFailure`.
- [ ] `AssignModeratorState` has exactly four freezed variants: `initial`, `loading`, `success({required bool isModerator})`, `error(Failure failure)`.
- [ ] `ModeratorManagementAdapter` is annotated `@LazySingleton(as: ModeratorManagementPort)`.
- [ ] `AssignModeratorCubit` is annotated `@injectable` (not `@lazySingleton`).
- [ ] Domain files (`moderator_management_port.dart`, use-cases) contain no imports from `package:flutter` or `package:dio`.
- [ ] No file in `lib/features/users/moderator_contract/` imports any other slice of the `users` feature (only `_shared/` is allowed).
- [ ] `AssignModeratorButton` contains no `context.read<PermissionCubit>()` or `Permission` check — the parent screen controls its presence.
- [ ] `user_details_screen.dart` does not call `UserDetailsCubit.load` on `AssignModeratorState.success`.
- [ ] No hardcoded UI strings in any new Dart file — all text via `context.t.*` slang keys.
- [ ] `dart run build_runner build --delete-conflicting-outputs` — no errors
- [ ] `dart run slang` — no errors
- [ ] `dart analyze` — no warnings
- [ ] All tests green
