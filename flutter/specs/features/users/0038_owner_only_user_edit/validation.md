# 0038 · owner_only_user_edit — Validation Checklist

## Manual testing

| # | Step | Expected result |
|---|---|---|
| M1 | Log in as **alice**. Navigate to alice's own profile (`/user/alice`). | Edit button (pencil icon) is visible in the app bar. |
| M2 | Log in as **alice**. Navigate to **bob's** profile (`/user/bob`). | Edit button is **not** visible in the app bar. |
| M3 | Log in as a user who holds the `editUsers` permission (e.g. an admin). Navigate to any **other** user's profile. | Edit button is **not** visible — the permission does not grant the edit affordance on another user's profile. |
| M4 | Log out completely. Navigate to any user profile. | Edit button is not visible. No other action buttons (delete, erase) appear for a profile the guest does not own. |
| M5 | Log in as **alice**. Navigate to alice's profile. | Both the edit button **and** the delete button are visible. No regression in owner controls. |
| M6 | Log in as a user with `eraseUsers` permission who is **not** the profile owner. Navigate to another user's profile. | Erase button is visible (existing rule unchanged); edit button is **not** visible. |
| M7 | Log in as **bob** (non-owner). Manually type `/user/alice/edit` in the address bar and navigate. | The edit form may open (no route guard blocks it), but attempting to save changes returns a 403 error from the backend — owner-only save enforcement is intact. |

## Code review

- [ ] `user_details_screen.dart` line that previously read `final showEdit = isMe || canEdit` now reads `final showEdit = isMe`.
- [ ] The `canEdit` local variable is absent from `user_details_screen.dart`, or — if it remains — it is referenced by at least one condition other than `showEdit` (no dead code).
- [ ] No files under `lib/features/users/user_details/domain/`, `data/`, or `application/` appear in the diff.
- [ ] No new files are created anywhere in the `lib/` or `test/` tree for this change.
- [ ] `test/features/users/user_details/presentation/user_details_screen_test.dart` contains a test case that sets `permissionCubit.state` to `{Permission.editUsers}` with a non-owner `authCubit.state`, and asserts `find.byIcon(Icons.edit)` finds nothing.
- [ ] `user_details_screen.dart` contains no hardcoded UI strings — all user-visible text is routed through `context.t.*`.
- [ ] `grep` of `import.*features/users/` inside `lib/features/users/user_details/` shows only `_shared/` imports — no sibling slice imports.
- [ ] `dart run build_runner build --delete-conflicting-outputs` — no errors
- [ ] `dart run slang` — no errors
- [ ] `dart analyze` — no warnings
- [ ] All tests green
