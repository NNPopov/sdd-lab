# 0021 · edit_post — Requirements

## Functional Requirements

| ID | Requirement |
|---|---|
| F1 | The Edit button (`Icons.edit_outlined`) is displayed in the `PostDetailsScreen` AppBar only when the post is loaded and the current user is the post author |
| F2 | For unauthenticated users and for users viewing another user's post, the Edit button is hidden |
| F3 | Tapping Edit opens `EditPostScreen` with pre-filled fields: title, text, mediaUrl from the `Post` object |
| F4 | Title: minimum 2, maximum 30 characters; a validation error is displayed below the field |
| F5 | Media URL: if entered — not an empty string; a validation error is displayed below the field; the field is optional |
| F6 | Text: minimum 100, maximum 63206 characters; a validation error is displayed below the field |
| F7 | A live preview of the rendered Markdown is displayed below the Text field, updating in real time |
| F8 | The Save button is disabled while the request is being sent |
| F9 | A loading indicator is displayed during submission |
| F10 | After successful saving, the user is returned to `PostDetailsScreen` |
| F11 | After returning, `PostDetailsScreen` reloads the post (`PostDetailsCubit.load(username, id)`) |
| F12 | On a request error, an inline error message is displayed without a dialog; the button is re-enabled |
| F13 | The use-case checks ownership: if `currentUser == null` or `currentUser.username != data.username` — returns `Left(ForbiddenFailure)` without calling the API |
| F14 | Tapping Back or using the system back gesture cancels editing without saving |
| F15 | The screen scrolls vertically — the form and preview are visible in a single stream |

## Non-functional Requirements

| ID | Requirement |
|---|---|
| N1 | All UI strings via slang — no hardcoding (`context.t.posts.editPost.*`) |
| N2 | `MarkdownPreview` is moved to `posts/_shared/presentation/widgets/` and accepts `label` as a parameter |
| N3 | The `MarkdownPreview` import in `create_post_screen.dart` is updated to the new path |
| N4 | `UpdatePostRequestDto` lives in `_shared/data/dto/` (used by `PostsApiClient`) |
| N5 | `UpdatedPostData` is a simple immutable Dart class without freezed |
| N6 | The adapter implements the double catch pattern per CLAUDE.md §8.4 |
| N7 | Live preview is managed by `TextEditingController` in the widget, no state in Cubit |
| N8 | `EditPostState` — `sealed class` + `freezed`: initial, loading, success, error(Failure) |
| N9 | `PostDetailsScreen` is converted to `StatefulWidget` for correct `mounted` checking |
| N10 | `EditPostRoute` is registered in `app_router.dart` with `authGuard` |
| N11 | The slice does not import other slices of the `posts` feature |
| N12 | `username` is passed to `EditPostRoute` as a named parameter, not via path |

## Out of Scope

- Editing posts on behalf of another user (admin capability)
- Partial PATCH — the adapter always sends all three fields
- Optimistic UI updates — the post details reload from the server
- Conflict detection (ETag, last-write-wins without checking)
- Image upload — media URL is a text field only
- Deleting a post from the edit screen
- Widget tests for `EditPostScreen` (desirable, not required for v1)
