# 0026 · tab_root_reset_on_tap — Validation Checklist

## Manual testing

| # | Step | Expected result |
|---|---|---|
| M1 | Open the Users tab. Tap any user row to open UserDetails ("alice"). Tap the **Users** tab button in the nav bar. | Users list is shown. "alice" page title is gone. No back-slide animation plays. |
| M2 | Open UserDetails ("alice") as above so the Users tab is already active. Tap the **Users** tab button again (same-tab re-tap). | Users list is shown immediately. "alice" page title is gone. |
| M3 | From Users list, navigate: open UserDetails → open UserPosts → open PostDetails (four levels deep). Tap the **Users** tab button. | Users list is shown instantly. No intermediate pages (UserDetails, UserPosts, PostDetails) are visible. |
| M4 | Tap the **Posts** tab button to switch to Posts. Open any PostDetails. Tap the **Posts** tab button. | Posts list is shown. PostDetails is gone. |
| M5 | Log in as a superuser. Tap the **Tiers** tab button. Open any TierDetails (e.g. "gold"). Tap the **Tiers** tab button. | Tiers list is shown. "gold" detail page is gone. |
| M6 | Open UserDetails in the Users tab. Tap the **Users** tab button. | Root screen appears with no back-navigation (pop) animation — transition is an instant cut, not a slide from right to left. |
| M7 | Open UserDetails ("alice") in the Users tab. Tap the **Posts** tab button (switch away). | Posts list is shown. No error. Users tab state is preserved in the background (no reset yet). |
| M8 | Continuing from M7: tap the **Users** tab button to return. | Users list is shown (the reset occurred on this deliberate tap, not on the earlier switch to Posts). "alice" title is absent. |
| M9 | Log in as superuser (Tiers tab is now visible but has not been tapped yet). Tap the **Tiers** tab button for the very first time. | Tiers list is displayed. No crash, no error message. |
| M10 | Log in as superuser. Navigate to TierDetails ("gold") on the Tiers tab. Log out. | App auto-switches to Users tab. No crash. No "gold" detail visible. Users tab shows its prior state (Users list if not previously navigated). |

## Code review

- [ ] Only `lib/core/routing/app_shell_screen.dart` is modified in the production `lib/` tree; no other file under `lib/` is changed (verify with `git diff --name-only`).
- [ ] In each of the three tab `onTap` closures (or in the extracted helper method), `replaceAll([...])` is called **before** `setActiveIndex(n)`.
- [ ] Inner router lookup uses `?.replaceAll(...)` (null-safe call operator); no explicit `if (router != null)` guard clause is present.
- [ ] The `onTap` handler (inline or extracted method) contains no `async`, `await`, or `unawaited`.
- [ ] No logic or method calls are placed directly inside any `build()` method body; tab-reset logic lives in a separate private method or in the `onTap` lambda only.
- [ ] No `setState` call exists anywhere in `app_shell_screen.dart`.
- [ ] The `BlocListener` block that calls `setActiveIndex(0)` on `AuthUnauthenticated` while `activeIndex == 2` is **textually unchanged** from the pre-patch version.
- [ ] No new `import` directive appears in `app_shell_screen.dart`; all route classes and tab-name constants are accessed via the existing `app_router.dart` import.
- [ ] No `package:flutter_application_1/features/` import path is introduced in any file under `lib/core/`.
- [ ] `test/core/routing/tab_root_reset_test.dart` exists and contains exactly 5 test cases covering: Users-tab reset while deep, same-tab re-tap, Posts-tab reset, Tiers-tab reset (superuser), cross-tab sequence.
- [ ] Test assertions use only `find.text(...)`, `find.byType(...)`, `findsOneWidget`, and `findsNothing`; no access to `router.stack`, `_pages`, or any private router field.
- [ ] `dart run build_runner build --delete-conflicting-outputs` — no errors
- [ ] `dart run slang` — no errors
- [ ] `dart analyze` — no warnings
- [ ] All tests green
