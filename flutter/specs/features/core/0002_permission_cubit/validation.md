# 0002 · PermissionCubit — Validation Checklist

## Data / DTO

- [ ] `CurrentUserDto.isSuperuser` deserializes from `is_superuser` (already exists — verify not broken)
- [ ] `CurrentUser.isSuperuser` is present in the domain entity (already exists — verify)

## PermissionCubit — Logic

- [ ] Initial state = guest permissions (before the first auth event)
- [ ] `isSuperuser == true` → all permissions (`Permission.values`)
- [ ] `isSuperuser == false` → regular user permissions (`viewCatalog`, `viewReports`)
- [ ] Logout → returns to guest permissions
- [ ] `has(Permission.editUsers)` for superuser = `true`
- [ ] `has(Permission.editUsers)` for regular user = `false`
- [ ] `_sub.cancel()` is called in `close()` (no memory leak)

## DI

- [ ] `PermissionCubit` is registered in `injection.config.dart` (after codegen)
- [ ] `getIt<PermissionCubit>()` returns an instance without errors

## Widget tree

- [ ] `BlocProvider<PermissionCubit>` is added to `main.dart`
- [ ] `context.read<PermissionCubit>()` is accessible on the `UserDetailsScreen`

## UserDetailsScreen — UI

- [ ] Superuser sees Edit / Delete / EraseDb buttons on another user's profile
- [ ] Regular user does NOT see buttons on another user's profile
- [ ] Regular user sees buttons on their own profile (isMe)
- [ ] Logout hides buttons (reactively, without a page reload)

## Tests

- [ ] `permission_cubit_test.dart` — all 5 scenarios green
- [ ] Test for `close()` — no exceptions, subscription cancelled

## Not affected

- [ ] `list_users` slice — not modified
- [ ] `create_user` slice — not modified
- [ ] `edit_user` slice — not modified
- [ ] `delete_user` slice — not modified
- [ ] `kRolePolicy` — not modified
- [ ] `CurrentUserDto` — not modified (only presence of field verified)
- [ ] `AuthCubit` — not modified
