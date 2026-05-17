# Plan: 0007 — AppShell Navigation

## Title

Task: add a top navigation bar (AppShell) with Users and Tiers tabs.
Tiers is visible only to logged-in users with `isSuperuser == true`.
The shell wraps existing screens via nested `auto_route` navigation.

**This is not a feature-slice with domain/data/application layers.** This is a shell screen in `core/routing/`
that uses `AutoTabsRouter` and the existing `AuthCubit` without new ports or adapters.

---

## Context

### READ:
- `@CLAUDE.md` in full
- `@lib/core/routing/app_router.dart` — will be modified: AppShellRoute as root with nested children
- `@lib/features/users/list_users/presentation/users_route.dart` — route file pattern
- `@lib/features/users/list_users/presentation/users_screen.dart` — will be modified: remove AppBar
- `@lib/features/tiers/list_tiers/presentation/list_tiers_screen.dart` — will be modified: remove AppBar
- `@lib/core/auth/application/auth_cubit.dart` — for logout/forceLogout, stream events
- `@lib/core/auth/application/auth_state.dart` — AuthAuthenticated, AuthUnauthenticated
- `@lib/core/auth/domain/entities/current_user.dart` — isSuperuser field
- `@lib/core/i18n/i18n/en.json` — will be modified: add nav keys
- `@lib/core/i18n/i18n/ru.json` — will be modified: add nav keys
- `@.claude/skills/flutter-implementing-navigation-and-routing/SKILL.md`
- `@.claude/skills/bloc/SKILL.md`

### DO NOT READ:
- `@lib/features/users/create_user/**`
- `@lib/features/users/edit_user/**`
- `@lib/features/users/user_details/**`
- `@lib/features/users/delete_user/**`
- `@lib/features/users/erase_db_user/**`
- `@lib/features/auth/**`
- `@lib/features/tiers/create_tier/**`
- `@lib/core/routing/app_router.gr.dart` (generated)

---

## API

No HTTP calls. The shell only uses the existing `AuthCubit` via `context.read`.

---

## Target Structure

### New files:

```
lib/core/routing/
├── app_shell_screen.dart    # Main shell widget: AutoTabsRouter + NavRow + AppBar
└── app_shell_route.dart     # @RoutePage() class AppShellPage
```

### Files to modify:

```
lib/core/routing/app_router.dart                                  # nested routing
lib/features/users/list_users/presentation/users_screen.dart      # remove AppBar
lib/features/tiers/list_tiers/presentation/list_tiers_screen.dart # remove AppBar
lib/core/i18n/i18n/en.json                                        # nav keys
lib/core/i18n/i18n/ru.json                                        # nav keys
specs/roadmap.md                                                   # entry 0007
```

---

## What to do

### 1) ROUTING — app_shell_route.dart

Create file `lib/core/routing/app_shell_route.dart` following the pattern of existing route files
(see `users_route.dart` — a separate `@RoutePage()` class that wraps the screen).

AppShellPage requires no DI providers — all needed cubits are already provided higher in the tree.

```dart
// lib/core/routing/app_shell_route.dart
@RoutePage()
class AppShellPage extends StatelessWidget {
  const AppShellPage({super.key});

  @override
  Widget build(BuildContext context) => const AppShellScreen();
}
```

### 2) SHELL SCREEN — app_shell_screen.dart

Create `lib/core/routing/app_shell_screen.dart`.

Structure:
```dart
class AppShellScreen extends StatelessWidget {
  const AppShellScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AutoTabsRouter(
      routes: const [UsersRoute(), ListTiersRoute()],
      builder: (context, child) {
        final tabsRouter = AutoTabsRouter.of(context);
        return BlocListener<AuthCubit, AuthState>(
          // CRITICAL: if the user logs out while on the Tiers tab (index 1)
          // — automatically switch to Users (index 0), otherwise the screen is "stuck" on a protected route
          listenWhen: (prev, curr) =>
              curr is AuthUnauthenticated && tabsRouter.activeIndex == 1,
          listener: (context, _) => tabsRouter.setActiveIndex(0),
          child: Scaffold(
            appBar: AppBar(
              title: Text(context.t.app.title),
              bottom: _AppNavBar(tabsRouter: tabsRouter),
              actions: const [_AuthAppBarAction()],  // moved from UsersScreen
            ),
            body: child,
          ),
        );
      },
    );
  }
}
```

#### _AppNavBar (PreferredSizeWidget)

IMPORTANT: Do NOT use the standard `TabBar` with `TabController` — it requires a fixed
`length`, which is incompatible with a conditional number of tabs. Instead, use a custom
widget with `InkWell`/`TextButton` buttons.

```dart
class _AppNavBar extends StatelessWidget implements PreferredSizeWidget {
  const _AppNavBar({required this.tabsRouter});
  final TabsRouter tabsRouter;

  @override
  Size get preferredSize => const Size.fromHeight(40);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final isSuperuser = state is AuthAuthenticated &&
            (state.currentUser?.isSuperuser ?? false);

        return Row(
          children: [
            _NavTab(
              label: context.t.nav.users,
              isSelected: tabsRouter.activeIndex == 0,
              onTap: () => tabsRouter.setActiveIndex(0),
            ),
            if (isSuperuser)
              _NavTab(
                label: context.t.nav.tiers,
                isSelected: tabsRouter.activeIndex == 1,
                onTap: () => tabsRouter.setActiveIndex(1),
              ),
          ],
        );
      },
    );
  }
}
```

`_NavTab` — a small stateless widget: `InkWell` + `Padding` + `Text`, styled
"active/inactive" via `Theme.of(context)`. Implementation details are at the agent's discretion.

#### _AuthAppBarAction

Move the `_AuthAppBarAction` class from `users_screen.dart` to `app_shell_screen.dart` unchanged.

### 3) ROUTING — app_router.dart

Change the route structure: AppShellRoute becomes the root with nested routes.

```dart
@override
List<AutoRoute> get routes => [
  AutoRoute(page: LoginRoute.page, path: '/login'),
  AutoRoute(
    page: AppShellRoute.page,   // new root route
    path: '/',
    initial: true,
    children: [
      AutoRoute(page: UsersRoute.page, initial: true, path: ''),
      AutoRoute(
        page: ListTiersRoute.page,
        path: 'tiers',
        guards: [
          authGuard,
          PermissionGuard({Permission.manageTiers}, permissionCubit),
        ],
      ),
    ],
  ),
  AutoRoute(page: CreateUserRoute.page),
  AutoRoute(page: UserDetailsRoute.page, path: '/user/:username'),
  AutoRoute(
    page: EditUserRoute.page,
    path: '/user/:username/edit',
    guards: [authGuard],
  ),
  AutoRoute(
    page: CreateTierRoute.page,
    path: '/tiers/new',
    guards: [
      authGuard,
      PermissionGuard({Permission.manageTiers}, permissionCubit),
    ],
  ),
];
```

IMPORTANT: `ListTiersRoute` is removed from the top-level routes — it is now only a nested child.

After changing app_router.dart — run codegen:
```
dart run build_runner build --delete-conflicting-outputs
```

### 4) users_screen.dart — remove AppBar

Remove from `UsersScreen`:
- `AppBar` with `title` and `actions` (the shell now owns the AppBar)
- Class `_AuthAppBarAction` (moved to app_shell_screen.dart)

Keep the `Scaffold` in UsersScreen — needed for `floatingActionButton`.
The `body:` remains unchanged.

Resulting `build()` structure:
```dart
return Scaffold(
  floatingActionButton: FloatingActionButton(...),
  body: BlocBuilder<UsersListCubit, UsersListState>(...)
);
```

### 5) list_tiers_screen.dart — remove AppBar

Remove from `ListTiersScreen`:
- `AppBar` with `title` (the shell now owns the AppBar)

Keep the `Scaffold` — needed for `floatingActionButton`.

### 6) LOCALIZATION

Add `nav` keys to `en.json`:
```json
"nav": {
  "users": "Users",
  "tiers": "Tiers"
}
```

Add to `ru.json`:
```json
"nav": {
  "users": "Пользователи",
  "tiers": "Тиры"
}
```

Run codegen:
```
dart run slang
```

---

## Tests

Create `test/core/routing/app_shell_screen_test.dart`.

```
a) widget test — AppShellScreen:

   - unauthenticated (AuthUnauthenticated): 1 tab visible (Users), Tiers absent
   - AuthAuthenticated(isSuperuser: false): 1 tab visible (Users), Tiers absent
   - AuthAuthenticated(isSuperuser: true): 2 tabs visible (Users + Tiers)
   - superuser switches to Tiers (index 1) → emit AuthUnauthenticated
     → activeIndex == 0, Tiers tab disappears

Mock AuthCubit via mocktail.
For AutoTabsRouter in tests — wrap in MaterialApp with MockRouter or
use `AutoRouterMock` from auto_route_test (see package docs).
```

---

## Report

Upon completion, provide:
- List of new files and modified files
- Confirmation that other users and tiers slices were NOT touched (except users_screen.dart and list_tiers_screen.dart)
- Confirmation that codegen was run (`build_runner` + `slang`)
- UX walkthrough against the validation.md checklist
- Tests: number of new tests, execution result

---

## What NOT to do

- DO NOT use the standard `TabBar` with `TabController` — its `length` is fixed at
  creation time, and conditional rendering of the Tiers tab will cause an assertion error (`length` != number of Tab widgets)
- DO NOT check permissions via `PermissionCubit` for tab visibility — use only `isSuperuser`
  (user role from `AuthCubit`). `PermissionGuard` stays on the Tiers route only (for URL protection)
- DO NOT duplicate `_AuthAppBarAction` in UsersScreen — move it to the shell, remove from UsersScreen
- DO NOT add `AppBar` to UsersScreen or ListTiersScreen after moving to the shell
- DO NOT create port/usecase/adapter — the shell has no domain layer
- DO NOT touch other users slices (create_user, edit_user, user_details, delete_user, erase_db_user)
- DO NOT touch create_tier
- DO NOT add `ListTiersRoute` back to the top-level routes (it is now a nested child of AppShellRoute)
- DO NOT remove guards from the ListTiersRoute nested child — they are needed to protect direct URL navigation
