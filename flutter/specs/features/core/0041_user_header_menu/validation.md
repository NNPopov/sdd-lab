# 0041 · user_header_menu — Validation Checklist

## Manual testing

| # | Step | Expected result |
|---|---|---|
| M1 | Open the app authenticated as user `alice`. Inspect the AppBar. | Username `alice` appears as a tappable text widget in the AppBar actions area. |
| M2 | Tap `alice` in the AppBar. | A dropdown opens with exactly three items: "My Profile", "My Posts", "Sign out". |
| M3 | Open the dropdown. Inspect item order and divider placement. | "My Profile" is first, "My Posts" is second, a visual divider appears between "My Posts" and "Sign out"; no divider between the first two items. |
| M4 | Open dropdown, tap "My Profile". | The user details screen for `alice` opens; a back button is available. |
| M5 | Tap back from the user details screen reached via "My Profile". | Returns to the screen the user was on before; AppBar username is still visible. |
| M6 | Open dropdown, tap "My Posts". | The user posts screen for `alice` opens; a back button is available. |
| M7 | Tap back from the user posts screen reached via "My Posts". | Returns to the previous screen. |
| M8 | Open dropdown, tap "Sign out". | The logout confirmation dialog appears. |
| M9 | In the logout confirmation dialog, tap "Cancel". | Dialog closes; user remains signed in; username still visible in AppBar. |
| M10 | Open dropdown, tap "Sign out", then tap "Sign out" in the dialog. | User is signed out; username disappears; sign-in button appears. |
| M11 | While authenticated, scan the AppBar visually and with a gesture-detector tool. | No standalone logout icon button (`Icons.logout`) is present anywhere in the AppBar. |
| M12 | Open the app while not authenticated. Inspect the AppBar. | No username text, no popup menu; existing sign-in button is present and unchanged. |
| M13 | Navigate to the Posts tab while authenticated. Tap username, tap "My Profile". | User details screen opens regardless of which tab was active; back returns to the Posts tab. |
| M14 | Authenticate as superuser. Navigate to the Tiers tab. Tap username, tap "My Posts". | User posts screen opens; navigation works from the Tiers tab without forcing a tab switch. |
| M15 | Change the app locale to Spanish (or another non-English locale). Open the dropdown. | "My Profile" shows the Spanish translation ("Mi perfil"); "My Posts" shows "Mis publicaciones"; "Sign out" label reflects the existing `auth.logout.confirm` key for that locale. |

## Code review

- [ ] `lib/core/routing/app_shell_screen.dart` is the only production Dart file in the diff; no new files appear under `lib/`
- [ ] All four locale files (`en-US.json`, `ru-RU.json`, `es-ES.json`, `uk-UA.json`) contain both `userMenu.myProfile` and `userMenu.myPosts` keys with non-empty values
- [ ] Menu item labels use `context.t.userMenu.myProfile`, `context.t.userMenu.myPosts`, and `context.t.auth.logout.confirm`; no hardcoded strings present
- [ ] `_confirmLogout` method body is byte-for-byte identical to the pre-change implementation
- [ ] `AuthCubit`, `AuthState`, `CurrentUser`, and `app_router.dart` show no diff
- [ ] `_UserMenuAction` is declared with a leading underscore (file-private); it appears in no export or public API
- [ ] No new `AutoRoute` entry, Cubit, adapter, port, or use-case class appears in the diff
- [ ] `_AuthAppBarAction.build` contains only widget composition; all navigation and dispatch logic lives in `_onMenuAction`
- [ ] The `AuthAuthenticated` branch in `build` guards against `currentUser == null` (renders `SizedBox.shrink()` when null)
- [ ] `test/core/routing/app_shell_screen_test.dart` contains tests for: username rendered, menu items visible, My Profile navigation, My Posts navigation, Sign out dialog, no standalone logout `IconButton`, unauthenticated state (no menu), and null `currentUser` (no menu)
- [ ] `dart run build_runner build --delete-conflicting-outputs` — no errors
- [ ] `dart run slang` — no errors
- [ ] `dart analyze` — no warnings
- [ ] All tests green
