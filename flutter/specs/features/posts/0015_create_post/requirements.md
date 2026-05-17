# 0015 · create_post — Requirements

## Functional Requirements

| ID | Requirement |
|---|---|
| F1 | The route `/user/:username/posts/create` opens the post creation page |
| F2 | An unauthenticated user is redirected to `/login` (AuthGuard) |
| F3 | The form contains three fields: Title (required), Media URL (optional), Text (required) |
| F4 | Title: minimum 2, maximum 30 characters; a validation error is displayed below the field |
| F5 | Media URL: if entered — not an empty string; a validation error is displayed below the field |
| F6 | Text: minimum 100, maximum 63206 characters; a validation error is displayed below the field |
| F7 | A live preview of the rendered Markdown is displayed below the Text field, updating in real time as the user types |
| F8 | The "Publish" button is disabled while the request is being sent |
| F9 | A loading indicator is displayed during submission |
| F10 | After successful publishing, the user is returned to `/user/:username/posts` |
| F11 | After returning, the list of posts is refreshed (calling `UserPostsCubit.refresh()`) |
| F12 | On a request error, an inline error message is displayed without a dialog; the button is re-enabled |
| F13 | The use-case checks ownership: if `data.username != currentUser.username` — returns `ForbiddenFailure` without calling the API |
| F14 | The screen scrolls vertically — the form and preview are visible in a single stream without tabs |

## Non-functional Requirements

| ID | Requirement |
|---|---|
| N1 | All UI strings via slang — no hardcoding (`context.t.posts.createPost.*`) |
| N2 | `Post` entity and `PostDto` are moved to `_shared/` and extended with `mediaUrl` and `createdByUserId` fields |
| N3 | Import updates in `user_posts` are performed in the same change as the move |
| N4 | `CreatePostRequestDto` lives in `_shared/data/dto/` (used by `PostsApiClient`) |
| N5 | `NewPostData` is a simple immutable Dart class without freezed |
| N6 | The adapter implements the double catch pattern per CLAUDE.md §8.4 |
| N7 | Live preview is managed by `TextEditingController` in the widget, no state in Cubit |
| N8 | `CreatePostState` — `sealed class` + `freezed`: initial, loading, success, error(Failure) |
| N9 | The link to `UserPostsCubit` is only via `BlocListener` in presentation, not in Cubit/UseCase |
| N10 | The slice does not import other slices of the `posts` feature (except `UserPostsCubit` in presentation) |
| N11 | `flutter_markdown` is added to `pubspec.yaml` with a coordinated version |

## Out of Scope

- Editing an existing post (`edit_post`)
- Deleting a post (`delete_post`)
- Post detail page with full Markdown rendering (`post_details`)
- A button to navigate to the post creation screen from other screens
- URL format validation for the Media URL field on the client
- File image upload (text link only)
- Post drafts
- Widget tests for `CreatePostScreen` (desirable but not required for MVP)
