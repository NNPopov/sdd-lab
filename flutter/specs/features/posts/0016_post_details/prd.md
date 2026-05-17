# 0016 · post_details — PRD

## Problem Statement

The user sees posts in the feed (`list_posts`) and on the user page (`user_posts`),
but cannot open an individual post to read it in full. The text in the list is truncated,
Markdown is not rendered. There is no public page for a direct link to a specific post.

## Solution

Add a post viewing screen at the route `/user/:username/posts/:id`. The screen is public —
accessible to both authenticated users and guests without authentication. The screen displays
the title, media image (if present), full text with Markdown rendering, and publication date.

## User Stories

1. As a user (any, including a guest), I want to open a post at the URL
   `/user/username/posts/1` so that I can read the full text of the post.
2. As a user, I want to see the post title at the top of the screen body
   so that I immediately understand what the post is about.
3. As a user, I want to see an image below the title if the post has a
   media link so that I can see the visual content of the post.
4. As a user, I want to see the post text with rendered Markdown
   (bold text, lists, line breaks, etc.) so that I can read formatted content.
5. As a user, I want to see the publication date at the bottom of the content in the format
   `dd MMM yyyy, HH:mm` so that I know when the post was published.
6. As a user, I want to see a `CircularProgressIndicator` while the post is loading
   so that I understand that the app is working and the data is being loaded.
7. As a user, I want to see an error message and a "Retry" button if the post
   did not load (network unavailable, post does not exist, any other error)
   so that I understand what went wrong and can try again.
8. As a user, I want to see a standard AppBar with the title "Post" and a
   back button so that I can return to the previous screen.
9. As a user with a long post, I want to scroll the screen down so that I can read
   the entire post text.
10. As a user, I want that if the image fails to load (invalid link,
    unavailable server) a placeholder icon is shown and the rest of the post content
    is displayed normally.
11. As a user, I want to open a post without logging in so that I can read public
    content without registering.

## Implementation Decisions

### Architecture

A new `post_details` slice inside the `posts` feature. Follows the standard vertical-slice
structure of the project: domain → data → application → presentation.

### Modules

**Existing modules without changes:**
- `Post` entity in `_shared/domain/entities/` — used as-is.
- `PostDto` in `_shared/data/dto/` — used as-is.

**Modification of existing module:**
- `PostsApiClient` — one method is added: `GET /{username}/post/{id}`,
  returns `PostDto`. Retrofit annotations, codegen.

**New modules of the `post_details` slice:**

- **`PostDetailsPort`** — narrow port (one method), accepts `username` and `id`,
  returns `Either<Failure, Post>`.
- **`GetPostUseCase`** — orchestrates the port call, returns `Either<Failure, Post>`.
  No business logic — delegates directly to the port.
- **`GetPostAdapter`** — implements `PostDetailsPort`. Double catch per rule §8.4:
  inner `on DioException` with mapping HTTP errors to `Failure`,
  outer `catch (e, st)` with logging via `AppLogger` and returning `UnknownFailure`.
- **`PostDetailsState`** — sealed class via freezed:
  `initial`, `loading`, `loaded(Post)`, `error(Failure)`.
- **`PostDetailsCubit`** — method `load(username, id)`. Emits `loading` → `loaded`
  or `loading` → `error`. Initialised from route via cascade.
- **`PostDetailsRoute`** — `@RoutePage()` with path params `username` (String) and `id` (int).
  Provides `PostDetailsCubit` via `BlocProvider`, calls `load` on creation.
- **`PostDetailsScreen`** — `StatelessWidget`, `BlocBuilder`. Three states:
  loading/initial → spinner; error → text + Retry; loaded → content.

### UI decisions

- Content order: title → image → Markdown text → date.
- Image: `Image.network` with `BoxFit.cover`, `errorBuilder` with placeholder icon.
- Markdown: `MarkdownBody` from `flutter_markdown` (already in the project).
- Date: `DateFormat('dd MMM yyyy, HH:mm')` via `intl` (already in the project), local time.
- Scrolling: `SingleChildScrollView` around all content.
- Error state: one common state for all error types, without detailing in the UI.

### Route

- Path `/user/:username/posts/:id`, without `authGuard`.
- Added to `AppRouter`. Navigation to the route from other screens — out of scope.

### API contract

- `GET /api/v1/{username}/post/{id}`
- Response: `{ id, title, text, media_url, created_by_user_id, created_at }`
- Authentication not required.

### Dependencies

- No new packages are added. `intl` and `flutter_markdown` are already in `pubspec.yaml`.

## Testing Decisions

A good test verifies the external behaviour of a module through its public interface,
not implementation details (we do not check whether a specific method was called if it
is not part of the contract).

### Modules under test

- **`GetPostUseCase`** — unit test: success scenario → `Right(Post)`;
  error from port → propagated as `Left(failure)`.
- **`PostDetailsCubit`** — `bloc_test`: `load` on success emits
  `[loading, loaded(post)]`; on error emits `[loading, error(failure)]`.

### What not to test

- Widget test `PostDetailsScreen` — out of scope for MVP.
- `GetPostAdapter` — standard template, no test case added in this slice.

### Examples of analogous tests in the project

- Use-case tests: `test/features/users/`
- Cubit tests: `test/features/tiers/`
- Mocks via `mocktail` (not mockito).

## Out of Scope

- Navigation to `PostDetailsScreen` from `list_posts` or `user_posts` (added later).
- Editing a post — `edit_post` slice.
- Deleting a post — `delete_post` slice.
- Post author name (requires an additional request to `/users/{id}`).
- Pull-to-refresh — the post is static, update is via Retry on error.
- Relative date format (`timeago`) — using absolute format via `intl`.
- Validation of the content type of `media_url` — treating it as an image, fallback on error.
- Share button for the post.
- Widget test for `PostDetailsScreen`.

## Further Notes

- The `flutter_markdown` package was added to the project in slice `0015_create_post`.
  Here we use `MarkdownBody` — a component for reading (unlike `Markdown`,
  which requires a Scrollable wrapper).
- `PostDto.createdAt` is declared as `DateTime?` (nullable). The `toDomain()` mapper
  must handle `null`, for example substituting `DateTime.now()` or returning
  `Left(ValidationFailure)`. This decision is made during adapter implementation.
- Since `created_by_user_id` is an int (not a username), we do not show the author name:
  a separate request for the user profile is not in scope.
