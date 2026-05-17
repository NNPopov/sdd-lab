# PRD 0021 — `edit_post` slice

## Problem Statement

A post author has no way to correct or update a post after publishing it. If a typo
slips in, the content needs updating, or the media URL changes, the user is forced to
delete and recreate the post — losing its identity and any associated metadata.

## Solution

Add an Edit Post screen reachable from the Post Details screen. Only the post author
sees an edit button in the AppBar. Tapping it opens a pre-filled form (title, text,
media URL) identical in layout to Create Post, with a live markdown preview. On save
the post is updated via PATCH and the user is returned to the refreshed Post Details
screen.

## User Stories

1. As a logged-in post author, I want to see an edit icon in the AppBar when viewing
   my own post, so that I can tell at a glance that the post is editable by me.
2. As a logged-in user viewing someone else's post, I want the edit icon to be hidden,
   so that I am never tempted to edit content I do not own.
3. As a post author, I want to tap the edit icon and be taken to a pre-filled edit
   form, so that I can see the current content before changing anything.
4. As a post author, I want the title field to be pre-filled with the current title,
   so that I only need to change what I intend to.
5. As a post author, I want the body (text) field to be pre-filled with the current
   body, so that I can make targeted edits without retyping.
6. As a post author, I want the media URL field to be pre-filled with the current URL
   (or empty if none), so that I can update or clear it as needed.
7. As a post author, I want to see a live markdown preview while editing the body,
   so that I can verify formatting before saving.
8. As a post author, I want the title and body fields to be required with inline
   validation, so that I cannot accidentally save an empty title or empty body.
9. As a post author, I want the media URL field to be optional, so that I can save a
   post without attaching any media.
10. As a post author, I want to tap a Save button and see a loading indicator while
    the request is in flight, so that I know the app is working.
11. As a post author, I want to be returned to the Post Details screen with updated
    content after a successful save, so that I can immediately verify my changes.
12. As a post author, I want to see an error message if the update fails (network
    error, server error), so that I know the save did not go through.
13. As a post author, I want to tap the back button or the system back gesture to
    cancel editing without saving, so that I can exit without unintended changes.
14. As a post author, I want the Save button to be disabled while a save is in
    progress, so that I cannot submit the form twice.
15. As a post author trying to edit another user's post (e.g. via deep link), I want
    the use-case to return a Forbidden failure, so that the server-side constraint is
    mirrored client-side.

## Implementation Decisions

### Slice structure
A new `edit_post` slice is added under `features/posts/`, following the same
vertical-slice layout as `create_post` and `post_details`:
`domain/` → `data/` → `application/` → `presentation/`.

### Entry point
The edit button is an `IconButton` (`Icons.edit_outlined`) placed in the `AppBar`
`actions` of `PostDetailsScreen`. It is rendered conditionally: only when
`AuthCubit.currentUser?.username == username` (the route path param already carries
the post author's username).

### Navigation
`PostDetailsScreen` awaits `context.pushRoute(EditPostRoute(post: post))`. After the
await returns, it calls `postDetailsCubit.load(username, id)` to refresh the post.
The `Post` domain object is passed directly as a typed `auto_route` parameter
(no serialisation to path params needed).

### Edit form
The edit form mirrors `CreatePostScreen` in structure: a `Form` with three fields
(title, text, media URL) and a live markdown preview below the text field. Validation
rules are identical to `create_post`: title non-empty, text non-empty, media URL
optional.

### MarkdownPreview widget
`MarkdownPreview` is moved from `create_post/presentation/widgets/` to
`posts/_shared/presentation/widgets/`, because both `create_post` and `edit_post`
need it.

### State model (`EditPostState`)
Sealed class with four variants: `initial`, `loading`, `success`, `error(Failure)`.

### Use-case authorisation
`EditPostUseCase` reads `AuthCubit.currentUser`. If the username does not match
`UpdatedPostData.username` it returns `Left(Failure.forbidden(...))` without calling
the port.

### Value object
`UpdatedPostData` carries `username`, `id`, `title`, `text`, and optional `mediaUrl`.

### Port
`EditPostPort` is a narrow interface with a single `call(UpdatedPostData)` method
returning `Either<Failure, void>`.

### Adapter
`EditPostAdapter` implements `EditPostPort`, calls `PostsApiClient.patchPost`, and
follows the double-catch pattern with `AppLogger`.

### API client
A new `patchPost` method is added to `PostsApiClient` (in `_shared/data/`):
`PATCH /{username}/post/{id}` with an `UpdatePostRequestDto` body.

### DTO
`UpdatePostRequestDto` (freezed, json_serializable) lives in `_shared/data/dto/`
alongside `CreatePostRequestDto`. Fields: `title` (required String), `text`
(required String), `mediaUrl` (optional String, `@JsonKey(name: 'media_url')`).

### Error mapping
HTTP errors follow the same mapping as `CreatePostAdapter`:
401 → `unauthorized`, 403 → `forbidden`, 422 → `validation`, 5xx → `server`,
connection error → `network`.

### Localisation
New keys added under `posts.editPost` in all locale JSON files:
`title` (AppBar title), `saveButton`, `titleHint`, `textHint`, `mediaUrlHint`,
`successMessage` (optional snackbar), and error messages reusing
`posts.createPost.errors.*` where identical.

## Testing Decisions

Good tests verify observable behaviour through the public interface of a module,
not its internal wiring. They should not know which private methods are called.

### Units under test

| Module | What to assert |
|---|---|
| `EditPostUseCase` | Returns `Left(forbidden)` when `currentUser` is null or username mismatch; delegates to port and returns its result otherwise. |
| `EditPostCubit` | Emits `loading` then `success` on port success; emits `loading` then `error(failure)` on port failure. |
| `EditPostAdapter` | Maps 401/403/422/5xx/connection DioExceptions to correct `Failure` variants; maps success response to `Right(null)`; outer catch returns `Left(unknown)`. |

### Prior art
- `test/features/posts/create_post/` — cubit test with `bloc_test`, adapter test
  with `mocktail`
- `test/features/users/delete_user/` — use-case authorisation guard pattern

### Widget tests (recommended, not required for v1)
`EditPostScreen` with a mocked `EditPostCubit`: assert form is pre-filled, Save
button triggers `cubit.submit`, loading state disables the button, error state shows
a snackbar.

## Out of Scope

- Editing posts on behalf of other users (admin capability).
- Partial PATCH — the adapter always sends all three fields.
- Optimistic UI updates (the details screen always reloads from the server).
- Conflict detection (last-write-wins; no ETag handling).
- Image upload — media URL is a plain text field.
- Delete post from the edit screen.

## Further Notes

- The `Post` domain entity already contains all fields needed to pre-fill the form
  (`title`, `text`, `mediaUrl`). No schema change to `_shared/domain/entities/post.dart`
  is required.
- The `username` available in `PostDetailsPage` route params is the post author's
  username (it comes from the route path `/{username}/post/{id}`), so no additional
  field is needed on `Post` to derive author identity for the visibility check.
- `MarkdownPreview` is a stateless presentational widget with no slice-specific
  dependencies; moving it to `_shared` is purely mechanical.
