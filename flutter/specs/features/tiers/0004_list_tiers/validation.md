# Validation: list_tiers

## Static checks

- [ ] `dart analyze` — zero errors in new and modified files
- [ ] `dart format --set-exit-if-changed lib/features/tiers/ lib/core/routing/guards/` — zero changes
- [ ] `dart run build_runner build` — completed without errors, `app_router.gr.dart` updated
- [ ] `dart run slang` — completed, generated files updated

## Architectural invariants

- [ ] `PermissionGuard` has no `@injectable`, `@lazySingleton`, or other DI annotations
- [ ] `AppRouter` creates `PermissionGuard` inline in `routes`, not via DI
- [ ] `list_tiers/` does not contain `domain/`, `data/`, `application/` — only `presentation/`
- [ ] `list_tiers/` does not contain a Cubit or BlocProvider
- [ ] `features/tiers/` does not import `features/users/` or other features
- [ ] `Permission.manageTiers` is present in `enum Permission`
- [ ] `role_policy.dart` and `PermissionCubit` are not modified

## Tests

- [ ] `permission_guard_test.dart` exists and contains >= 3 test cases
- [ ] `flutter test test/core/routing/guards/permission_guard_test.dart` — all green
- [ ] Verified: guard passes when permission is present
- [ ] Verified: guard blocks when permission is absent
- [ ] Verified: empty `_required` → pass through

## UX scenarios (manual verification)

### Scenario 1: Superuser opens `/tiers` directly
1. Log in as a superuser (`isSuperuser == true`)
2. Enter the path in the address bar (or call `router.pushPath('/tiers')`)
3. Expected: `TiersScreen` opened with AppBar "Tiers" / "Тиры"
4. Body contains placeholder text

### Scenario 2: Regular user cannot access `/tiers`
1. Log in as a regular user (`isSuperuser == false`)
2. Try to navigate to `/tiers` (via `router.pushPath('/tiers')` in code or the address bar on Web)
3. Expected: navigation is blocked, user remains on the current screen

### Scenario 3: Unauthenticated user
1. Log out
2. Try to navigate to `/tiers`
3. Expected: `AuthGuard` fires first, redirect to `/login`
4. `PermissionGuard` is not invoked

### Scenario 4: Verify that the navigation button is absent
1. Log in as a superuser
2. Inspect all screens in the app (user list, user details, etc.)
3. Expected: no button / menu item to navigate to "Tiers" anywhere

## Regression check

- [ ] Routes `list_users`, `create_user`, `user_details`, `edit_user` work without changes
- [ ] `AuthGuard` on the `edit_user` route works without changes
- [ ] Login / logout works without changes
- [ ] `PermissionCubit` correctly updates permissions after login (superuser receives all permissions)
