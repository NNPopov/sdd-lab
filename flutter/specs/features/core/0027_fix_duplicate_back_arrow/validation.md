# 0027 · fix_duplicate_back_arrow — Validation Checklist

## Manual testing

| # | Step | Expected result |
|---|---|---|
| M1 | Launch the app and land on the Users tab root. | No back arrow appears in the shell AppBar (top row with app title) or in the Users list AppBar. |
| M2 | Switch to the Posts tab. | No back arrow appears in the shell AppBar or in the Posts list AppBar. |
| M3 | From the Users tab, tap any user to open UserDetailsScreen. | Exactly one back arrow appears — in UserDetailsScreen's own AppBar, next to the username title. The shell AppBar (app title row) shows no back arrow. |
| M4 | From UserDetailsScreen, tap "Posts" to open UserPostsScreen. | Exactly one back arrow — in UserPostsScreen's own AppBar. Shell AppBar still shows no back arrow. |
| M5 | From UserPostsScreen, tap any post to open PostDetailsScreen. | Exactly one back arrow — in PostDetailsScreen's own AppBar. Shell AppBar still shows no back arrow. Three screens are in the stack; the back arrow is only in the innermost screen. |
| M6 | Tap the back arrow on PostDetailsScreen. | Navigates back to UserPostsScreen. The back arrow in UserPostsScreen's AppBar remains. |
| M7 | Tap the back arrow on UserPostsScreen. | Navigates back to UserDetailsScreen. The back arrow in UserDetailsScreen's AppBar remains. |
| M8 | Tap the back arrow on UserDetailsScreen. | Navigates back to the Users tab root. No back arrow is visible anywhere. |
| M9 | From the Posts tab, tap any post to open PostDetailsScreen. | Exactly one back arrow — in PostDetailsScreen's own AppBar. Shell AppBar shows no back arrow. |
| M10 | From any detail screen, verify the shell AppBar contents. | Shell AppBar shows: app title text, locale selector button, and the auth action (username + logout button or Sign In). No leading arrow, no extra icons. |
| M11 | From the Tiers tab (as superuser), open TierDetailsScreen. | Exactly one back arrow — in TierDetailsScreen's own AppBar. Shell AppBar shows no back arrow. |
| M12 | Open CreatePostScreen or EditPostScreen. | Exactly one back arrow — in the screen's own AppBar. Shell AppBar shows no back arrow. |

## Code review

- [ ] Diff touches exactly two files: `lib/core/routing/app_shell_screen.dart` and `test/core/routing/app_shell_screen_test.dart`.
- [ ] `AppShellScreen`'s `AppBar` has `automaticallyImplyLeading: false` as an explicit property.
- [ ] `AppShellScreen`'s `AppBar` has no `leading` property (and no `AutoLeadingButton` anywhere in `AppShellScreen.build`).
- [ ] No detail-screen file (`post_details_screen.dart`, `user_details_screen.dart`, etc.) is modified.
- [ ] `app_router.dart` and route configuration files are unmodified.
- [ ] `pubspec.yaml` is unmodified (no new dependencies).
- [ ] In `app_shell_screen_test.dart`, the test formerly named `'AutoLeadingButton is present in the widget tree'` now asserts `find.byType(AutoLeadingButton), findsNothing` (and has an updated name).
- [ ] In `app_shell_screen_test.dart`, the test `'no BackButton rendered at root of Users tab'` still asserts `find.byType(BackButton), findsNothing` (assertion unchanged, name may be updated).
- [ ] In `app_shell_screen_test.dart`, the test for a pushed child route now asserts `find.byType(BackButton), findsOneWidget` (changed from `findsWidgets`).
- [ ] `tab_navigation_test.dart` and `tab_root_reset_test.dart` are unmodified.
- [ ] `dart run build_runner build --delete-conflicting-outputs` — no errors
- [ ] `dart run slang` — no errors
- [ ] `dart analyze` — no warnings
- [ ] All tests green
