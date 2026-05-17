# PRD: pending_posts (0034)

## Problem Statement

Moderators and superusers need a dedicated place to review posts that are awaiting
moderation. Currently there is no such screen: the global posts feed shows only
`approved` posts, and there is no way for a moderator to find posts in
`pending_review` status. This blocks the entire moderation workflow.

## Solution

Add a fourth tab — "Pending" — to the app shell, visible only to users with the
`moderatePosts` permission (moderators and superusers). The tab contains an
infinite-scroll list of posts in `pending_review` status. Each tile shows the post
title, author, creation date, and the number of events in the moderation log, giving
the moderator enough context to prioritise the queue. Tapping a tile navigates to the
moderation screen (slice D).

## User Stories

1. As a moderator, I want to see a "Pending" tab in the navigation bar, so that I can
   quickly reach the moderation queue from anywhere in the app.
2. As a regular user or guest, I want the "Pending" tab to be invisible, so that I am
   not confused by UI I cannot use.
3. As a moderator, I want the pending-posts list to load automatically when I open the
   tab, so that I can start reviewing immediately.
4. As a moderator, I want to see a loading indicator while the first page is fetching,
   so that I know the app is working.
5. As a moderator, I want to see each post's title, author username, creation date, and
   moderation-log event count in the tile, so that I can prioritise which posts to
   review first.
6. As a moderator, I want to scroll to the bottom of the list to load more posts, so
   that I can page through a long queue without manual interaction.
7. As a moderator, I want to see a loading indicator at the bottom of the list while
   the next page is fetching, so that I know more results are coming.
8. As a moderator, I want to see an error message with a retry option if the list fails
   to load, so that I can recover from network errors.
9. As a moderator, I want to pull-to-refresh the list to re-fetch from page one, so
   that I can see newly submitted posts.
10. As a moderator, I want to see an empty-state message when there are no pending
    posts, so that I know the queue is clear and there is nothing to do.
11. As a moderator, I want tapping a tile to navigate to the moderation screen for that
    post, so that I can review and act on it.
12. As a moderator, I want a post to disappear from the list automatically after I
    approve or reject it from the moderation screen, so that I do not need to refresh
    the queue manually.
13. As a superuser who is also on the "Pending" tab, I want the tab to be visible
    alongside the "Tiers" tab, so that I can access both moderation and tier management
    without switching accounts.
14. As a moderator, I want the "Pending" tab to reset its stack to the list root when I
    tap the tab again (same behaviour as Users and Posts tabs), so that deep navigation
    does not persist unexpectedly.
15. As a moderator, I want the app to redirect me away from the "Pending" tab if I am
    logged out, so that I never see a protected screen unauthenticated.

## Implementation Decisions

### New domain entity: PendingPostItem

`GET /posts/pending` returns a richer shape than the standard post list: each item
includes `post_uuid`, `title`, `text`, `media_url`, `status`, `created_at`,
`updated_at`, `author_username`, and an inline `moderation_log` array (same schema as
`GET /posts/{post_uuid}/moderation-log`).

A dedicated `PendingPostItem` entity is introduced in `posts/_shared/domain/entities/`
so both this slice (list) and slice D (moderation screen, which receives the item as
route extras) can import it without violating slice-isolation rules. The entity carries:
`postUuid`, `title`, `text`, `mediaUrl`, `status` (`PostStatus` from slice A),
`createdAt`, `updatedAt`, `authorUsername`, and `moderationLog` (list of
`ModerationLogEntry` values — a new domain type also placed in `posts/_shared/`).

### New domain type: ModerationLogEntry

`ModerationLogEntry` carries: `id`, `eventType` (enum: `moderatorReview`,
`authorRevision`), `action` (nullable enum: `approved`, `changesRequested`), `message`
(nullable string), `createdAt`, `actorUserId`, `actorUsername`. Placed in
`posts/_shared/domain/entities/`.

### New DTOs

`ModerationLogEntryDto` and `PendingPostItemDto` are added to `posts/_shared/data/dto/`.
`PendingPostsDto` is a paginated wrapper (`items`, `totalCount`, `page`,
`itemsPerPage`) following the same shape as `PaginatedPostsDto`.

### New API endpoint

`PostsApiClient` gains:

```
GET /posts/pending?page=&items_per_page=
```

Returns `PendingPostsDto`. Guarded by `authGuard` +
`PermissionGuard({Permission.moderatePosts})` at the route level; the adapter also
handles 403 → `PermissionDenied`.

### Port and adapter

`IPendingPostsPort` exposes `getPendingPosts({required int page, required int perPage})`
returning `Either<Failure, PaginatedResult<PendingPostItem>>`. A single adapter
implements the port, maps DTOs to domain entities, and applies the standard double-catch
error mapping.

### PendingPostsCubit

Follows the same infinite-scroll pattern as `ListPostsCubit` and `UserPostsCubit`:
- States: `initial`, `loading`, `loaded(items, page, hasMore, loadMoreStatus,
  loadMoreError)`, `error(Failure)`.
- Methods: `load()`, `refresh()`, `loadMore()`.
- Subscribes to `PostEventBus` for `PostModeratedEvent`; on receipt, removes the
  matching `postUuid` from the loaded list so the queue updates without a network call.

### Navigation: 4th tab in AppShell

A new `PendingTabRoute` and `PendingPostsRoute` are added following the same pattern as
`TiersTabRoute` / `ListTiersRoute`.

`AppRouter` gains a fourth tab child under `AppShellRoute`:
```
path: 'pending'
guards: [authGuard, PermissionGuard({Permission.moderatePosts}, permissionCubit)]
children: [PendingPostsRoute (initial)]
```

The moderation-screen route (`/pending/:post_uuid/moderate`) lives as a child of this
tab so back-navigation stays within the Pending stack.

`AppShellScreen` changes:
- `AutoTabsRouter.routes` list grows from 3 to 4 entries (PendingTabRoute at index 3).
- `_AppNavBar` adds a "Pending" `_NavTab`, shown only when
  `permissions.contains(Permission.moderatePosts)`. The Tiers tab remains gated on
  `isSuperuser` as before.
- The logout redirect listener is extended to also redirect from index 3 (Pending) to
  index 0 (Users) on logout.

### Tile widget: PendingPostTile

A self-contained widget displaying: post title (primary), author username + formatted
creation date (secondary), moderation-log event count chip (trailing). Taps trigger
navigation to the moderation screen, passing the `PendingPostItem` as route extras.

### Adaptive breakpoint constant

`AppBreakpoints.medium = 600.0` (a `double` constant) is added to `core/` in this
slice. It will be reused by slices D and E.

### Localisation

All strings (tab label, empty state, error messages, tile labels) are added via `slang`
JSON. No hardcoded strings.

## Testing Decisions

Good tests assert on observable cubit state and widget output, not on DTO internals or
network call order.

**Modules to test:**

- **PendingPostsAdapter** — cover: 200 success with correct `PendingPostItem` mapping
  including `moderationLog` count; 403 → `PermissionDenied`; 404 → `NotFoundFailure`;
  unexpected exception → `Failure.unknown()` with log. Prior art: adapter tests in
  `test/features/posts/*/data/`.
- **PendingPostsCubit** — cover: `load()` → loading → loaded with correct items and
  `hasMore`; `loadMore()` → appends page; `loadMore()` when no more → no-op;
  `PostModeratedEvent` → removes item from loaded list; `load()` failure → error state;
  `loadMore()` failure → `loadMoreStatus.error`. Prior art: `ListPostsCubit` tests in
  `test/features/posts/list_posts/application/`.
- **PendingPostTile widget** — render: title, author, date, and event-count chip are
  visible; tap triggers navigation callback. Prior art: widget tests in
  `test/features/posts/*/presentation/`.
- **PendingPostsScreen widget** — render loaded state with items; render empty state;
  render error state with retry button. Prior art: existing list screen widget tests.

## Out of Scope

- The moderation screen itself (slice D, `moderate_post`).
- Displaying `pending_review` posts in the regular Posts feed or user_posts list (those
  screens are governed by backend filtering, no client change needed).
- Push notifications for new pending posts.
- Sorting or filtering the pending queue beyond what the backend provides.
- Any changes to the `Post` entity or existing post DTOs (slice A).
- Any changes to the `User` entity or permission enum (slice B) — this slice depends on
  `Permission.moderatePosts` already being defined.

## Further Notes

- **Dependency order:** this slice depends on slice A (`post_status_contract`, which
  defines `PostStatus`) and slice B (`moderator_contract`, which defines
  `Permission.moderatePosts`). Both must be merged first.
- **Tab index stability:** `AutoTabsRouter` routes are declared in fixed order. Pending
  is always at index 3 regardless of whether it is visible in the nav bar. This avoids
  dynamic route list issues with auto_route.
- The `ModerationLogEntry` and `PendingPostItem` entities introduced here are also used
  by slice D (`moderate_post`). Placing them in `posts/_shared/` is the approved
  cross-slice sharing mechanism per the project architecture.
- The `AppBreakpoints.medium` constant introduced here is also used by slices D and E;
  it is defined once here and imported by the later slices.
