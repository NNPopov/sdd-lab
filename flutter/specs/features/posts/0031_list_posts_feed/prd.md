# 0031 · posts / list_posts_feed — PRD

## Problem Statement

The Posts tab exists in the app shell but shows an empty screen. Users who navigate
to Posts see nothing — no content, no loading indicator, no way to create a post.
Anonymous visitors cannot browse the public feed at all, and authenticated users have
no shortcut to create a new post from the global view.

## Solution

Implement the full logic for the existing `list_posts` screen stub. The screen fetches
all posts from every user via the public `GET /api/v1/posts` endpoint, displays them
in an infinite-scroll list, and allows pull-to-refresh. Each post card shows the
author username. Authenticated users see a floating action button that navigates to
the create-post screen using their own username. Deleted posts are removed from the
visible list in real time via the shared event bus without requiring a manual refresh.

Two shared modules (`PaginatedPosts` domain entity and `PaginatedPostsDto`) are
relocated from the `user_posts` slice into `_shared` so that both slices can use them
without violating slice-isolation rules.

## User Stories

1. As an anonymous visitor, I want to see a paginated list of all posts when I open the
   Posts tab, so that I can browse public content without signing in.
2. As an anonymous visitor, I want the first page to load automatically when I open the
   Posts tab, so that I do not have to trigger loading manually.
3. As any user (anonymous or authenticated), I want to see each post's title, a short
   text preview, the publication date, and the author's username in the list, so that I
   can identify who wrote each post.
4. As any user, I want to scroll down and have additional pages load automatically, so
   that I can read more posts without tapping a "load more" button.
5. As any user, I want to see a loading spinner at the bottom while additional pages are
   fetching, so that I know the app is working.
6. As any user, I want to see a "Retry" button at the bottom if a load-more request
   fails, so that I can try again without refreshing the entire list.
7. As any user, I want to pull the list down to refresh, so that I can see newly
   published posts.
8. As any user, I want to see a full-screen loading indicator while the first page is
   loading, so that I know the app is fetching content.
9. As any user, I want to see a full-screen error message with a Retry button if the
   initial load fails, so that I can recover without restarting the app.
10. As any user, I want to see an empty-state message if no posts exist yet, so that I
    understand the feed is genuinely empty rather than broken.
11. As any user, I want to tap "Open" on a post card to navigate to that post's detail
    screen, so that I can read the full content.
12. As an authenticated user, I want to see a floating action button on the Posts tab,
    so that I can quickly navigate to the create-post screen without going through my
    profile first.
13. As an authenticated user, I want the FAB to use my own username when navigating to
    create-post, so that the new post is attributed to me correctly.
14. As any user viewing the feed, I want a post I just deleted (from a detail screen in
    another tab) to disappear from the list immediately, so that the feed stays
    consistent without a manual refresh.
15. As a developer, I want `PaginatedPosts` and `PaginatedPostsDto` to live in `_shared`
    rather than inside `user_posts`, so that both `list_posts` and `user_posts` can
    reference them without violating slice-isolation rules.

## Implementation Decisions

### Modules to build or modify

**New port — `ListPostsPort`**
Narrow interface in `list_posts/domain/ports/`. Takes `page` and `perPage`; returns
`Either<Failure, PaginatedPosts>`. No `username` parameter (this is a global feed).

**New use case — `ListPostsUseCase`**
Thin orchestrator in `list_posts/domain/usecases/`. Delegates directly to
`ListPostsPort`. Injectable.

**New adapter — `ListPostsAdapter`**
Implements `ListPostsPort`. Calls the new `getPosts` method on `PostsApiClient`.
Uses double-catch: inner `DioException` catch maps HTTP status codes to typed
`Failure` values; outer `Object` catch logs via `AppLogger.error` and returns
`Failure.unknown()`.

**Modified shared API client — `PostsApiClient`** (in `_shared/data/`)
Add one new method: `getPosts(page, perPage)` via `GET /posts`. Return type is
`PaginatedPostsDto`. Fix the existing import violation: `PaginatedPostsDto` is moved
here from `user_posts`, so the client no longer imports across slice boundaries.

**Relocated — `PaginatedPostsDto`**
Move from `user_posts/data/dto/` to `_shared/data/dto/`. Update all import sites
(`PostsApiClient`, `UserPostsAdapter`, `user_posts_adapter_test`).

**Relocated — `PaginatedPosts`**
Move from `user_posts/domain/entities/` to `_shared/domain/entities/`. Update all
import sites (`UserPostsUseCase`, `UserPostsPort`, `UserPostsAdapter`,
`UserPostsCubit`, related tests).

**New state — `ListPostsState`**
Sealed freezed class in `list_posts/application/`. Mirrors `UserPostsState` exactly:
`initial | loading | loaded(posts, page, hasMore, loadMoreStatus, loadMoreError) |
error`. Includes `LoadMoreStatus` enum if not already in `_shared`.

**New cubit — `ListPostsCubit`**
In `list_posts/application/`. Exposes `load()`, `refresh()`, `loadMore()`. In
constructor, subscribes to `PostEventBus`; on `PostDeleted` event, removes the
matching post from `ListPostsLoaded.posts`. Cancels subscription in `close()`. No
`username` parameter on any method.

**New widget — `ListPostTile`**
In `list_posts/presentation/widgets/`. Card showing title, stripped-text preview,
publication date, author username, and an "Open" `TextButton.icon`. Does not share
code with `PostTile` in `user_posts` (separate widget, no cross-slice import).

**Modified screen — `ListPostsScreen`**
Replace the current stub with a `StatefulWidget`. `initState` calls `cubit.load()`.
`ScrollController` triggers `loadMore()` within 200 px of the bottom. `BlocBuilder`
switches on all four state branches. `RefreshIndicator` wraps the list.
`BlocBuilder<AuthCubit, AuthState>` drives FAB visibility.

**Modified route — `ListPostsRoute`**
Add `BlocProvider(create: (_) => getIt<ListPostsCubit>())` wrapping the screen, same
pattern as `UserPostsRoute`.

### API contract

```
GET /api/v1/posts?page={n}&items_per_page={k}
```
No authentication header required. Response shape is identical to
`GET /{username}/posts`:
```json
{
  "items": [
    { "id": 0, "title": "string", "text": "string",
      "media_url": "string", "created_at": "ISO-8601",
      "created_by_user_id": 0, "username": "string" }
  ],
  "total_count": 0, "page": 0, "items_per_page": 0
}
```
`hasMore` is derived as `page * itemsPerPage < totalCount`.

### Navigation

"Open" button on `ListPostTile` navigates to `PostDetailsRoute(username:
post.username!, id: post.id)` within the Posts tab context.

FAB navigates to `CreatePostRoute(username: currentUser.username)` within the Posts
tab context.

### Localization

New keys added to `posts.listPosts.*`:
- `empty` — empty-state message
- `loadError` — full-screen error message
- `fabTooltip` — FAB tooltip for screen readers
- `openPost` — label on the "Open" button in `ListPostTile`

`common.retry` is reused for both the full-screen and load-more retry buttons.

### Dependency injection

`ListPostsCubit` and `ListPostsAdapter` are registered via `@injectable` /
`@LazySingleton`. No new DI module is needed — `injectable` discovers them through
the existing `@InjectableInit` scan.

## Testing Decisions

**What makes a good test here:**
Test observable state transitions and adapter outputs only. Never assert on internal
implementation details (private fields, method call order). Mock only at true system
boundaries: the Dio HTTP layer and the shared `AppLogger`.

**Use-case unit test** (`list_posts/domain/usecases/`)
Verify `ListPostsUseCase` delegates to `ListPostsPort` and returns its result
unchanged, for both `Right` and `Left` paths. Prior art: `user_posts_usecase_test`.

**Adapter unit test** (`list_posts/data/`)
Cover: success (items mapped, `hasMore` computed), `DioException` 404 → `Failure.notFound()`,
`DioException` 5xx → `Failure.server(statusCode: ...)`, network error →
`Failure.network(...)`, unexpected exception → `Failure.unknown()` + `AppLogger.error`
called. Prior art: `user_posts_adapter_test`.

**Cubit unit test** (`list_posts/application/`)
Cover: `load` success → `[loading, loaded]`; `load` failure → `[loading, error]`;
`loadMore` appends items and advances page; `loadMore` failure sets `loadMoreStatus.error`;
`refresh` resets to page 1; `PostDeleted` event removes matching post from `loaded`
state; `PostDeleted` ignored when state is not `loaded`. Prior art:
`user_posts_cubit_test`.

**Widget test** (`list_posts/presentation/`)
Mock `ListPostsCubit`. Cover: loading spinner shown; empty state shown; list of tiles
rendered with username visible; load-more spinner shown; load-more retry button shown;
full-screen error + retry triggers `load`; pull-to-refresh triggers `refresh`; FAB
visible when authenticated, hidden when anonymous; FAB tap navigates to create-post
route. Prior art: `user_posts_screen_test`.

**Outside-in test** (generated by `/slice-test-red`)
Wires real `ListPostsAdapter` → `ListPostsUseCase` → `ListPostsCubit` with Dio mocked
at the network boundary. Two scenarios: first-page load (`hasMore = true`) and
last-page load (`hasMore = false`). Prior art:
`adapt_paginated_posts_contract_outside_in_test`.

## Out of Scope

- Filtering or sorting the global feed.
- Search within the feed.
- Pagination via explicit page controls (infinite scroll only).
- Showing media attachments in the tile (text preview only).
- Editing or deleting posts from the feed directly (navigate to detail screen first).
- Any change to `user_posts` behaviour — only shared infrastructure is touched.
- Authentication changes or anonymous-user registration.

## Further Notes

Moving `PaginatedPosts` and `PaginatedPostsDto` to `_shared` is a prerequisite for
all other work in this slice. It must be done first and the `user_posts` import sites
updated before any `list_posts` code is written. This avoids a mid-slice breakage
window.

The `PostsApiClient` currently imports `PaginatedPostsDto` from `user_posts`, which
is an existing architectural violation (`_shared` importing from a slice). Moving the
DTO to `_shared` corrects this for both the existing `getUserPosts` method and the new
`getPosts` method.

`ListPostTile` intentionally duplicates some display logic from `PostTile` rather than
sharing a cross-slice widget, in line with the project's slice-isolation rule.
If the two tiles diverge further over time (e.g., different action buttons per
audience), the separation will prove correct. If they converge, a later refactor can
move a common tile to `_shared/presentation/widgets/`.
