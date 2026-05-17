# Validation Criteria — `delete_post` slice (0022)

Each criterion maps directly to a requirement. All must pass before the slice
is considered done.

---

## Manual UX Walkthrough

### V-01 Happy path (author)
1. Log in as user **A**.
2. Navigate to a post authored by **A**.
3. **Assert:** delete icon (trash) is visible in AppBar alongside the edit icon.
4. Tap the delete icon.
5. **Assert:** confirmation dialog appears with title, irreversibility message, Cancel, and Delete buttons.
6. Tap **Delete**.
7. **Assert:** button shows `CircularProgressIndicator`; Delete button in dialog is gone (dialog dismissed).
8. **Assert:** success snackbar appears with "Post deleted" text.
9. **Assert:** screen navigates back to the previous screen (user posts or list).
10. **Assert:** the deleted post is absent from the visible post list without refreshing.

### V-02 Cancel dismisses without side effects
1. Navigate to author's post.
2. Tap delete icon → dialog appears.
3. Tap **Cancel**.
4. **Assert:** dialog closes; post details screen remains open; no snackbar; no navigation.
5. Tap delete icon again.
6. **Assert:** dialog reappears (state reset correctly).

### V-03 Non-author cannot see the button
1. Log in as user **B**.
2. Navigate to a post authored by **A**.
3. **Assert:** delete icon is NOT present in AppBar.
4. Edit icon is also absent (unless B has `editUsers` permission — verify separately).

### V-04 Unauthenticated user cannot see the button
1. Log out (or open as guest).
2. Navigate to any post via direct URL.
3. **Assert:** delete icon is NOT present.

### V-05 Failure path (network error)
1. Log in as author. Navigate to their post.
2. Disable network / configure server to return 500.
3. Tap delete → confirm.
4. **Assert:** error snackbar appears ("Failed to delete post").
5. **Assert:** post details screen remains open; post is not removed from the list.
6. Re-enable network. Tap delete again.
7. **Assert:** succeeds normally (V-01 criteria).

### V-06 Deep link arrival
1. Open the app via deep link `/user/A/posts/42` while logged in as A.
2. **Assert:** delete button is visible and functions correctly (same as V-01).

---

## Automated Tests

### V-10 Cubit — state machine
Run `flutter test test/features/posts/delete_post/application/`:

| Test | Pass condition |
|---|---|
| `requestConfirmation` emits `[confirming]` | ✅ |
| `cancel` from `confirming` emits `[initial]` | ✅ |
| `cancel` from `initial` emits `[]` | ✅ |
| `confirmAndDelete` → success emits `[deleting, success]` | ✅ |
| `confirmAndDelete` → success calls `eventBus.publish(PostDeleted(id))` | ✅ |
| `confirmAndDelete` → failure emits `[deleting, failure(...)]` | ✅ |

### V-11 Adapter — error mapping
Run `flutter test test/features/posts/delete_post/data/`:

| Test | Pass condition |
|---|---|
| 2xx → `Right(unit)` | ✅ |
| 401 → `Left(UnauthorizedFailure)` | ✅ |
| 403 → `Left(ForbiddenFailure)` | ✅ |
| 404 → `Left(NotFoundFailure)` | ✅ |
| 500 → `Left(NetworkFailure)` | ✅ |
| Unexpected exception → `Left(UnknownFailure)` + `logger.error` called | ✅ |

### V-12 Use-case — ownership enforcement
Run `flutter test test/features/posts/delete_post/domain/`:

| Test | Pass condition |
|---|---|
| `currentUser == null` → `Left(ForbiddenFailure)`, port not called | ✅ |
| `currentUser.username != username` → `Left(ForbiddenFailure)`, port not called | ✅ |
| `currentUser.username == username` → delegates to port | ✅ |

### V-13 UserPostsCubit — event bus integration
Run `flutter test test/features/posts/user_posts/`:

| Test | Pass condition |
|---|---|
| `PostDeleted(id)` while `UserPostsLoaded` → post removed from list | ✅ |
| `PostDeleted(unknownId)` → list unchanged | ✅ |
| `PostDeleted(id)` while not `UserPostsLoaded` → no emission | ✅ |

---

## Static Checks

### V-20 `dart analyze`
```
dart analyze
```
Expected: **0 issues**.

### V-21 `dart format`
```
dart format --set-exit-if-changed .
```
Expected: **no diff** (exit 0).

### V-22 Codegen clean
```
dart run build_runner build --delete-conflicting-outputs
```
Expected: no errors; `posts_api_client.g.dart` updated;
`delete_post_state.freezed.dart` generated.

### V-23 Slang regenerated
`lib/core/i18n/translations.g.dart` MUST contain the `deletePost` key group
(grep for `deletePost`).

---

## Scope Guard

The following MUST NOT change:
- Any slice other than `delete_post` and `_shared` (except the three explicitly
  listed modified files).
- `core/` directory.
- `pubspec.yaml`.
- Any route path in `app_router.dart` (no new route added).
