# PRD: post_status_contract (0032)

## Problem Statement

Posts now go through a moderation lifecycle on the backend. Every post carries two new
fields — `post_uuid` (a stable UUID identifier used by moderation endpoints) and `status`
(the current position in the lifecycle: `pending_review`, `approved`, or
`changes_requested`). The Flutter client's shared post data model does not know about
either field, so every downstream slice that needs to display post status or call
UUID-based endpoints is blocked.

## Solution

Extend the shared post contract — the `Post` domain entity, `PostDto`, and `PostItemDto`
— to carry `postUuid` and `status`. Introduce a `PostStatus` domain enum so the rest of
the app can branch on lifecycle state in a type-safe way. Update every adapter that maps
a DTO to a `Post` entity to populate the two new fields. No UI changes are part of this
slice.

## User Stories

1. As a developer working on the pending-posts tab, I want `Post` to carry a `postUuid`
   field, so that I can pass it to UUID-based moderation endpoints without making an
   extra network call.
2. As a developer working on the post-details screen, I want `Post` to carry a
   `PostStatus` value, so that I can show the author a status badge without additional
   fields or extra calls.
3. As a developer working on the edit/revise screen, I want `Post.status` to be a typed
   enum, so that the use-case can switch on it to choose between the regular edit
   endpoint and the revise endpoint.
4. As a developer working on the moderation screen, I want `Post.postUuid` available
   after navigating from the pending queue, so that I can build the `/moderate` and
   `/moderation-log` request paths without extra lookups.
5. As a developer, I want the DTO layer to map an unknown `status` string to a safe
   fallback value, so that a future backend status addition does not crash the app.
6. As a developer, I want `PostDto` (single-post endpoints) to carry both `post_uuid`
   and `status`, so that all endpoints — list and detail — expose a consistent shape.
7. As a developer, I want `PostItemDto` (paginated list endpoints) to carry both
   `post_uuid` and `status`, so that list screens can render status without a second
   fetch.
8. As a developer writing adapter unit tests, I want clear mapping coverage for all
   three `PostStatus` variants, so that a misnamed JSON key is caught immediately.

## Implementation Decisions

### New domain type: PostStatus enum

A `PostStatus` enum is added to the domain layer with three values:
`pendingReview`, `approved`, `changesRequested`.

The enum lives in the posts `_shared` domain layer. It has zero imports from Flutter or
Dio — it is pure Dart.

### Post entity changes

Two fields are added to `Post`:
- `postUuid: String` — required, stable UUID received from all post endpoints.
- `status: PostStatus` — required, typed lifecycle position.

Both fields are required (not nullable). The backend guarantees they are always present
in every post response after this contract update.

### DTO changes — PostDto

`PostDto` gains two new fields:
- `post_uuid: String` — required, mapped to `postUuid` via `@JsonKey`.
- `status: String` — required at the DTO level; the adapter converts it to `PostStatus`.

### DTO changes — PostItemDto

Same two fields added as in `PostDto`. `PostItemDto` is used by both
`GET /posts` and `GET /users/{username}/posts`.

### Adapter mapping

All adapters that currently map `PostDto` → `Post` or `PostItemDto` → `Post` are updated
to populate `postUuid` and `status`. The `status` string-to-enum conversion is done
inside each adapter (not in the DTO) so the domain entity stays free of JSON knowledge.

Unknown `status` strings fall back to `PostStatus.pendingReview` and are logged as
warnings via `AppLogger`.

### No API client changes

The Retrofit `PostsApiClient` return types (`PostDto`, `PaginatedPostsDto`) already
cover all affected endpoints. No new endpoints are added in this slice.

### No UI changes

This slice is purely a data-layer contract update. No widget, screen, cubit, or
navigation change is included.

## Testing Decisions

Good tests for this slice verify only the observable adapter output — what `Post` comes
out for a given raw JSON map — without asserting on internal DTO structure or field
names.

Modules to test:
- **PostStatus mapping in adapters** — for each adapter that maps a DTO to `Post`,
  cover: all three valid `status` string values, an unknown `status` string (fallback +
  log warning), a `post_uuid` value round-trips correctly.
- Prior art: existing adapter unit tests in `test/features/posts/*/data/` follow the
  pattern of constructing a raw `Map<String, dynamic>`, calling the adapter method, and
  asserting on the returned domain entity.

The `PostStatus` enum itself requires no separate tests — coverage comes from the adapter
tests.

## Out of Scope

- Any UI rendering of `status` or `postUuid` (covered by slices 0033–0037).
- The moderation-log endpoint and its DTO (introduced in slice D, `moderate_post`).
- The pending-posts endpoint and its DTO (introduced in slice C, `pending_posts`).
- Navigation changes or new routes.
- Changes to the `User` entity or user DTOs (covered by slice B, `moderator_contract`).

## Further Notes

- Slices C (`pending_posts`), D (`moderate_post`), E (`revise_post`), and F
  (`post_status_display`) all depend on this slice being merged first.
- The `postUuid` field is the key that unlocks UUID-based endpoints
  (`/posts/{post_uuid}/moderate`, `/posts/{post_uuid}/moderation-log`,
  `/posts/{post_uuid}/revise`). Navigation extras will carry the full `Post` object so
  downstream screens do not need to re-fetch.
- Backend guarantees `post_uuid` and `status` are present on all post responses
  (create, get single, list, user list) after this contract update.
