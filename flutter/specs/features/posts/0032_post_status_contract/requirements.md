# 0032 · post_status_contract — Requirements

## Functional Requirements

| ID | Requirement |
|---|---|
| F1 | The `Post` domain entity exposes a `postUuid: String` field containing the stable UUID received from all post endpoints. |
| F2 | The `Post` domain entity exposes a `status: PostStatus` field reflecting the post's current lifecycle position. |
| F3 | `PostStatus` is an enum with exactly three values: `pendingReview`, `approved`, `changesRequested`. |
| F4 | `PostDto` deserialises a `post_uuid` JSON key (snake_case) into a `postUuid` Dart field and a `status` JSON key into a `status` String field. |
| F5 | `PostItemDto` deserialises `post_uuid` and `status` from the server response using the same mapping as `PostDto`. |
| F6 | `GetPostAdapter` populates `Post.postUuid` and `Post.status` when mapping a `PostDto` returned by the single-post endpoint. |
| F7 | `UserPostsAdapter` populates `Post.postUuid` and `Post.status` for every item when mapping a `PaginatedPostsDto` returned by the user-posts endpoint. |
| F8 | `ListPostsAdapter` populates `Post.postUuid` and `Post.status` for every item when mapping a `PaginatedPostsDto` returned by the global-posts endpoint. |
| F9 | When the backend returns an unrecognised `status` string, the adapter maps it to `PostStatus.pendingReview` and logs a warning via `AppLogger`. |

## Non-functional Requirements

| ID | Requirement |
|---|---|
| N1 | `PostStatus` is a pure Dart enum with no imports from `package:flutter/*`, `package:dio/*`, or any package outside pure Dart. |
| N2 | The `status` string-to-`PostStatus` conversion is performed inside each adapter; the DTO carries the raw `String` and the domain entity carries the typed `PostStatus`. |
| N3 | `Post.postUuid` and `Post.status` are required (non-nullable); the backend contract guarantees their presence on all post responses. |
| N4 | Each adapter that maps a DTO to `Post` retains the double-catch pattern: an inner `on DioException catch` for HTTP errors and an outer `on Object catch` that calls `logger.error` and returns `Left(Failure.unknown())`. |
| N5 | Unknown-status fallback is logged at warning level (not error), because the fallback is graceful and the app continues functioning. |
| N6 | All new types (`PostStatus`) and all modified shared types (`Post`, `PostDto`, `PostItemDto`) reside in `lib/features/posts/_shared/`; no new slice folder is created under `lib/features/posts/`. |
| N7 | No slice outside `posts/_shared/` or the three named adapters is modified by this slice. |
| N8 | No `PostsApiClient` endpoint signature is added or changed. |
| N9 | No localization keys are added; the `slang` pipeline is not involved. |
| N10 | After modifying `PostDto` or `PostItemDto`, `dart run build_runner build --delete-conflicting-outputs` is run to regenerate `*.freezed.dart` and `*.g.dart` files. |

## Out of scope

- Any UI rendering of `status` or `postUuid` (covered by slices 0033–0037).
- The moderation-log endpoint and its DTO (covered by slice `moderate_post`).
- The pending-posts endpoint and its DTO (covered by slice `pending_posts`).
- Navigation changes or new routes.
- Changes to the `User` entity or user DTOs (covered by slice `moderator_contract`).
