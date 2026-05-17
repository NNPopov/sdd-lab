# 0034 · posts / pending_posts — Implementation Plan

## Task

Create the `pending_posts` slice in the `posts` feature. Result: a fourth tab —
"Pending" — appears in `AppShell` for any user with the `moderatePosts` permission
(moderators and superusers). The tab shows an infinite-scroll list of posts in
`pending_review` status, each tile displaying title, author, creation date, and the
number of moderation-log events. Tapping a tile navigates to the moderation screen
(slice D). After a post is moderated (slice D publishes `PostModeratedEvent`), it
disappears from the list without a manual refresh.

**CRITICAL PREREQUISITE:** Slice 0033 (moderator_contract) must be merged before
implementing this slice. It adds `Permission.moderatePosts` to
`lib/core/rbac/permission.dart`. Slice 0032 (post_status_contract) is already
merged — `PostStatus` enum exists at
`lib/features/posts/_shared/domain/entities/post_status.dart`.

---

## CONTEXT

READ:
- `CLAUDE.md` — in full
- `specs/features/posts/0034_pending_posts/prd.md` — authoritative product spec
- `lib/features/posts/list_posts/**` — closest analogue (infinite scroll, event-bus,
  same state shape). DO NOT copy — refer to as a pattern
- `lib/features/posts/user_posts/**` — secondary analogue for `LoadMoreStatus`
  duplication precedent
- `lib/features/posts/_shared/data/posts_api_client.dart` — adding new endpoint
- `lib/features/posts/_shared/data/dto/post_item_dto.dart` — DTO conventions
- `lib/features/posts/_shared/data/dto/paginated_posts_dto.dart` — pagination DTO shape
- `lib/features/posts/_shared/domain/entities/post.dart` — entity conventions
- `lib/features/posts/_shared/domain/entities/paginated_posts.dart` — pagination entity shape
- `lib/features/posts/_shared/domain/entities/post_status.dart` — `PostStatus` enum
- `lib/features/posts/_shared/application/post_event.dart` — adding `PostModeratedEvent`
- `lib/features/posts/_shared/application/post_event_bus.dart` — event-bus pattern
- `lib/core/routing/app_router.dart` — adding 4th tab child
- `lib/core/routing/app_shell_screen.dart` — adding nav tab + extending logout redirect
- `lib/core/routing/tabs/tiers_tab_route.dart` — tab shell page pattern
- `lib/core/rbac/permission.dart` — `Permission.moderatePosts` (from 0033)
- `lib/core/rbac/permission_cubit.dart` — reading Set<Permission> in _AppNavBar
- `lib/core/errors/failure.dart`
- `lib/core/logging/domain/app_logger.dart`
- `lib/core/i18n/i18n/en.json`, `ru.json`
- `agent_docs/architecture.md`
- `agent_docs/error_handling.md`
- `agent_docs/testing.md`

DO NOT READ:
- `lib/features/posts/create_post/**`
- `lib/features/posts/edit_post/**`
- `lib/features/posts/post_details/**`
- `lib/features/users/**`
- `lib/features/tiers/**`
- `*.gr.dart`, `*.config.dart`, `*.g.dart`, `*.freezed.dart`

---

## API

```
GET http://127.0.0.1:8000/api/v1/posts/pending?page={n}&items_per_page={k}
Authorization: Bearer <token>  (required)

Response 200:
{
  "items": [
    {
      "post_uuid": "abc-123",
      "title": "My post",
      "text": "Post body...",
      "media_url": null,
      "status": "pending_review",
      "created_at": "2026-05-16T10:00:00Z",
      "updated_at": "2026-05-16T10:00:00Z",
      "author_username": "john",
      "moderation_log": [
        {
          "id": 1,
          "event_type": "moderator_review",
          "action": "changes_requested",
          "message": "Please revise the text.",
          "created_at": "2026-05-16T11:00:00Z",
          "actor_user_id": 42,
          "actor_username": "mod1"
        }
      ]
    }
  ],
  "total_count": 25,
  "page": 1,
  "items_per_page": 10
}
```

`hasMore` is computed client-side: `page * itemsPerPage < totalCount`.

Errors:
- 401 → `Failure.unauthorized(message: ...)`
- 403 → `Failure.permissionDenied()`
- 5xx → `Failure.server(statusCode: ...)`
- network error → `Failure.network(message: ...)`
- unexpected exception → `Failure.unknown()` + `logger.error`

Route guards: `authGuard` + `PermissionGuard({Permission.moderatePosts})` at the
`AppRouter` level. The adapter still handles 401/403 defensively.

---

## STRUCTURE

```
New shared files (posts/_shared/):
  lib/features/posts/_shared/
  ├── domain/entities/
  │   ├── moderation_event_type.dart    # enum: moderatorReview, authorRevision
  │   ├── moderation_action.dart        # enum: approved, changesRequested
  │   ├── moderation_log_entry.dart     # plain class
  │   ├── pending_post_item.dart        # plain class
  │   └── paginated_result.dart         # generic PaginatedResult<T>
  ├── data/dto/
  │   ├── moderation_log_entry_dto.dart # @freezed sealed class
  │   ├── pending_post_item_dto.dart    # @freezed sealed class
  │   └── pending_posts_dto.dart        # @freezed sealed class (paginated wrapper)
  └── application/
      └── post_event.dart               # MODIFIED: add PostModeratedEvent

Modified shared files:
  lib/features/posts/_shared/data/posts_api_client.dart  # add getPendingPosts

New slice files:
  lib/features/posts/pending_posts/
  ├── domain/
  │   ├── ports/
  │   │   └── pending_posts_port.dart
  │   └── usecases/
  │       └── get_pending_posts_usecase.dart
  ├── data/
  │   └── pending_posts_adapter.dart
  ├── application/
  │   ├── pending_posts_state.dart      # @freezed sealed; defines LoadMoreStatus locally
  │   └── pending_posts_cubit.dart
  └── presentation/
      ├── pending_posts_route.dart      # BlocProvider(PendingPostsCubit)
      ├── pending_posts_screen.dart
      └── widgets/
          └── pending_post_tile.dart

New core files:
  lib/core/theme/app_breakpoints.dart  # AppBreakpoints.medium = 600.0
  lib/core/routing/tabs/pending_tab_route.dart

Modified core files:
  lib/core/routing/app_router.dart      # add PendingTabRoute at index 3
  lib/core/routing/app_shell_screen.dart # add nav tab + extend logout redirect

Modified i18n:
  lib/core/i18n/i18n/en.json
  lib/core/i18n/i18n/ru.json
```

---

## WHAT TO DO

### 1) _SHARED DOMAIN: NEW ENUMS AND ENTITIES

**1a. `moderation_event_type.dart`**
```dart
enum ModerationEventType { moderatorReview, authorRevision }
```

**1b. `moderation_action.dart`**
```dart
enum ModerationAction { approved, changesRequested }
```

**1c. `moderation_log_entry.dart`** — plain class, no `@freezed` (matches `Post` and
`PaginatedPosts` conventions):
```dart
class ModerationLogEntry {
  const ModerationLogEntry({
    required this.id,
    required this.eventType,
    required this.createdAt,
    required this.actorUserId,
    required this.actorUsername,
    this.action,
    this.message,
  });
  final int id;
  final ModerationEventType eventType;
  final ModerationAction? action;
  final String? message;
  final DateTime createdAt;
  final int actorUserId;
  final String actorUsername;
}
```

**1d. `pending_post_item.dart`** — plain class:
```dart
class PendingPostItem {
  const PendingPostItem({
    required this.postUuid,
    required this.title,
    required this.text,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.authorUsername,
    required this.moderationLog,
    this.mediaUrl,
  });
  final String postUuid;
  final String title;
  final String text;
  final PostStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String authorUsername;
  final List<ModerationLogEntry> moderationLog;
  final String? mediaUrl;
}
```

**1e. `paginated_result.dart`** — generic class, mirrors `PaginatedPosts`:
```dart
class PaginatedResult<T> {
  const PaginatedResult({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.itemsPerPage,
  });
  final List<T> items;
  final int totalCount;
  final int page;
  final int itemsPerPage;
  bool get hasMore => page * itemsPerPage < totalCount;
}
```

---

### 2) _SHARED DATA: NEW DTOS

**2a. `moderation_log_entry_dto.dart`** — `@freezed sealed class`:
```dart
@freezed
sealed class ModerationLogEntryDto with _$ModerationLogEntryDto {
  const factory ModerationLogEntryDto({
    required int id,
    @JsonKey(name: 'event_type') required String eventType,
    String? action,
    String? message,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'actor_user_id') required int actorUserId,
    @JsonKey(name: 'actor_username') required String actorUsername,
  }) = _ModerationLogEntryDto;
  factory ModerationLogEntryDto.fromJson(Map<String, dynamic> json) =>
      _$ModerationLogEntryDtoFromJson(json);
}
```

**2b. `pending_post_item_dto.dart`** — `@freezed sealed class`:
```dart
@freezed
sealed class PendingPostItemDto with _$PendingPostItemDto {
  const factory PendingPostItemDto({
    @JsonKey(name: 'post_uuid') required String postUuid,
    required String title,
    required String text,
    required String status,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
    @JsonKey(name: 'author_username') required String authorUsername,
    @Default([]) @JsonKey(name: 'moderation_log')
        List<ModerationLogEntryDto> moderationLog,
    @JsonKey(name: 'media_url') String? mediaUrl,
  }) = _PendingPostItemDto;
  factory PendingPostItemDto.fromJson(Map<String, dynamic> json) =>
      _$PendingPostItemDtoFromJson(json);
}
```

**2c. `pending_posts_dto.dart`** — paginated wrapper:
```dart
@freezed
sealed class PendingPostsDto with _$PendingPostsDto {
  const factory PendingPostsDto({
    required List<PendingPostItemDto> items,
    @JsonKey(name: 'total_count') required int totalCount,
    required int page,
    @JsonKey(name: 'items_per_page') required int itemsPerPage,
  }) = _PendingPostsDto;
  factory PendingPostsDto.fromJson(Map<String, dynamic> json) =>
      _$PendingPostsDtoFromJson(json);
}
```

After writing these DTOs: `dart run build_runner build --delete-conflicting-outputs`

---

### 3) _SHARED: POST EVENT — ADD PostModeratedEvent

File: `lib/features/posts/_shared/application/post_event.dart`

Add:
```dart
final class PostModeratedEvent extends PostEvent {
  PostModeratedEvent(this.postUuid);
  final String postUuid;
}
```

This event is published by slice D (`moderate_post`) after a moderation action
succeeds. `PendingPostsCubit` consumes it to remove the item without a network round-trip.

---

### 4) _SHARED: POSTS API CLIENT — ADD ENDPOINT

File: `lib/features/posts/_shared/data/posts_api_client.dart`

Add method:
```dart
@GET('/posts/pending')
Future<PendingPostsDto> getPendingPosts({
  @Query('page') required int page,
  @Query('items_per_page') required int perPage,
});
```

Import `PendingPostsDto` from `_shared/data/dto/pending_posts_dto.dart`.

After change: `dart run build_runner build --delete-conflicting-outputs`

---

### 5) DOMAIN: PORT

File: `lib/features/posts/pending_posts/domain/ports/pending_posts_port.dart`

```dart
import 'package:dartz/dartz.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/paginated_result.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/pending_post_item.dart';

abstract class PendingPostsPort {
  Future<Either<Failure, PaginatedResult<PendingPostItem>>> call({
    required int page,
    required int perPage,
  });
}
```

---

### 6) DOMAIN: USE CASE

File: `lib/features/posts/pending_posts/domain/usecases/get_pending_posts_usecase.dart`

`@injectable`. Constructor: `PendingPostsPort _port`. Delegates directly to port.
Mirror of `ListPostsUseCase` — use it as the exact pattern.

---

### 7) DATA: ADAPTER

File: `lib/features/posts/pending_posts/data/pending_posts_adapter.dart`

`@LazySingleton(as: PendingPostsPort)`. Constructor: `PostsApiClient _api, AppLogger _logger`.

Double-catch (mandatory per CLAUDE.md):
```
outer: on Object catch (e, st) → _logger.error(...) → Left(Failure.unknown())
inner: on DioException catch (e) → Left(_mapHttp(e))
```

`_mapHttp`:
- `401` → `Failure.unauthorized(message: e.message ?? '')`
- `403` → `const Failure.permissionDenied()`
- `404` → `const Failure.notFound()`
- `statusCode != null && statusCode >= 500` → `Failure.server(statusCode: statusCode)`
- otherwise → `Failure.network(message: e.message)`

Success mapping: iterate `dto.items`, map each `PendingPostItemDto` → `PendingPostItem`:
- `postUuid`, `title`, `text`, `mediaUrl`, `authorUsername` — direct
- `status` → `_parseStatus(dto.status)` using same switch as `ListPostsAdapter`
- `createdAt`, `updatedAt` — direct
- `moderationLog` → map each `ModerationLogEntryDto` → `ModerationLogEntry`:
  - `id`, `message`, `createdAt`, `actorUserId`, `actorUsername` — direct
  - `eventType` → `_parseEventType(dto.eventType)`:
    - `'moderator_review'` → `ModerationEventType.moderatorReview`
    - `'author_revision'` → `ModerationEventType.authorRevision`
    - unknown → log warning, fallback to `moderatorReview`
  - `action` → `_parseAction(dto.action)` (nullable):
    - `'approved'` → `ModerationAction.approved`
    - `'changes_requested'` → `ModerationAction.changesRequested`
    - `null` → `null`
    - unknown → log warning, return `null`

Return `Right(PaginatedResult<PendingPostItem>(items: ..., totalCount: ..., page: ..., itemsPerPage: ...))`.

---

### 8) APPLICATION: STATE

File: `lib/features/posts/pending_posts/application/pending_posts_state.dart`

Define `LoadMoreStatus` locally (same enum as in `list_posts_state.dart` and
`user_posts_state.dart` — each slice owns its own copy; cross-slice import is forbidden):

```dart
enum LoadMoreStatus { idle, loading, error }

@freezed
sealed class PendingPostsState with _$PendingPostsState {
  const factory PendingPostsState.initial() = PendingPostsInitial;
  const factory PendingPostsState.loading() = PendingPostsLoading;
  const factory PendingPostsState.loaded({
    required List<PendingPostItem> items,
    required int page,
    required bool hasMore,
    @Default(LoadMoreStatus.idle) LoadMoreStatus loadMoreStatus,
    Failure? loadMoreError,
  }) = PendingPostsLoaded;
  const factory PendingPostsState.error(Failure failure) = PendingPostsError;
}
```

After creating: `dart run build_runner build --delete-conflicting-outputs`

---

### 9) APPLICATION: CUBIT

File: `lib/features/posts/pending_posts/application/pending_posts_cubit.dart`

`@injectable`. Constructor: `GetPendingPostsUseCase _useCase, PostEventBus _eventBus`.

```dart
const int _pageSize = 10;
```

Subscribe in constructor: `_sub = _eventBus.stream.listen(_onPostEvent);`

**Event handler:**
```dart
void _onPostEvent(PostEvent event) {
  if (event is PostModeratedEvent) {
    final current = state;
    if (current is PendingPostsLoaded) {
      emit(current.copyWith(
        items: current.items
            .where((p) => p.postUuid != event.postUuid)
            .toList(),
      ));
    }
  }
}
```

**Methods:**
- `load()` — emit loading → useCase(page:1, perPage:_pageSize) → fold → emit loaded/error
- `refresh()` — identical to `load()` (resets to page 1)
- `loadMore()`:
  1. Guard: `state is! PendingPostsLoaded` → return
  2. Guard: `!current.hasMore` → return
  3. Guard: `current.loadMoreStatus == LoadMoreStatus.loading` → return
  4. `emit(current.copyWith(loadMoreStatus: LoadMoreStatus.loading, loadMoreError: null))`
  5. `useCase(page: current.page + 1, perPage: _pageSize)`
  6. fold:
     - Left → `emit(current.copyWith(loadMoreStatus: LoadMoreStatus.error, loadMoreError: failure))`
     - Right → `emit(PendingPostsState.loaded(items: [...current.items, ...result.items], page: result.page, hasMore: result.hasMore))`

**close():** `unawaited(_sub.cancel()); return super.close();`

---

### 10) PRESENTATION: PENDING POST TILE

File: `lib/features/posts/pending_posts/presentation/widgets/pending_post_tile.dart`

`StatelessWidget`. Fields: `final PendingPostItem item`, `final VoidCallback onTap`.

Content (inside a `Card` or `ListTile`):
- **Title** (primary): `item.title` — `titleMedium`, bold
- **Author + date** (secondary): `item.authorUsername` and
  `DateFormat('d MMM yyyy').format(item.createdAt)` — `bodySmall`
- **Event count chip** (trailing): `Chip(label: Text('${item.moderationLog.length}'))` 
  with a tooltip or icon for context (e.g., `Icons.history`)
- `onTap` wired to `GestureDetector` or `InkWell` wrapping the card

---

### 11) PRESENTATION: SCREEN

File: `lib/features/posts/pending_posts/presentation/pending_posts_screen.dart`

`StatefulWidget` — needs `ScrollController`.

**initState:**
```dart
_scrollController.addListener(_onScroll);
unawaited(context.read<PendingPostsCubit>().load());
```

**dispose:** `_scrollController.dispose()`

**_onScroll:**
```dart
if (_scrollController.position.pixels >=
    _scrollController.position.maxScrollExtent - 200) {
  unawaited(context.read<PendingPostsCubit>().loadMore());
}
```

**build — switch on state:**
- `PendingPostsInitial()` → `SizedBox.shrink()`
- `PendingPostsLoading()` → `Center(child: CircularProgressIndicator())`
- `PendingPostsLoaded(:final items, :final loadMoreStatus)`:
  - `items.isEmpty` → `Center(child: Text(context.t.posts.pendingPosts.empty))`
  - otherwise → `RefreshIndicator(onRefresh: () => cubit.refresh(), child: ListView.builder(controller: _scrollController, itemCount: items.length + _trailingCount(loadMoreStatus), itemBuilder: ...))`
  - item tiles: `PendingPostTile(item: items[index], onTap: () => context.router.push(/* ModeratePostRoute — slice D — to be added later; use placeholder or TODO comment */))` 
    — IMPORTANT: do not reference slice D's route until it exists. For now, `onTap: () {}` (no-op) is acceptable; the outside-in test does not test navigation to slice D.
  - trailer: `LoadMoreStatus.loading` → spinner; `LoadMoreStatus.error` → retry TextButton; `idle` → `SizedBox.shrink()`
- `PendingPostsError()` → error message + Retry `FilledButton` calling `cubit.load()`

**AppBar:** `title: Text(context.t.posts.pendingPosts.title)`
No FAB — moderation actions are tile-level, not screen-level.

---

### 12) PRESENTATION: ROUTE

File: `lib/features/posts/pending_posts/presentation/pending_posts_route.dart`

```dart
@RoutePage()
class PendingPostsPage extends StatelessWidget {
  const PendingPostsPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => getIt<PendingPostsCubit>(),
    child: const PendingPostsScreen(),
  );
}
```

---

### 13) CORE: PENDING TAB ROUTE

File: `lib/core/routing/tabs/pending_tab_route.dart`

Mirror of `tiers_tab_route.dart`:
```dart
@RoutePage()
class PendingTabPage extends StatelessWidget {
  const PendingTabPage({super.key});

  @override
  Widget build(BuildContext context) => const AutoRouter();
}
```

---

### 14) CORE: APP BREAKPOINTS

File: `lib/core/theme/app_breakpoints.dart`

```dart
abstract final class AppBreakpoints {
  static const double medium = 600.0;
}
```

This constant is introduced here for use by slices D and E later.
Not needed inside `pending_posts_screen.dart` itself (the list is single-column).

---

### 15) CORE: APP ROUTER — ADD 4TH TAB

File: `lib/core/routing/app_router.dart`

Add import for `PendingTabRoute` and `PendingPostsRoute`.

Inside `get routes`, add as 4th child of `AppShellRoute`:
```dart
AutoRoute(
  page: PendingTabRoute.page,
  path: 'pending',
  guards: [authGuard, PermissionGuard({Permission.moderatePosts}, permissionCubit)],
  children: [
    AutoRoute(page: PendingPostsRoute.page, initial: true, path: ''),
    // Slice D (moderate_post) will add its route here
  ],
),
```

IMPORTANT: This is always declared at index 3 in the `AutoTabsRouter.routes` list,
regardless of whether it is visible in the nav bar. `auto_route` uses declaration
order for tab indexing.

After change: `dart run build_runner build --delete-conflicting-outputs`

---

### 16) CORE: APP SHELL SCREEN — ADD PENDING TAB

File: `lib/core/routing/app_shell_screen.dart`

**16a. `AutoTabsRouter.routes`:** extend from 3 to 4 entries:
```dart
routes: const [
  UsersTabRoute(),
  PostsTabRoute(),
  TiersTabRoute(),
  PendingTabRoute(),   // NEW — always at index 3
],
```

**16b. Logout redirect — extend `listenWhen`:**
```dart
listenWhen: (prev, curr) =>
    curr is AuthUnauthenticated &&
    (tabsRouter.activeIndex == 2 || tabsRouter.activeIndex == 3),
```

**16c. `_AppNavBar` — add Pending tab:**

The nav bar currently uses `BlocBuilder<AuthCubit>`. Wrap the existing builder
(or nest a second one) with `BlocBuilder<PermissionCubit, Set<Permission>>`:

```dart
BlocBuilder<PermissionCubit, Set<Permission>>(
  builder: (context, permissions) {
    final canModerate = permissions.contains(Permission.moderatePosts);
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        final isSuperuser = ...;
        return Row(
          children: [
            _NavTab(/* users */),
            _NavTab(/* posts */),
            if (isSuperuser) _NavTab(/* tiers */),
            if (canModerate)
              _NavTab(
                label: context.t.nav.pending,
                isSelected: tabsRouter.activeIndex == 3,
                onTap: () => _resetAndSwitch(
                  tabsRouter,
                  3,
                  PendingTabRoute.name,
                  const PendingPostsRoute(),
                ),
              ),
          ],
        );
      },
    );
  },
)
```

`PermissionCubit` is a `@lazySingleton` and is already in the widget tree — no
additional `BlocProvider` needed.

---

### 17) LOCALIZATION

`lib/core/i18n/i18n/en.json` — add to `"nav"`:
```json
"pending": "Pending"
```

Add to `"posts"`:
```json
"pendingPosts": {
  "title": "Pending Posts",
  "empty": "No pending posts",
  "loadError": "Failed to load pending posts",
  "loadMoreError": "Failed to load more",
  "eventCount": "Events"
}
```

`lib/core/i18n/i18n/ru.json` — same keys:
```json
"pending": "На проверке"
```
```json
"pendingPosts": {
  "title": "Посты на проверке",
  "empty": "Нет постов на проверке",
  "loadError": "Не удалось загрузить посты",
  "loadMoreError": "Не удалось загрузить ещё",
  "eventCount": "Событий"
}
```

After editing: `dart run slang`

---

## TESTS

`test/features/posts/pending_posts/`

### a) `data/pending_posts_adapter_test.dart`

Mocks: `MockPostsApiClient extends Mock implements PostsApiClient`,
`MockAppLogger extends Mock implements AppLogger`

- **200 success** — `items` mapped to `PendingPostItem` list; `moderationLog` count
  equals DTO list length; `eventType` and `action` parsed correctly;
  `hasMore = page * perPage < totalCount` correct for both true and false cases.
- **DioException 401** → `Left(UnauthorizedFailure)`
- **DioException 403** → `Left(PermissionDenied)`
- **DioException 404** → `Left(NotFoundFailure)`
- **DioException 500** → `Left(ServerFailure(statusCode: 500))`
- **DioException without statusCode (network)** → `Left(NetworkFailure)`
- **Unexpected `Exception`** → `Left(UnknownFailure)`, `logger.error` called with
  non-null `error` and `stackTrace`

### b) `application/pending_posts_cubit_test.dart`

Mocks: `MockGetPendingPostsUseCase`, `MockPostEventBus` (broadcast stream controller)

- `load()` success → emits `[PendingPostsLoading, PendingPostsLoaded(items, page:1, hasMore:true)]`
- `load()` failure → emits `[PendingPostsLoading, PendingPostsError(failure)]`
- `refresh()` → emits `[PendingPostsLoading, PendingPostsLoaded(freshItems, page:1)]`
- `loadMore()` success → emits
  `[PendingPostsLoaded(...loadMoreStatus.loading), PendingPostsLoaded(combined, page:2)]`
- `loadMore()` failure → emits
  `[PendingPostsLoaded(...loadMoreStatus.loading), PendingPostsLoaded(...loadMoreStatus.error)]`
- `loadMore()` when `!hasMore` → nothing emitted
- `loadMore()` when already `LoadMoreStatus.loading` → nothing emitted
- `loadMore()` when state is not `PendingPostsLoaded` → nothing emitted
- `PostModeratedEvent(postUuid)` when `PendingPostsLoaded` → item removed, new loaded
  state emitted without that item
- `PostModeratedEvent` when state is `PendingPostsInitial` → ignored, nothing emitted

Prior art: `test/features/posts/list_posts/application/list_posts_cubit_test.dart`

### c) `presentation/widgets/pending_post_tile_test.dart`

Mock cubit: none needed (tile is a pure widget).

- Renders `item.title` on screen
- Renders `item.authorUsername` on screen
- Renders formatted `item.createdAt`
- Renders moderation-log event count (e.g., `'3'` chip when `moderationLog` has 3 items)
- `onTap` callback is invoked when tile is tapped

### d) `presentation/pending_posts_screen_test.dart`

Mock: `MockPendingPostsCubit extends MockCubit<PendingPostsState> implements PendingPostsCubit`

- state=`loading` → `CircularProgressIndicator` visible
- state=`loaded(empty list)` → empty-state text visible, no list tiles
- state=`loaded(one item)` → item title visible in tile
- state=`loaded(loadMoreStatus.loading)` → spinner at bottom of list
- state=`loaded(loadMoreStatus.error)` → retry TextButton at bottom, tap calls `cubit.loadMore()`
- state=`error` → error text visible, Retry FilledButton tap calls `cubit.load()`

Prior art: `test/features/posts/list_posts/presentation/list_posts_screen_test.dart`

---

## REPORT

On completion provide:
- List of new files created
- List of modified files (including `_shared` and `core`)
- Confirmation that `flutter test test/features/posts/pending_posts/` is green
- Confirmation that `flutter test test/features/posts/list_posts/` is still green
  (post_event.dart change must not break existing cubit)
- Confirmation that no other slices were modified except `_shared` and `core/routing`
  and `core/rbac` and `core/theme`
- Confirmation `dart format .` — no diff
- Confirmation `dart analyze` — no warnings
- Confirmation codegen (`dart run slang` + `dart run build_runner build`) completed
  without errors

---

## WHAT NOT TO DO

- DO NOT start implementation before slice 0033 (moderator_contract) is merged —
  `Permission.moderatePosts` must exist in `permission.dart` first
- DO NOT reference slice D's `ModeratePostRoute` in the screen — it does not exist yet;
  use a no-op `onTap` and leave a `// TODO(0035): wire to ModeratePostRoute` comment
- DO NOT import `LoadMoreStatus` from `list_posts_state.dart` or `user_posts_state.dart` —
  define it locally in `pending_posts_state.dart`
- DO NOT import `PaginatedPosts` for this slice — use the new generic `PaginatedResult<T>`
- DO NOT add `PendingTabRoute` to `AutoTabsRouter.routes` before adding it to the `AppRouter`
  route tree — `auto_route` generates route index based on declaration order in the router,
  which must stay consistent
- DO NOT show the Pending tab in `_AppNavBar` using `isSuperuser` — check
  `Permission.moderatePosts` via `PermissionCubit` (moderators are not superusers)
- DO NOT add auth guard only at the route level without a defensive 401/403 check in the
  adapter — the adapter must handle both
- DO NOT hardcode any strings — use `context.t.posts.pendingPosts.*` and `context.t.nav.pending`
- DO NOT use `setState` in the screen — Cubit only
- DO NOT call Dio directly from presentation
- DO NOT touch `user_posts/`, `list_posts/`, `create_post/`, or any other slice's files
