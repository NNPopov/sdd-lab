# PRD 0023 — `erase_db_post` slice

## Problem Statement

A superuser has no in-app way to remove an arbitrary post published by another user.
Harmful or policy-violating content can only be removed via a direct database operation
outside the application, making moderation slow and error-prone.

## Solution

Add a superuser-only erase action to the Post Details screen. The button is visible
exclusively when the current user is a superuser **and** is not the post's owner
(owners use the existing `delete_post` action for their own content). Tapping the
button presents a confirmation dialog. On confirmation, the post is permanently erased
via the server API. The superuser is returned to the previous screen and the post is
immediately removed from the in-memory posts list without a network round-trip.

## User Stories

1. As a superuser, I want an erase button on any post detail page that does not belong
   to me, so that I can remove policy-violating or harmful content directly from the app.
2. As a superuser, I want the erase button to be invisible on posts I own, so that I
   use the standard delete action for my own content and am not confused by two delete
   controls.
3. As a regular user (non-superuser), I want the erase button to be completely hidden,
   so that I am never exposed to moderation controls I am not permitted to use.
4. As a superuser, I want a confirmation dialog before the erasure proceeds, so that I
   do not accidentally remove a post.
5. As a superuser, I want the confirmation dialog to clearly state that the action is
   irreversible, so that I understand the consequences before confirming.
6. As a superuser, I want to be able to cancel the confirmation dialog without side
   effects, so that I can change my mind freely.
7. As a superuser, I want a loading indicator while the erase request is in flight, so
   that I know the app is working.
8. As a superuser, I want the confirm button to be disabled while the request is in
   flight, so that I cannot submit the erasure twice.
9. As a superuser, I want a success notification after erasure, so that I know the post
   was removed successfully.
10. As a superuser, I want to be returned to the previous screen after a successful
    erasure, so that I am not left on a detail page for a post that no longer exists.
11. As a superuser, I want the erased post to disappear from the posts list immediately
    on return, so that I do not see stale content after navigating back.
12. As a superuser, I want to see an error message if the erasure fails, so that I know
    something went wrong and can retry.
13. As a superuser, I want the detail page to remain open if erasure fails, so that I
    can retry or navigate away manually.
14. As a non-superuser attempting erasure by bypassing the UI (e.g. via a deep link),
    I want the use-case to return a PermissionDenied failure, so that the superuser
    check is enforced end-to-end and not only in the UI.
15. As a superuser, I want the erase feature to work correctly regardless of how I
    arrived at the post (posts list, deep link, another navigation path), so that the
    feature is reliable in all contexts.

## Implementation Decisions

### Slice structure

A new `erase_db_post` slice is added under `features/posts/`, following the same
vertical-slice layout used by all other posts slices:
`domain/` → `data/` → `application/` → `presentation/`.

### API contract

- Method: `DELETE`
- Path: `/api/v1/{username}/db_post/{id}`
- Auth: bearer token required; caller must be a superuser
- Success: `2xx` (no body)
- Errors: `401` unauthorized, `403` forbidden (not a superuser), `404` not found,
  `5xx` server error
- One new annotated method is added to the shared `PostsApiClient` Retrofit interface.

### State machine (`EraseDbPostState`)

Sealed freezed class with five variants, mirroring `DeletePostState`:
- `initial` — idle, no action in progress
- `confirming` — confirmation dialog is open
- `deleting` — DELETE request is in flight
- `success` — server confirmed erasure
- `failure(Failure)` — server returned an error

### Superuser enforcement (dual-layer)

- **Presentation layer:** the erase button is rendered only when
  `currentUser.isSuperuser == true` **and** `currentUser.username != post.author.username`.
  When the current user is the owner of the post, only the standard `delete_post` button
  is shown, regardless of superuser status.
- **Use-case layer:** `EraseDbPostUseCase` receives `isSuperuser` as a call-site
  parameter (read by the cubit from `AuthCubit`) and returns
  `Left(Failure.permissionDenied())` when it is `false`. Mirrors the pattern in
  `EraseDbUserUseCase`. The "not your own post" rule is not duplicated in the use-case —
  it is a UI concern and the server enforces what it needs to.

### Cubit wiring

`EraseDbPostCubit` constructor accepts only injected dependencies
(`EraseDbPostUseCase`, `AuthCubit`). Runtime values (`username`, `id`) are passed as
arguments to `confirmAndErase(username, id)`, consistent with all other cubits in the
posts feature. `isSuperuser` is read from `AuthCubit.currentUser` inside the cubit
and forwarded to the use-case. The cubit is provided alongside `PostDetailsCubit` and
`DeletePostCubit` via `MultiBlocProvider` in the post details route.

### Post list freshness via event bus

`EraseDbPostCubit` reuses the existing `PostEventBus` singleton in
`features/posts/_shared/`. On success it publishes `PostDeleted(int id)`, which
`UserPostsCubit` already handles by removing the matching post from its in-memory list
without a network request. No changes to `PostEventBus` or `PostEvent` are required.

### Presentation widget

A dedicated `EraseDbPostButton` widget encapsulates the `BlocProvider`,
`BlocListener` (success/failure reactions), and the `AlertDialog` confirmation UI.
`PostDetailsScreen` places this widget in the AppBar alongside the existing edit and
delete buttons. It is mounted only when `currentUser.isSuperuser == true` and
`currentUser.username != post.author.username`. Mirrors the `delete_post_button` and
`erase_db_user_button` patterns.

### Success path

1. Superuser taps the erase button → `cubit.requestConfirmation()` → state:
   `confirming`, dialog appears.
2. Superuser taps the confirm button → `cubit.confirmAndErase(username, id)` →
   state: `deleting`.
3. Server returns `2xx` → state: `success`. `BlocListener` shows a
   `ScaffoldMessenger` snackbar, then calls `router.pop()`.
4. `PostEventBus` emits `PostDeleted(id)` → `UserPostsCubit` removes the post from
   its list.

### Failure path

Server returns an error → state: `failure(Failure)`. `BlocListener` shows a
`ScaffoldMessenger` snackbar. State resets to `initial`. Detail screen stays open.
Superuser may retry or navigate away.

### Adapter error mapping

The adapter follows the project's double-catch pattern with `AppLogger`:
- `401` → `Failure.unauthorized`
- `403` → `Failure.forbidden`
- `404` → `Failure.notFound`
- `5xx` → `Failure.serverError`
- Catch-all `catch (e, st)` with logging → `Failure.unknown`

### Localisation

New key group `posts.eraseDbPost` added to both `en.json` and `ru.json`:
- `tooltip` — icon button accessibility label
- `confirmTitle` — dialog heading
- `confirmMessage` — body text (states action is irreversible)
- `confirmButton` — destructive action label
- `cancelButton` — dismiss label
- `success` — snackbar text on successful erasure
- `errors.forbidden` — snackbar text when caller is not a superuser
- `errors.generic` — snackbar text for all other failures

## Testing Decisions

Good tests verify observable external behaviour through the public interface of a
module, not internal wiring or implementation details.

| Module | What to assert |
|---|---|
| `EraseDbPostUseCase` | Returns `Left(permissionDenied)` when `isSuperuser` is `false`; delegates to port and returns its result when `isSuperuser` is `true`. |
| `EraseDbPostAdapter` | Success path returns `Right(unit)`; each HTTP error code maps to the correct `Failure`; unexpected exception triggers `AppLogger.error` and returns `Failure.unknown`. |
| `EraseDbPostCubit` | Full state machine via `bloc_test`: `initial → confirming`, `confirming → deleting → success`, `confirming → deleting → failure`, `cancel` resets to `initial`. |
| Widget (`EraseDbPostButton`) | Renders the icon when `isSuperuser && !isOwner`; hidden for non-superusers; hidden when current user is the owner; confirmation dialog appears on tap; loading state disables the confirm button; success triggers snackbar + pop; failure triggers snackbar only. |

Prior art: `test/features/posts/delete_post/`, `test/features/users/erase_db_user/`.

## Out of Scope

- Erasure from the posts list screen (no swipe-to-delete for superusers on list tiles).
- Bulk erasure of multiple posts.
- Audit log or moderation history for erased posts.
- Push notification to the post author when their post is erased by a superuser.
- Soft delete / trash / undo functionality.
- Erasure of posts by non-superuser moderator roles.
- Updating the paginated post count after erasure.

## Further Notes

- `erase_db_user` in `features/users/` is the primary reference for the superuser
  permission pattern (dual-layer check, `isSuperuser` as call parameter).
- `delete_post` in `features/posts/` is the primary reference for the state machine
  shape, event bus wiring, and button/dialog presentation pattern.
- The `PostEventBus` and `PostEvent` sealed class require no modification — `PostDeleted`
  already covers this case.
- The visibility rule (erase button hidden when current user is the owner) is enforced
  only in the UI; the use-case does not duplicate it.
