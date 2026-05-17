# Plan — 0026: Tab Root Reset on Tap

## Summary

A single-file change to `lib/core/routing/app_shell_screen.dart`. No new layers, no
cubit, no use-case, no adapter. The three `onTap` callbacks in `_AppNavBar` gain a
`replaceAll` call before `setActiveIndex` to clear each tab's inner stack.

One new test file is added:
`test/core/routing/tab_root_reset_test.dart`.

---

## Context

Read before implementing:

- `lib/core/routing/app_shell_screen.dart` — the only file changed
- `lib/core/routing/app_router.dart` — tab route names and child route list
- `lib/core/routing/tabs/users_tab_route.dart` — tab page class (same pattern for
  posts / tiers)
- `test/core/routing/tab_navigation_test.dart` — prior-art test: mock setup pattern,
  `_PermissiveAuthGuard`, `AutoLeadingButton` context anchor, `navigate` vs `push`
- `test/core/routing/app_shell_screen_test.dart` — prior-art test: `_buildApp`
  helper, `getIt` mock registration pattern

Do **not** read other slices or feature files.

---

## What already exists

```
lib/core/routing/app_shell_screen.dart   ← ONLY FILE TO MODIFY
```

Current `_AppNavBar.build` onTap callbacks (lines 62, 66, 71):
```dart
onTap: () => tabsRouter.setActiveIndex(0),   // Users
onTap: () => tabsRouter.setActiveIndex(1),   // Posts
onTap: () => tabsRouter.setActiveIndex(2),   // Tiers
```

---

## Step 1 — Modify `_AppNavBar` callbacks

File: `lib/core/routing/app_shell_screen.dart`

Replace each `onTap` lambda with a helper that:
1. Looks up the inner `StackRouter` for the target tab (null-safe).
2. Calls `replaceAll([RootRoute()])` on it if non-null.
3. Calls `setActiveIndex(n)`.

### Root routes per tab

| Tab index | `innerRouterOf` key | `replaceAll` argument |
|---|---|---|
| 0 (Users) | `UsersTabRoute.name` | `[const UsersRoute()]` |
| 1 (Posts) | `PostsTabRoute.name` | `[const ListPostsRoute()]` |
| 2 (Tiers) | `TiersTabRoute.name` | `[const ListTiersRoute()]` |

### Concrete implementation

Extract a private method on `_AppNavBar` (or inline — whichever avoids repetition):

```dart
void _resetAndSwitch(TabsRouter tabsRouter, int index, String tabName, PageRouteInfo root) {
  tabsRouter.innerRouterOf<StackRouter>(tabName)?.replaceAll([root]);
  tabsRouter.setActiveIndex(index);
}
```

Then update the three `onTap` closures:

```dart
_NavTab(
  label: context.t.nav.users,
  isSelected: tabsRouter.activeIndex == 0,
  onTap: () => _resetAndSwitch(tabsRouter, 0, UsersTabRoute.name, const UsersRoute()),
),
_NavTab(
  label: context.t.nav.posts,
  isSelected: tabsRouter.activeIndex == 1,
  onTap: () => _resetAndSwitch(tabsRouter, 1, PostsTabRoute.name, const ListPostsRoute()),
),
if (isSuperuser)
  _NavTab(
    label: context.t.nav.tiers,
    isSelected: tabsRouter.activeIndex == 2,
    onTap: () => _resetAndSwitch(tabsRouter, 2, TiersTabRoute.name, const ListTiersRoute()),
  ),
```

### Critical constraints

- `replaceAll` is called **before** `setActiveIndex`. Both mutations land in the same
  frame — no visible intermediate state.
- `innerRouterOf<StackRouter>(name)` returns `null` when the tab has never been
  activated (its page was never pushed into the `IndexedStack`). The null-safe `?.`
  skips `replaceAll` in that case; `setActiveIndex` then shows the tab's initial
  route automatically.
- The `BlocListener` that handles forced tab switch on logout
  (`listenWhen: curr is AuthUnauthenticated && activeIndex == 2`) must **not** be
  touched. Its `setActiveIndex(0)` call is intentionally a silent switch with no
  stack reset, and it is out of scope.
- `_resetAndSwitch` is a plain sync helper — no `unawaited`, no `async`, no
  `Future`. The `replaceAll` async tail (guard evaluation) is irrelevant here
  because the root routes carry no guards within the tab stacks.

---

## Step 2 — Imports

`UsersRoute`, `ListPostsRoute`, and `ListTiersRoute` must be imported in
`app_shell_screen.dart` if not already present (check before adding):

```dart
import 'package:flutter_application_1/features/users/list_users/presentation/users_route.dart';
import 'package:flutter_application_1/features/posts/list_posts/presentation/list_posts_route.dart';
import 'package:flutter_application_1/features/tiers/list_tiers/presentation/list_tiers_route.dart';
import 'package:flutter_application_1/core/routing/tabs/users_tab_route.dart';
import 'package:flutter_application_1/core/routing/tabs/posts_tab_route.dart';
import 'package:flutter_application_1/core/routing/tabs/tiers_tab_route.dart';
```

`app_router.dart` already imports all of these routes — verify the generated
`app_router.gr.dart` exports them before adding redundant imports.

---

## Step 3 — Tests

File: `test/core/routing/tab_root_reset_test.dart`

Follow the exact setup pattern from `tab_navigation_test.dart`:
- Real `AppRouter` with `_PermissiveAuthGuard`.
- `getIt`-registered mock cubits (same factories used in `tab_navigation_test.dart`).
- `AutoLeadingButton` element as the context anchor for `AutoTabsRouter.of()`.
- `navigate` (not `push`) for inner-stack navigation to avoid blocking
  `pumpAndSettle` on the pop future.

### Mock registration

Reuse the same mock classes and factory patterns from `tab_navigation_test.dart`
(copy or refactor into a shared helper file — your call, but do not break existing
tests).

Required mocks:
- `_MockUsersListCubit` — for Users list root screen
- `_MockUserDetailsCubit`, `_MockGetUserTierCubit`, `_MockUpdateUserTierCubit` — for
  UserDetails child screen
- `_MockPostDetailsCubit`, `_MockDeletePostCubit` — for PostDetails child screen in
  Posts tab
- `_MockListTiersCubit`, `_MockTierDetailsCubit`, `_MockDeleteTierCubit` — for
  TierDetails child screen in Tiers tab

### Test cases

All five are in a single `group('tab root reset on tap')`.

#### TC-1: Users tab tap while deep in Users stack

```
Setup: unauthenticated, navigate UserDetailsRoute(username: 'alice') into the Users
       inner stack.
Action: tap the 'Users' tab button.
Assert: find.text('alice') → findsNothing (UserDetails gone).
        find.text('Users') → findsOneWidget (tab button still present).
```

#### TC-2: Re-tapping the active Users tab

```
Setup: unauthenticated, navigate UserDetailsRoute(username: 'alice') into the Users
       inner stack.
Action: the Users tab is already active (index 0). Tap 'Users' again.
Assert: find.text('alice') → findsNothing.
        find.text('Users') → findsOneWidget.
```

#### TC-3: Posts tab tap while deep in Posts stack

```
Setup: unauthenticated.
       Switch to Posts tab (tester.tap 'Posts').
       Navigate PostDetailsRoute(username: 'alice', id: 1) via innerRouterOf.
Action: tap 'Posts' tab button.
Assert: find.byType(PostDetailsPage or its identifying widget) → gone.
        find.text('Posts') → findsOneWidget.
```

#### TC-4: Tiers tab tap while deep in Tiers stack (superuser)

```
Setup: authenticated superuser.
       Switch to Tiers tab (tester.tap 'Tiers').
       Navigate TierDetailsRoute(tierName: 'gold') via innerRouterOf.
Action: tap 'Tiers' tab button.
Assert: find.text('gold') → findsNothing (TierDetails gone).
        find.text('Tiers') → findsOneWidget.
```

#### TC-5: Cross-tab sequence — re-tap after visiting other tab

```
Setup: unauthenticated.
       Navigate UserDetailsRoute(username: 'alice') into Users stack.
       Tap 'Posts' (switch tabs).
       Tap 'Users' (switch back).
Assert: find.text('alice') → findsNothing (stack was reset when Users was tapped).
        find.text('Users') → findsOneWidget.
```

### Assertions to use

- Presence / absence of `find.text('alice')` or `find.text('gold')` — widget-tree
  observable state, not router internals.
- `find.text('Users')`, `find.text('Posts')`, `find.text('Tiers')` — tab button labels.
- Do **not** inspect `_pages` lists, `router.stack`, or any private router field.

---

## Files changed

| Path | Status |
|---|---|
| `lib/core/routing/app_shell_screen.dart` | Modified — 3 `onTap` lambdas replaced |
| `test/core/routing/tab_root_reset_test.dart` | New — 5 widget tests |

No other file is touched. No cubit, use-case, adapter, domain, or `core/` file
outside `routing/` is modified.

---

## Verification checklist

- `dart format .` — no diff.
- `dart analyze` — no warnings.
- `flutter test test/core/routing/tab_root_reset_test.dart` — all 5 pass.
- `flutter test test/core/routing/` — existing tests in `app_shell_screen_test.dart`
  and `tab_navigation_test.dart` remain green.
- No `build_runner` run needed (no codegen-affecting files changed).
