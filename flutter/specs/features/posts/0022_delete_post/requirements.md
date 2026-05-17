# Requirements — `delete_post` slice (0022)

## Functional Requirements

### FR-01 Delete button visibility
The delete button MUST be rendered in `PostDetailsScreen`'s AppBar **only** when
the authenticated user's `username` matches `widget.username` (the post author).
Non-authors and unauthenticated users MUST NOT see the button.

### FR-02 Ownership enforcement in use-case
`DeletePostUseCase` MUST return `Left(Failure.forbidden(...))` if
`authCubit.currentUser` is `null` or its `username` does not equal the target
`username` argument. The port MUST NOT be called in that case.

### FR-03 Confirmation dialog
Tapping the delete button MUST trigger a confirmation dialog before any API call
is made. The dialog MUST:
- State the post will be permanently deleted.
- State the action is irreversible.
- Provide a **Cancel** action that dismisses without side effects.
- Provide a **Confirm** (destructive) action that proceeds with deletion.

### FR-04 Loading state
While the DELETE request is in flight the button MUST show a `CircularProgressIndicator`
(20×20, strokeWidth 2) and `onPressed` MUST be `null` (not tappable).

### FR-05 Success flow
On a successful server response the cubit MUST:
1. Publish `PostDeleted(id)` to `PostEventBus`.
2. Emit `DeletePostSuccess`.

The `BlocListener` in `DeletePostButton` MUST then:
1. Show a success snackbar (`t.posts.deletePost.success`).
2. Call `router.pop()` to return to the previous screen.

### FR-06 Post list freshness
`UserPostsCubit` MUST subscribe to `PostEventBus` and, upon receiving
`PostDeleted(id)`, remove the matching post from the in-memory `UserPostsLoaded`
list without making a network request. Unknown IDs MUST be a no-op.

### FR-07 Failure flow
On any server error the cubit MUST emit `DeletePostFailure(failure)`.
The `BlocListener` MUST show an error snackbar and leave the detail screen open
so the user can retry or navigate away manually.

### FR-08 Cancel / dismiss
Cancelling the confirmation dialog (via Cancel button or back gesture) MUST emit
`DeletePostInitial` without any API call or navigation.

### FR-09 No dedicated route
`delete_post` has no screen of its own. All presentation is embedded in
`PostDetailsScreen` via `DeletePostButton`. No route file is created.

### FR-10 Localisation
All user-facing strings MUST use `slang` keys under `posts.deletePost`. No
hardcoded strings. Keys: `tooltip`, `confirmTitle`, `confirmMessage`,
`confirmButton`, `cancelButton`, `success`, `errors.forbidden`, `errors.generic`.

---

## Non-Functional Requirements

### NFR-01 Architecture compliance
- `domain/` MUST NOT import Flutter or Dio packages.
- `DeletePostAdapter` MUST use the double-catch pattern with `AppLogger`.
- `PostEventBus` MUST live in `features/posts/_shared/`, not in `core/`.
- No slice outside `delete_post/` and `_shared/` may be modified except:
  `post_details_route.dart`, `post_details_screen.dart`, `user_posts_cubit.dart`.

### NFR-02 DI
`DeletePostCubit` MUST be `@injectable` (transient, one instance per route).
`DeletePostAdapter` MUST be `@LazySingleton(as: DeletePostPort)`.
`PostEventBus` MUST be `@lazySingleton`.

### NFR-03 No new pubspec dependency
No new package may be added to `pubspec.yaml`.

### NFR-04 Codegen
After modifying `posts_api_client.dart`, `delete_post_state.dart`, or any slang
JSON file, `dart run build_runner build --delete-conflicting-outputs` MUST be run
and produce no errors.

### NFR-05 Static analysis
`dart analyze` MUST report zero warnings or errors after the change.
