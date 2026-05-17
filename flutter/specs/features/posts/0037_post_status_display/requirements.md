# 0037 · post_status_display — Requirements

## Functional Requirements

| ID | Requirement |
|---|---|
| F1 | When the screen is in `PostDetailsLoaded` state and the authenticated user is the post's author, a status chip is rendered below the post title and above the media image (or above the markdown body if there is no media). |
| F2 | When the post status is `pendingReview`, the chip label reads "Pending Review". |
| F3 | When the post status is `approved`, the chip label reads "Approved". |
| F4 | When the post status is `changesRequested`, the chip label reads "Changes Requested". |
| F5 | When the authenticated user's username does not match `post.username`, the status chip is not rendered. |
| F6 | When `post.username` is null, the status chip is not rendered regardless of the authenticated user. |
| F7 | When the user is unauthenticated (`AuthUnauthenticated`), the status chip is not rendered. |
| F8 | When the screen is in `PostDetailsLoading` state, the status chip is not rendered. |
| F9 | When the screen is in `PostDetailsError` state, the status chip is not rendered. |
| F10 | The status chip uses theme-based container colours: `tertiaryContainer` for `pendingReview`, `primaryContainer` for `approved`, and `errorContainer` for `changesRequested`. |
| F11 | The status chip is visible immediately when the `PostDetailsLoaded` state is emitted; no additional loading indicator is shown for the chip. |
| F12 | After the author navigates away to the edit screen and returns, `PostDetailsCubit.load()` is called, and the chip reflects the updated post status without manual refresh. |
| F13 | The edit button (`Icons.edit_outlined`) remains visible to the author for all post statuses (`pendingReview`, `approved`, `changesRequested`). |
| F14 | No additional API call is made to determine the post status; the value is read from `PostDetailsLoaded.post.status`. |

## Non-functional Requirements

| ID | Requirement |
|---|---|
| N1 | All status chip label strings are supplied via `slang` translation keys (`posts.postStatus.pendingReview`, `posts.postStatus.approved`, `posts.postStatus.changesRequested`); no hardcoded UI strings are permitted. |
| N2 | The `PostStatusChip` widget is a stateless widget placed in `lib/features/posts/post_details/presentation/widgets/post_status_chip.dart`. |
| N3 | No new port, adapter, use-case, or cubit is created for this slice. |
| N4 | `PostDetailsCubit` and `PostDetailsState` are not modified by this slice. |
| N5 | `PostDetailsScreen` does not import any other slice of the `posts` feature (only `_shared/` and its own `post_details/` files). |
| N6 | `PostStatusChip` does not import `package:flutter_bloc`; it receives `PostStatus` as a constructor parameter and is purely presentational. |
| N7 | Chip colours are read from the active `Theme.of(context).colorScheme`; no colour values are hardcoded. |
| N8 | The `isAuthor` guard in the body uses `post.username` (nullable entity field), not `widget.username` (route param), and treats a null `post.username` as non-author. |
| N9 | `setState` is not used inside `PostDetailsScreen`; all state access goes through `BlocBuilder`. |
| N10 | Widget tests cover all observable author/non-author/unauthenticated and state scenarios using mocked `PostDetailsCubit` and `AuthCubit`; `pumpAndSettle` is not used (use `pump()` to avoid `CircularProgressIndicator` timeout). |
| N11 | No adapter, use-case, or cubit tests are added for this slice because the observable contracts of those layers are unchanged. |

## Out of scope

- Showing post status in `user_posts` list tiles.
- Showing moderator messages or moderation log in `post_details`.
- Status visibility for moderators or superusers on other authors' posts.
- Any change to how `post_details` works for non-authors.
- Push notifications or badges when post status changes.
- Real-time status updates while the author is on the screen.
