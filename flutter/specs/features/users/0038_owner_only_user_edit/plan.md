# Plan: Owner-only Edit Button on User Details

## Nature of change

This is a **targeted presentation fix** inside the existing `user_details` slice.
No new slice, no new domain/data/application layers, no API changes, no routing
changes, no DI changes, and no new files.

---

## Root cause

`user_details_screen.dart`, line 65:

```dart
final showEdit = isMe || canEdit;   // BUG: canEdit grants edit affordance to non-owners
```

`canEdit` is `true` whenever the signed-in user holds the `editUsers` permission.
This causes the edit button to appear on other users' profiles, contradicting the
owner-only policy stated in the PRD and already enforced by the backend.

---

## Fix

```dart
// BEFORE
final showEdit = isMe || canEdit;

// AFTER
final showEdit = isMe;
```

`canEdit` is no longer used to drive `showEdit`. The `canEdit` variable can be
removed from `build()` entirely if it serves no other purpose after this change.
Verify by inspection during implementation — do not remove it silently if it is
referenced elsewhere in the same builder.

---

## Files changed

| File | Change |
|---|---|
| `lib/features/users/user_details/presentation/user_details_screen.dart` | `showEdit` condition: remove `canEdit` (and the variable if unused) |
| `test/features/users/user_details/presentation/user_details_screen_test.dart` | Add the missing "non-owner WITH `editUsers` permission" test case |

No other files are touched.

---

## Test gap to close

The existing widget test group `'UserDetailsScreen — Edit button visibility'`
already covers:

| # | Scenario | Status |
|---|---|---|
| T-01 | Owner (`isMe = true`) → edit visible | ✅ exists |
| T-02 | Non-owner, no special permissions → edit hidden | ✅ exists |
| T-03 | Authenticated, `currentUser == null` → edit hidden | ✅ exists |
| T-04 | Unauthenticated → edit hidden | ✅ exists |

**Missing case — must be added:**

| # | Scenario | Expected |
|---|---|---|
| T-05 | Non-owner WITH `Permission.editUsers` → edit **hidden** | ❌ missing |

This is the exact scenario the PRD describes as broken. Without T-05 the fix
has no regression guard.

### T-05 implementation sketch

```dart
testWidgets(
  'Edit button is hidden for non-owner even when editUsers permission is held',
  (tester) async {
    when(() => authCubit.state).thenReturn(
      const AuthState.authenticated(currentUser: _meBob),   // bob views alice
    );
    when(() => permissionCubit.state).thenReturn(
      {Permission.editUsers},   // bob has the permission
    );

    await tester.pumpWidget(buildScreen());   // screen shows alice's profile

    expect(find.byIcon(Icons.edit), findsNothing);
  },
);
```

---

## Architecture notes

- The fix lives entirely in the **presentation layer** of `user_details`.
- No use-case change is needed: the backend already rejects non-owner edit
  requests with 403.
- `AuthCubit.isMe(username)` exists as a convenience method; the inline check
  in `build()` is equivalent and consistent with the rest of the screen —
  do not refactor to use `isMe()` as part of this fix.
- `canEdit` may still be referenced elsewhere in the same builder (e.g. as a
  future guard). Check before removing; if unused, remove to avoid dead code.

---

## Verification checklist

Before declaring done:

- [ ] `dart format .` — no diff
- [ ] `dart analyze` — no warnings
- [ ] `flutter test test/features/users/user_details/` — all green, including T-05
- [ ] No other slice test files affected
