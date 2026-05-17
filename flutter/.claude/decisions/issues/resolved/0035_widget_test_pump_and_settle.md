# Resolved: pumpAndSettle times out on infinite animations (0035)

## Problem

Widget tests for `ModeratePostScreen` that used `pumpAndSettle()` hung until
the test framework timed out. The symptom was a stuck test runner with no
failure message — just a timeout after ~10 seconds.

The cause: `pumpAndSettle` keeps pumping frames until all animations settle.
`CircularProgressIndicator` (shown during the loading state) runs an infinite
rotation animation that never settles. `SnackBar` has its own dismiss animation
that also blocks settlement.

## Resolution

Replace `pumpAndSettle()` with a manual two-pump sequence:

```dart
await tester.pump();                              // commit the frame
await tester.pump(const Duration(milliseconds: 100)); // let transitions finish
```

For tab-switch animations (TabController default = 300 ms) use 300 ms instead
of 100 ms.

## Where this pattern is applied

- `test/features/posts/0035_moderate_post/presentation/moderate_post_screen_wide_test.dart`
- `test/features/posts/0035_moderate_post/presentation/moderate_post_screen_narrow_test.dart`

Apply to any future widget test that renders a loading spinner or shows a
SnackBar. As a rule: if a test hangs silently, suspect an infinite animation
before anything else.
