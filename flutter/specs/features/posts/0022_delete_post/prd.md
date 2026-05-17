# PRD 0022 — `delete_post` slice

## Problem Statement

A post author has no way to remove a post they have published. Once a post is created
it persists indefinitely regardless of the author's intent, leaving users without
control over their own content.

## Solution

Add a delete action to the Post Details screen, visible exclusively to the post's
owner. Tapping the button presents a confirmation dialog to prevent accidental
deletion. On confirmation, the post is permanently erased via the server API. The
user is returned to the previous screen and the post is immediately removed from the
in-memory posts list without a network round-trip.

## User Stories

1. As a post author, I want a delete button on my post's detail page, so that I can
   remove content I no longer want published.
2. As a post author, I want the delete button to appear only when I am viewing my own
   post, so that I am not confused by controls that do not apply to me.
3. As a viewer (non-owner), I want the delete button to be hidden when I view another
   user's post, so that I am not exposed to actions I am not permitted to perform.
4. As a post author, I want a confirmation dialog before deletion proceeds, so that I
   do not accidentally erase a post.
5. As a post author, I want the confirmation dialog to clearly state that the action
   is irreversible, so that I understand the consequences before confirming.
6. As a post author, I want to be able to cancel out of the confirmation dialog without
   side effects, so that I can change my mind freely.
7. As a post author, I want a loading indicator while the delete request is in flight,
   so that I know the app is working.
8. As a post author, I want the confirm button to be disabled while the request is in
   flight, so that I cannot submit the deletion twice.
9. As a post author, I want a success notification after deletion, so that I know the
   post was removed successfully.
10. As a post author, I want to be returned to the previous screen after a successful
    deletion, so that I am not left on a detail page for a post that no longer exists.
11. As a post author, I want the deleted post to disappear from my posts list
    immediately on return, so that I do not see stale content after navigating back.
12. As a post author, I want to see an error message if deletion fails, so that I know
    something went wrong and can retry.
13. As a post author, I want the detail page to remain open if deletion fails, so that
    I can retry or navigate away manually.
14. As a non-owner attempting deletion by bypassing the UI (e.g. via a deep link), I
    want the use-case to return a Forbidden failure, so that ownership is enforced
    end-to-end and not only in the UI.
15. As a post author, I want the delete feature to work correctly regardless of how I
    arrived at the post (posts list, deep link, another navigation path), so that the
    feature is reliable in all contexts.

## Implementation Decisions

### Slice structure

A new `delete_post` slice is added under `features/posts/`, following the same
vertical-slice layout used by `create_post`, `edit_post`, and `post_details`:
`domain/` → `data/` → `application/` → `presentation/`.

### API contract

- Method: `DELETE`
- Path: `/api/v1/{username}/post/{id}`
- Auth: bearer token required
- Success: `2xx` (no body)
- Errors: `401` unauthorized, `403` forbidden (not the owner), `404` not found,
  `5xx` server error
- One new annotated method is added to the shared `PostsApiClient` Retrofit interface.

### State machine (`DeletePostState`)

Sealed freezed class with five variants, mirroring `DeleteUserState`:
- `initial` — idle, no action in progress
- `confirming` — confirmation dialog is open
- `deleting` — DELETE request is in flight
- `success` — server confirmed deletion
- `failure(Failure)` — server returned an error

### Ownership enforcement (dual-layer)

- **Presentation layer:** the delete button is rendered only when
  `AuthCubit.currentUser?.username` matches the post author's username. Mirrors the
  existing edit button visibility check in `PostDetailsScreen`.
- **Use-case layer:** `DeletePostUseCase` reads `AuthCubit.currentUser` (injected) and
  returns `Left(Failure.forbidden(...))` if the username does not match the target.
  Mirrors the pattern in `EditPostUseCase` and `CreatePostUseCase`.

### Cubit wiring

`DeletePostCubit` constructor accepts only injected dependencies
(`DeletePostUseCase`, `AuthCubit`). Runtime values (`username`, `id`) are passed as
arguments to `confirmAndDelete(username, id)`, consistent with all other cubits in the
posts feature. The cubit is provided alongside `PostDetailsCubit` via
`MultiBlocProvider` in the post details route.

### Post list freshness via event bus

A new `PostEventBus` singleton (`StreamController<PostEvent>`, `@lazySingleton`) is
added to `features/posts/_shared/`. `DeletePostCubit` publishes a `PostDeleted(int id)`
event on success. `UserPostsCubit` subscribes to this stream and removes the matching
post from its in-memory list by ID, without making a network request. The `PostEvent`
sealed class contains only `PostDeleted(int id)` at this time. The bus must not live in
`core/` — `core/` must not know about features.

### Presentation widget

A dedicated `DeletePostButton` widget encapsulates the `BlocProvider`,
`BlocListener` (success/failure reactions), and the `AlertDialog` confirmation UI.
`PostDetailsScreen` places this widget in the AppBar alongside the existing edit
button, mounted only when the current user is the post author. Mirrors the
`delete_account_button` pattern from the `delete_user` slice.

### Success path

1. User taps the delete button → `cubit.requestConfirmation()` → state: `confirming`,
   dialog appears.
2. User taps the confirm button → `cubit.confirmAndDelete(username, id)` →
   state: `deleting`.
3. Server returns `2xx` → state: `success`. `BlocListener` shows a
   `ScaffoldMessenger` snackbar then calls `router.pop()`.
4. `PostEventBus` emits `PostDeleted(id)` → `UserPostsCubit` removes the post from
   its list.

### Failure path

1. Server returns an error → state: `failure(Failure)`. `BlocListener` shows a
   `ScaffoldMessenger` snackbar. State resets to `initial`. Detail screen stays open.
   User may retry or navigate away.

### Adapter error mapping

The adapter follows the project's double-catch pattern with `AppLogger`:
- `401` → `Failure.unauthorized`
- `403` → `Failure.forbidden`
- `404` → `Failure.notFound`
- `5xx` → `Failure.serverError`
- Catch-all `catch (e, st)` with logging → `Failure.unknown`

### Localisation

New key group `posts.deletePost` added to both `en.json` and `ru.json`:
- `tooltip` — icon button accessibility label
- `confirmTitle` — dialog heading
- `confirmMessage` — body text (states action is irreversible)
- `confirmButton` — destructive action label
- `cancelButton` — dismiss label
- `success` — snackbar text on successful deletion
- `errors.forbidden` — snackbar text when user is not the owner
- `errors.generic` — snackbar text for all other failures

## Testing Decisions

Testing scope will be determined in a separate task. When that task is undertaken,
good tests should verify observable external behaviour through the public interface of
a module, not internal wiring or implementation details.

Candidates for unit tests:

| Module | What to assert |
|---|---|
| `DeletePostUseCase` | Returns `Left(forbidden)` when `currentUser` is null or username mismatches; delegates to port and returns its result otherwise. |
| `DeletePostCubit` | Full state machine via `bloc_test`: `initial → confirming`, `confirming → deleting → success`, `confirming → deleting → failure`, `cancel` resets to `initial`. |
| `UserPostsCubit` (modified) | `PostDeleted(id)` event removes the matching post; unknown ID is a no-op. |

Prior art: `test/features/posts/create_post/`, `test/features/users/delete_user/`.

## Out of Scope

- Deletion from the posts list screen (no swipe-to-delete on list tiles).
- Bulk deletion of multiple posts.
- Soft delete / trash / undo functionality.
- Admin or moderator deletion of another user's posts.
- Push notification to followers when a post is deleted.
- Updating the paginated post count after deletion.
- Conflict detection or server-side tombstoning.

## Further Notes

- `delete_user` in `features/users/` is the primary reference implementation for the
  entire slice structure, state machine shape, and button/dialog pattern.
- The sealed `PostEvent` class must remain minimal. Extension to cover other post
  lifecycle events (e.g. `PostUpdated`) is explicitly deferred until a concrete need
  arises.
- The `PostEventBus` is scoped to `features/posts/_shared/` to respect the
  `core/`-knows-nothing-about-features constraint.
