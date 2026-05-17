# Plan: list_tiers

## Task

Create a skeleton slice `list_tiers` in the new feature `tiers`.
Result: a `/tiers` route accessible only to superusers via
`PermissionGuard({Permission.manageTiers})`. The screen is a stub with no data.
In parallel: implement `PermissionGuard` in `core/routing/guards/`.

---

## CONTEXT

**READ:**
- `CLAUDE.md` in full
- `lib/core/auth/infrastructure/auth_guard.dart` — reference implementation for `PermissionGuard`
- `lib/core/rbac/permission.dart` — add `manageTiers` here
- `lib/core/rbac/permission_cubit.dart` — understand how the isSuperuser → admin mapping works
- `lib/core/routing/app_router.dart` — add the route and `PermissionCubit` to the constructor here
- `lib/main.dart` — pass `permissionCubit` when creating `AppRouter` here
- `lib/features/users/list_users/presentation/users_route.dart` — reference route file
- `lib/features/users/list_users/presentation/users_screen.dart` — reference screen file
- `.claude/skills/flutter-implementing-navigation-and-routing/SKILL.md`

**DO NOT READ:**
- `lib/features/users/**` — except the reference files listed above
- `lib/features/auth/**`
- `**/*.gr.dart`, `**/*.config.dart`, `**/*.freezed.dart`, `**/*.g.dart`

---

## API

None. This slice is pure routing infrastructure with no HTTP requests.

---

## Target structure

```
lib/core/routing/guards/
└── permission_guard.dart            # NEW: reusable guard, not @injectable

lib/features/tiers/
└── list_tiers/
    └── presentation/
        ├── list_tiers_route.dart    # @RoutePage() + empty StatelessWidget wrapper
        └── list_tiers_screen.dart   # StatelessWidget — AppBar + placeholder body

Modified existing files:
- lib/core/rbac/permission.dart           — add manageTiers
- lib/core/routing/app_router.dart        — add permissionCubit to constructor + /tiers route
- lib/main.dart                           — pass permissionCubit when creating AppRouter
- lib/core/i18n/i18n/strings.en.json      — keys tiers.listTiers.*
- lib/core/i18n/i18n/strings.ru.json      — keys tiers.listTiers.*
```

**Note on structure:** `list_tiers/` contains only `presentation/` —
no API, no domain/data/application, no Cubit. These will be added in future slices.

---

## What to do

### 1) CORE/RBAC — add Permission.manageTiers

File: `lib/core/rbac/permission.dart`

Add at the end of the enum:
```dart
manageTiers,
```

**IMPORTANT:** `PermissionCubit` already maps `isSuperuser → UserRole.admin → {...Permission.values}`.
Adding a new value to the enum automatically makes it available to superusers
without any changes to `PermissionCubit` or `role_policy.dart`.

### 2) CORE/ROUTING — create PermissionGuard

File: `lib/core/routing/guards/permission_guard.dart` (NEW)

```dart
import 'package:auto_route/auto_route.dart';
import 'package:flutter_application_1/core/rbac/permission.dart';
import 'package:flutter_application_1/core/rbac/permission_cubit.dart';

/// Guard for routes that require a specific set of permissions.
/// NOT a DI singleton — parameterized with a permission set,
/// created in AppRouter for each route separately.
class PermissionGuard extends AutoRouteGuard {
  PermissionGuard(this._required, this._permissionCubit);

  final Set<Permission> _required;
  final PermissionCubit _permissionCubit;

  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) {
    if (_required.every(_permissionCubit.state.contains)) {
      resolver.next();
    } else {
      resolver.next(false);
    }
  }
}
```

**WHY not @injectable:** the guard is parameterized with `Set<Permission>` in the constructor.
Making it `@lazySingleton` is impossible — different instances with different permission sets are needed.
`PermissionCubit` is already a `@lazySingleton` in DI and is passed from outside.

### 3) PRESENTATION — route

File: `lib/features/tiers/list_tiers/presentation/list_tiers_route.dart` (NEW)

Analogous to `lib/features/users/list_users/presentation/users_route.dart`.
Uses `@RoutePage()`, wraps `ListTiersScreen`.

**IMPORTANT:** `ListTiersRoute` should use `BlocProvider.value` to pass
`PermissionCubit` if needed on the screen. But since `PermissionCubit` is already
provided in the `MultiBlocProvider` in `App`, no additional `BlocProvider` is needed.

### 4) PRESENTATION — screen

File: `lib/features/tiers/list_tiers/presentation/list_tiers_screen.dart` (NEW)

`StatelessWidget`. Only `AppBar` + placeholder body.

```dart
@override
Widget build(BuildContext context) {
  final t = context.t;
  return Scaffold(
    appBar: AppBar(title: Text(t.tiers.listTiers.title)),
    body: Center(child: Text(t.tiers.listTiers.placeholder)),
  );
}
```

No `Cubit`, no `BlocBuilder` — no data, no state.

### 5) CORE/ROUTING — update AppRouter

File: `lib/core/routing/app_router.dart`

Two changes:

**a) Add `permissionCubit` to the constructor:**
```dart
class AppRouter extends RootStackRouter {
  AppRouter({required this.authGuard, required this.permissionCubit});

  final AuthGuard authGuard;
  final PermissionCubit permissionCubit;
  ...
}
```

**b) Add the `/tiers` route:**
```dart
AutoRoute(
  page: ListTiersRoute.page,
  path: '/tiers',
  guards: [authGuard, PermissionGuard({Permission.manageTiers}, permissionCubit)],
),
```

Guard order matters: `AuthGuard` first (check authentication),
then `PermissionGuard` (check permission). An unauthenticated user
should not see a "no permission" message — they get redirected to login.

Add imports:
- `list_tiers_route.dart`
- `permission_guard.dart`
- `permission_cubit.dart`

After changes: `dart run build_runner build --delete-conflicting-outputs`
(regenerate `app_router.gr.dart`).

### 6) MAIN — pass permissionCubit to AppRouter

File: `lib/main.dart`

Change the `AppRouter` creation line:
```dart
// Before:
final _router = AppRouter(authGuard: getIt<AuthGuard>());

// After:
final _router = AppRouter(
  authGuard: getIt<AuthGuard>(),
  permissionCubit: getIt<PermissionCubit>(),
);
```

### 7) LOCALIZATION

Files: `lib/core/i18n/i18n/strings.en.json` and `strings.ru.json`

Add a `tiers` section at the top level:

```json
"tiers": {
  "listTiers": {
    "title": "Tiers",
    "placeholder": "Tier management coming soon"
  }
}
```

```json
"tiers": {
  "listTiers": {
    "title": "Тиры",
    "placeholder": "Управление тирами — скоро"
  }
}
```

Then: `dart run slang`

---

## Tests

Tests for this slice are minimal — no Cubit, no Adapter.

### a) `test/core/routing/guards/permission_guard_test.dart` (NEW)

Test `PermissionGuard` as a unit:

- `onNavigation` calls `resolver.next()` (without arguments / `true`) when all
  required permissions are present in `PermissionCubit.state`
- `onNavigation` calls `resolver.next(false)` when at least one permission is missing
- Empty `_required` → `resolver.next()` (no requirements → pass through)

Use `mocktail` to mock `NavigationResolver`, `StackRouter`, and `PermissionCubit`.

---

## Report (upon completion)

- List of new files (4 files)
- List of modified files (5 existing)
- Confirmation: `features/users/` and `features/auth/` were NOT touched
- `dart analyze` — zero errors
- `flutter test test/core/routing/guards/permission_guard_test.dart` — green
- UX walkthrough (see validation.md)

---

## What NOT to do

- Do NOT make `PermissionGuard` `@injectable` / `@lazySingleton`
- Do NOT create `_shared/` for the `tiers` feature — it is empty (fewer than 2 slices)
- Do NOT add a navigation button or menu item — requirement F-06
- Do NOT create a Cubit for `list_tiers` — no data, no state
- Do NOT create domain/ or data/ for `list_tiers` — will be added when the list is implemented
- Do NOT touch `role_policy.dart` — `manageTiers` automatically falls into admin via `{...Permission.values}`
- Do NOT touch `PermissionCubit` — the `isSuperuser → admin → all permissions` mapping already works
- Do NOT change the `AuthGuard` logic
