# 0015 · create_post — PRD

## Problem Statement

The user is authenticated in the app and wants to publish a post under their own name.
Currently the app provides no way to create a post via the UI: the user can only
view other people's posts. The user is forced to use external tools
(curl, Swagger) to create content, which is unacceptable for a finished product.

## Solution

Add a post creation screen at the route `/user/:username/posts/create`.
The screen is available only to the authenticated user and only for their own username.
The form contains Title, Media URL (optional), and Text (markdown) fields.
Below the Text field is a live preview of the rendered markdown that updates in real time.
After successful creation the user is returned to the `/user/:username/posts` screen
with the updated list of posts.

## User Stories

1. As an authenticated user, I want to navigate to the post creation page at the URL `/user/myusername/posts/create` so that I get a post creation form.
2. As an authenticated user, I want to enter a post title (2–30 characters) so that I can give the post a name.
3. As an authenticated user, I want to enter an optional media URL so that I can attach an image to the post.
4. As an authenticated user, I want to enter post text in Markdown format (minimum 100 characters) so that I can write a substantive post.
5. As an authenticated user, I want to see a live Markdown preview directly below the text input field so that I can see how the post will look before publishing.
6. As an authenticated user, I want to see a validation error below the field if fewer than 2 characters are entered in Title so that I understand what needs to be fixed.
7. As an authenticated user, I want to see a validation error if Title is longer than 30 characters so that I know about the limit.
8. As an authenticated user, I want to see a validation error if Text is shorter than 100 characters so that I do not submit a post that is too short.
9. As an authenticated user, I want to see a validation error if Text is longer than 63206 characters so that I know about the limit.
10. As an authenticated user, I want to see a validation error if the Media URL field is entered but is an empty string so that I do not submit an invalid URL.
11. As an authenticated user, I want to tap the "Publish" button and see a loading indicator while the post is being sent to the server.
12. As an authenticated user, I want to automatically return to `/user/:username/posts` with the updated list after successful publishing so that I can immediately see the published post.
13. As an authenticated user, I want to see an error message on the screen (without a dialog) if the post creation request fails so that I understand what went wrong and can try again.
14. As an authenticated user, I want the "Publish" button to be disabled during loading so that I cannot accidentally submit the post twice.
15. As an unauthenticated user, I want to be redirected to the login screen when attempting to navigate to `/user/:username/posts/create` so that the system protects access.
16. As an authenticated user, I want to receive a ForbiddenFailure error when attempting to create a post under another user's name (username in URL ≠ my username) so that it is impossible to publish posts on behalf of other people.
17. As a user, I want to scroll the screen down to see both the form and the preview at the same time, not split across tabs.

## Implementation Decisions

### New modules

- **`create_post` slice** — new slice in `features/posts/create_post/` with the standard structure: `domain/`, `data/`, `application/`, `presentation/`.

### Changes to existing modules

- **`PostsApiClient`** (`_shared/data/`) — add a method `POST /{username}/post` that accepts `CreatePostRequestDto` and returns `PostDto`.
- **`Post` entity** — add fields `mediaUrl` (nullable) and `createdByUserId`. Move from `user_posts/domain/entities/` to `_shared/domain/entities/`. Update imports in `user_posts`.
- **`PostDto`** — add fields `media_url` and `created_by_user_id`. Move from `user_posts/data/dto/` to `_shared/data/dto/`. Update imports in `user_posts`.
- **`AppRouter`** — add `CreatePostRoute` with path `/user/:username/posts/create` and `authGuard`.
- **`PostsFeatureModule`** — no changes (adapter is registered via the `@LazySingleton` annotation).
- **`pubspec.yaml`** — add `flutter_markdown` dependency.

### Domain layer (`create_post/domain/`)

- **`NewPostData`** — value object: `username`, `title`, `text`, `mediaUrl?`. Simple immutable Dart class, no freezed.
- **`CreatePostPort`** — narrow port with one method: `Future<Either<Failure, void>> call(NewPostData data)`.
- **`CreatePostUseCase`** — orchestrates: (1) checks ownership (`data.username == currentUser.username`), otherwise `Left(ForbiddenFailure())`; (2) delegates to `CreatePostPort`.

### Data layer (`create_post/data/`)

- **`CreatePostRequestDto`** — freezed + json_serializable: fields `title`, `text`, `media_url?`.
- **`CreatePostAdapter`** — implements `CreatePostPort`. Double catch per CLAUDE.md §8.4. Mapping: `DioException` → corresponding `Failure`, catch-all → `UnknownFailure` + logging.

### Application layer (`create_post/application/`)

- **`CreatePostState`** — sealed class via freezed: `initial`, `loading`, `success`, `error(Failure)`.
- **`CreatePostCubit`** — method `submit(NewPostData data)`. On success emits `success`, the UI listens via `BlocListener` and navigates back + calls `UserPostsCubit.refresh()`.

### Presentation layer (`create_post/presentation/`)

- **`CreatePostRoute`** — `@RoutePage()`, receives `@PathParam username`, provides `CreatePostCubit` via `BlocProvider`.
- **`CreatePostScreen`** — `StatefulWidget` (for `GlobalKey<FormState>`). Contains `Form` with three `TextFormField` (title, media_url, text) + live markdown preview below the text field. `BlocConsumer`: builder — shows loading/error; listener — navigation on success.

### Validation (in the form, not in Cubit)

| Field | Rules |
|---|---|
| Title | required, length 2–30 characters |
| Media URL | optional; if entered — not an empty string |
| Text | required, length 100–63206 characters |

### Ownership check (in use-case)

The use-case gets `CurrentUser` from `AuthCubit` via `get_it` and compares `data.username` with `currentUser.username`. Mismatch → `Left(ForbiddenFailure())`.

### API contract

- **Endpoint:** `POST /api/v1/{username}/post`
- **Request body:** `{ "title": string, "text": string, "media_url": string | null }`
- **Response:** `{ "id": int, "title": string, "text": string, "media_url": string | null, "created_by_user_id": int, "created_at": datetime }`
- **Auth:** Bearer token (via the existing `AuthInterceptor`)

### Navigation after success

`BlocListener` in `CreatePostScreen` catches `CreatePostSuccess`, calls `context.router.maybePop()`, then `context.read<UserPostsCubit>().refresh()`. Direct import of `UserPostsCubit` from the `create_post` presentation layer is acceptable — the connection is via UI per CLAUDE.md §4.

### Route

`/user/:username/posts/create` — flat route (not a child) in `AppRouter`, protected by `authGuard`.

## Testing Decisions

### What to test

Good tests verify the external behaviour of a module through its public interface, not implementation details. For this slice:

- **`CreatePostUseCase`** — unit test: verify ownership check (another user's username → ForbiddenFailure), success scenario (port call + Right(void)), port error is propagated.
- **`CreatePostAdapter`** — unit test: successful request → Right(void), DioException 403 → Left(ForbiddenFailure), catch-all (TypeError in mapper) → Left(UnknownFailure) + logger call.
- **`CreatePostCubit`** — `bloc_test`: `submit` on success emits `[loading, success]`; on error emits `[loading, error(failure)]`.

### Prior art

- Analogous unit tests for use-cases: `test/features/users/`
- Analogous cubit tests: `test/features/tiers/`
- Mocks via `mocktail` (not mockito)

### What not to test in this slice

Widget tests for `CreatePostScreen` — desirable but not required for MVP.

## Out of Scope

- Editing an existing post (separate `edit_post` slice)
- Deleting a post (separate `delete_post` slice)
- Post detail page with Markdown rendering (`post_details`)
- Navigation to `CreatePostScreen` via a button on any screen (buttons will be added later)
- URL format validation for the Media URL field on the client
- File image upload (media_url — text link only)
- Post drafts

## Further Notes

- The `flutter_markdown` package is being added to the project for the first time. Coordinate the version with `pubspec.yaml` before implementation.
- Live preview renders the `text` field in real time via `TextEditingController`. No additional state in Cubit is needed for this — the controller manages the preview directly in the widget.
- `PostDto` and the `Post` entity when moved to `_shared/` require updating imports in `user_posts`. This must be done in the same commit to avoid breaking `user_posts`.
