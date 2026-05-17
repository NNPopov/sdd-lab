# 0013 · posts / list_posts — Implementation Plan

## Task

Create a stub slice `list_posts` inside the `posts` feature.
Result: a **Posts** menu item appears between Users and Tiers, is accessible to all
users (including unauthenticated ones), and opens an empty screen with a title.
Business logic, API, Cubit — not implemented; everything will be added in subsequent tasks.

---

## CONTEXT

READ:
- `CLAUDE.md` in full
- `lib/core/routing/app_router.dart` — we will add ListPostsRoute to AppShellRoute
- `lib/core/routing/app_shell_screen.dart` — we will add a tab and update indices
- `lib/core/i18n/i18n/en.json` — we will add the `nav.posts` key
- `lib/core/i18n/i18n/ru.json` — same
- `lib/features/users/list_users/presentation/users_route.dart` — analogue route file
- `lib/features/tiers/list_tiers/presentation/list_tiers_route.dart` — analogue route file

DO NOT READ:
- `lib/features/users/**` (except list_users/presentation/users_route.dart)
- `lib/features/tiers/**` (except list_tiers/presentation/list_tiers_route.dart)
- `lib/core/auth/**`
- `*.gr.dart`, `*.config.dart`, `*.g.dart` — generated files

---

## STRUCTURE

```
lib/features/posts/
├── list_posts/
│   └── presentation/
│       ├── list_posts_screen.dart   # empty Scaffold with AppBar(title)
│       └── list_posts_route.dart    # @RoutePage() annotation
└── posts_feature_module.dart        # @module, empty (no registrations)
```

Files to modify:
- `lib/core/routing/app_router.dart`
- `lib/core/routing/app_shell_screen.dart`
- `lib/core/i18n/i18n/en.json`
- `lib/core/i18n/i18n/ru.json`
- `specs/roadmap.md`

---

## WHAT TO DO

### 1. LOCALISATION

`lib/core/i18n/i18n/en.json` — add key to the `nav` section:
```json
"nav": {
  "users": "Users",
  "posts": "Posts",
  "tiers": "Tiers"
}
```

`lib/core/i18n/i18n/ru.json` — same:
```json
"nav": {
  "users": "Пользователи",
  "posts": "Посты",
  "tiers": "Тиры"
}
```

After editing, run codegen: `dart run slang`

### 2. PRESENTATION — route

`lib/features/posts/list_posts/presentation/list_posts_route.dart`

```dart
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'list_posts_screen.dart';

part 'list_posts_route.gr.dart';

@RoutePage()
class ListPostsPage extends StatelessWidget {
  const ListPostsPage({super.key});

  @override
  Widget build(BuildContext context) => const ListPostsScreen();
}
```

### 3. PRESENTATION — screen

`lib/features/posts/list_posts/presentation/list_posts_screen.dart`

Empty `Scaffold` with `AppBar`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/i18n/translations.g.dart';

class ListPostsScreen extends StatelessWidget {
  const ListPostsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.t.nav.posts)),
    );
  }
}
```

IMPORTANT: The AppBar here is the screen's internal AppBar, separate from the global
one in AppShellScreen. This is normal for tabs that do not have their own AppBar in
the shell. See how it is done in analogous screens.

### 4. DI MODULE

`lib/features/posts/posts_feature_module.dart`

```dart
import 'package:injectable/injectable.dart';

@module
abstract class PostsFeatureModule {}
```

The module is empty — nothing to register yet until adapters and Cubit exist.

### 5. ROUTING — app_router.dart

Add an import for `list_posts_route.dart` and insert `ListPostsRoute` in the children
of AppShellRoute **between** UsersRoute and ListTiersRoute:

```dart
children: [
  AutoRoute(page: UsersRoute.page, initial: true, path: ''),
  AutoRoute(page: ListPostsRoute.page, path: 'posts'),  // <-- new, no guards
  AutoRoute(
    page: ListTiersRoute.page,
    path: 'tiers',
    guards: [...],
  ),
],
```

No guards — Posts is public.

After editing, run codegen: `dart run build_runner build`

### 6. NAVIGATION — app_shell_screen.dart

CRITICAL: inserting Posts at index 1 shifts Tiers from index 1 to index 2.
Three places must be updated in a single file:

**6a. AutoTabsRouter.routes** — add `ListPostsRoute()`:
```dart
routes: const [UsersRoute(), ListPostsRoute(), ListTiersRoute()],
```

**6b. listenWhen** — Tiers is now at index 2:
```dart
listenWhen: (prev, curr) =>
    curr is AuthUnauthenticated && tabsRouter.activeIndex == 2,
```

**6c. _AppNavBar.build** — add the Posts tab (always visible) and fix the Tiers index:
```dart
children: [
  _NavTab(
    label: context.t.nav.users,
    isSelected: tabsRouter.activeIndex == 0,
    onTap: () => tabsRouter.setActiveIndex(0),
  ),
  _NavTab(                                    // <-- new
    label: context.t.nav.posts,
    isSelected: tabsRouter.activeIndex == 1,
    onTap: () => tabsRouter.setActiveIndex(1),
  ),
  if (isSuperuser)
    _NavTab(
      label: context.t.nav.tiers,
      isSelected: tabsRouter.activeIndex == 2, // was 1
      onTap: () => tabsRouter.setActiveIndex(2), // was 1
    ),
],
```

### 7. ROADMAP

Update `specs/roadmap.md` — change the status of 0013 from 📋 to ✅ after implementation.

---

## TESTS

Stub slice with no logic — unit tests and bloc tests are not needed.
A widget test is optional: it can verify that `ListPostsScreen` renders without errors.

---

## REPORT

On completion, provide:
- List of created files
- List of modified files
- Confirmation that other slices were not touched
- Confirmation that codegen (`dart run slang` + `dart run build_runner build`) completed without errors

---

## WHAT NOT TO DO

- DO NOT create `domain/`, `data/`, `application/` in posts — it is a stub, they do not exist
- DO NOT add guards to ListPostsRoute — Posts is public
- DO NOT hardcode the string "Posts" — use only `context.t.nav.posts`
- DO NOT touch the index logic of the logout-redirect in `_confirmLogout` — there are no indices there
- DO NOT add logic to `PostsFeatureModule` — leave it empty
- DO NOT forget to update the Tiers index in THREE places in app_shell_screen.dart
