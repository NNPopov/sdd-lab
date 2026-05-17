# 0026 · tab_root_reset_on_tap — Requirements

## Functional Requirements

| ID | Requirement |
|---|---|
| F1 | Tapping any tab button (Users, Posts, or Tiers) navigates to the root screen of that tab, regardless of how many screens are currently in that tab's inner navigation stack. |
| F2 | Tapping the Users tab always shows the Users list screen. |
| F3 | Tapping the Posts tab always shows the Posts list screen. |
| F4 | Tapping the Tiers tab (visible to superusers only) always shows the Tiers list screen. |
| F5 | Re-tapping the currently active tab resets that tab to its root screen. |
| F6 | The root reset is instantaneous — no reverse-slide animation plays through intermediate pages; the root screen appears without a back-navigation transition. |
| F7 | Non-active tabs' inner stacks remain in memory between tab switches; a stack is cleared only when its own tab button is tapped. |
| F8 | When a tab is tapped for the first time and its inner router has not yet been initialised, the system navigates to that tab's initial route without error. |

## Non-functional Requirements

| ID | Requirement |
|---|---|
| N1 | The implementation is confined to `lib/core/routing/app_shell_screen.dart`; no other production source file is modified. |
| N2 | `replaceAll` is called before `setActiveIndex` so that both the stack mutation and the active-index change land in the same frame. |
| N3 | The inner `StackRouter` lookup uses a null-safe call (`?.replaceAll`); a `null` return value is silently ignored and `setActiveIndex` still executes. |
| N4 | The `onTap` callback is synchronous — no `async`, `await`, or `unawaited` is used. |
| N5 | No logic is placed inside any widget's `build()` method. |
| N6 | No `setState` is introduced in `_AppNavBar` or any widget in `app_shell_screen.dart`. |
| N7 | The `BlocListener` for the logout-forced tab switch (`listenWhen: curr is AuthUnauthenticated && activeIndex == 2`) is not modified. |
| N8 | No new file-level imports are added to `app_shell_screen.dart`; all route classes and tab router name constants are accessible through the existing `app_router.dart` import via its generated `app_router.gr.dart` part file. |
| N9 | `core/routing/` does not introduce any new direct dependency on `features/` packages. |
| N10 | Test assertions observe only widget-tree state (text labels, widget presence/absence); no private router fields or `_pages` lists are inspected. |

## Out of scope

- The logout-forced tab switch (`BlocListener` → `setActiveIndex(0)`) is not modified.
- Deep-link or URL-based navigation that lands directly on a child route is not affected.
- Scroll-position restoration within any root list screen is not addressed.
- Any change to the cross-tab switching animation (currently `IndexedStack` with no transition) is not in scope.
- Per-tab smart reset (e.g., reset only when already at root, or "scroll to top" shortcut) is not in scope.
