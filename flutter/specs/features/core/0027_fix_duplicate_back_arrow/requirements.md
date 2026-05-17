# 0027 · fix_duplicate_back_arrow — Requirements

## Functional Requirements

| ID | Requirement |
|---|---|
| F1 | The shell AppBar shall never display a back arrow, regardless of how deep the navigation stack is. |
| F2 | Each detail screen's own AppBar shall display a back arrow when there is a route to pop. |
| F3 | Tapping the back arrow in a detail screen's AppBar shall navigate back to the previous screen. |
| F4 | No back arrow shall appear in any AppBar when the user is on a top-level tab screen (Users, Posts, or Tiers root). |
| F5 | The shell AppBar title, locale selector, and auth action shall remain unaffected by this change. |
| F6 | Detail screens (post details, user details, user posts, create/edit post, create/edit/details tier, create/edit user) shall each display exactly one back arrow in their own AppBar when reached by navigation push. |

## Non-functional Requirements

| ID | Requirement |
|---|---|
| N1 | Only `AppShellScreen` is modified in production code; no detail-screen or routing-configuration files are touched. |
| N2 | The shell `AppBar` must carry `automaticallyImplyLeading: false` so that Flutter does not re-infer a leading button after `AutoLeadingButton` is removed. |
| N3 | No `AutoLeadingButton` widget shall appear anywhere in the shell `AppBar` widget tree. |
| N4 | No Cubit, use-case, adapter, domain, or `AppRouter` configuration file is modified. |
| N5 | No new package dependency is added to `pubspec.yaml`. |
| N6 | No codegen step (`build_runner`, `slang`) is required, as no freezed, injectable, retrofit, or slang files change. |
| N7 | The three tests in the `'AppShellScreen — AutoLeadingButton'` group of `app_shell_screen_test.dart` are updated to reflect the new behaviour; no new test file is created for this slice. |
| N8 | `dart format .` produces no diff and `dart analyze` reports no warnings after the change. |
| N9 | The existing passing tests in `tab_navigation_test.dart` and `tab_root_reset_test.dart` remain green and are not modified. |

## Out of scope

- Changing the visual design or position of the back arrow in any detail screen.
- Updating the shell AppBar title dynamically to reflect the current screen name.
- Any changes to detail-screen `AppBar` widgets themselves.
- Modifications to routing configuration, guards, or deep-link handling.
