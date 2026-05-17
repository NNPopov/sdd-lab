# 0031 · posts / list_posts_feed — Implementation Plan

## Task

Add full logic to the existing stub screen `list_posts` in the `posts` feature.
Result: the Posts tab shows a globally infinite-scroll list of posts
(`GET /api/v1/posts`), accessible to all users including anonymous ones.
Authenticated users see a FAB to navigate to the create-post screen using their
own username. Deleted posts disappear from the list in real time via the shared
`PostEventBus`.

**Preliminary step (CRITICAL):** move `PaginatedPosts` and
`PaginatedPostsDto` from `user_posts/` into `_shared/`, eliminating the existing
slice-isolation violation in `PostsApiClient`.

---

## CONTEXT

READ:
- `CLAUDE.md` — in full
- `lib/features/posts/user_posts/**` — closest analogue (DO NOT copy, use as reference)
- `lib/features/posts/list_posts/**` — current stub (being replaced)
- `lib/features/posts/_shared/data/posts_api_client.dart` — adding method + fixing import
- `lib/features/posts/_shared/data/dto/post_item_dto.dart`
- `lib/features/posts/_shared/domain/entities/post.dart`
- `lib/features/posts/_shared/application/post_event.dart`
- `lib/features/posts/_shared/application/post_event_bus.dart`
- `lib/core/auth/application/auth_cubit.dart` — for FAB (currentUser)
- `lib/core/auth/application/auth_state.dart`
- `lib/core/errors/failure.dart`
- `lib/core/logging/domain/app_logger.dart`
- `lib/core/i18n/i18n/en.json`, `ru.json` — adding keys
- `agent_docs/architecture.md`
- `agent_docs/error_handling.md`
- `agent_docs/testing.md`
- `.claude/skills/bloc/SKILL.md`

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
GET http://127.0.0.1:8000/api/v1/posts?page={n}&items_per_page={k}
Authorization: not required (public endpoint)

Response 200:
{
  "items": [
    {
      "id": 0,
      "title": "string",
      "text": "string",
      "media_url": "string",
      "created_at": "2026-05-14T21:06:06.748Z",
      "created_by_user_id": 0,
      "username": "string"
    }
  ],
  "total_count": 0,
  "page": 0,
  "items_per_page": 0
}
```

The response structure is identical to `GET /{username}/posts`. The `username` field on
each item is the post author (needed for navigation and display in the tile).

`hasMore` is computed client-side: `page * itemsPerPage < totalCount`.

Errors:
- 5xx → `Failure.server(statusCode: ...)`
- network error (no connection) → `Failure.network(message: ...)`
- unexpected exception → `Failure.unknown()` + `logger.error`

The endpoint requires no token — anonymous requests work correctly.

---

## STRUCTURE

```
Step 0 (migration — MUST BE DONE FIRST):
  Move from user_posts to _shared:
  lib/features/posts/_shared/
  ├── data/dto/paginated_posts_dto.dart     ← from user_posts/data/dto/
  └── domain/entities/paginated_posts.dart  ← from user_posts/domain/entities/

  Update imports in all affected files:
  - _shared/data/posts_api_client.dart         (fix existing violation)
  - user_posts/data/user_posts_adapter.dart
  - user_posts/domain/usecases/user_posts_usecase.dart
  - user_posts/domain/ports/user_posts_port.dart
  - user_posts/application/user_posts_cubit.dart
  - test/features/posts/user_posts/**           (all test files that use these types)
  - test/features/posts/0030_adapt_paginated_posts_contract/**

New files (list_posts_feed slice):
lib/features/posts/list_posts/
├── domain/
│   ├── ports/
│   │   └── list_posts_port.dart
│   └── usecases/
│       └── list_posts_usecase.dart
├── data/
│   └── list_posts_adapter.dart
├── application/
│   ├── list_posts_cubit.dart
│   └── list_posts_state.dart
└── presentation/
    ├── widgets/
    │   └── list_post_tile.dart    # card with author username
    ├── list_posts_screen.dart     # REPLACES current stub
    └── list_posts_route.dart      # UPDATED: add BlocProvider

Modified existing files:
  - lib/features/posts/_shared/data/posts_api_client.dart
  - lib/features/posts/list_posts/presentation/list_posts_screen.dart
  - lib/features/posts/list_posts/presentation/list_posts_route.dart
  - lib/core/i18n/i18n/en.json
  - lib/core/i18n/i18n/ru.json

NOT modified:
  - lib/core/routing/app_router.dart       (routes already registered)
  - lib/core/routing/app_shell_screen.dart (tab already present)
```

---

## WHAT TO DO

### 0) MIGRATE SHARED ENTITIES (DO THIS FIRST)

**0a. Move `PaginatedPostsDto`**

Move the file from `user_posts/data/dto/paginated_posts_dto.dart` to
`_shared/data/dto/paginated_posts_dto.dart`. Update the `part` directive
(`part 'paginated_posts_dto.freezed.dart'` and `part 'paginated_posts_dto.g.dart'`).
The class and its contents remain unchanged.
Delete the file from `user_posts/data/dto/`.

**0b. Move `PaginatedPosts`**

Move the file from `user_posts/domain/entities/paginated_posts.dart` to
`_shared/domain/entities/paginated_posts.dart`.
Delete the file from `user_posts/domain/entities/`.

**0c. Update all imports**

The following files reference the old paths — fix them to the new ones:
- `_shared/data/posts_api_client.dart` — import of `PaginatedPostsDto` (fixes existing violation)
- `user_posts/data/user_posts_adapter.dart` — both types
- `user_posts/domain/usecases/user_posts_usecase.dart` — `PaginatedPosts`
- `user_posts/domain/ports/user_posts_port.dart` — `PaginatedPosts`
- `user_posts/application/user_posts_cubit.dart` — `PaginatedPosts`
- tests `test/features/posts/user_posts/**` — all files that use these types
- test `test/features/posts/0030_adapt_paginated_posts_contract/**`

**Verification after step 0:**
`flutter test test/features/posts/user_posts/` — must be green.
`dart analyze` — no warnings.
Only then proceed to step 1.

---

### 1) _SHARED: ADD METHOD TO API CLIENT

File: `lib/features/posts/_shared/data/posts_api_client.dart`

Add method (the `PaginatedPostsDto` import is already fixed to `_shared` in step 0):

```dart
@GET('/posts')
Future<PaginatedPostsDto> getPosts({
  @Query('page') required int page,
  @Query('items_per_page') required int perPage,
});
```

After the change, run: `dart run build_runner build --delete-conflicting-outputs`

---

### 2) DOMAIN: PORT

File: `lib/features/posts/list_posts/domain/ports/list_posts_port.dart`

```dart
abstract class ListPostsPort {
  Future<Either<Failure, PaginatedPosts>> call({
    required int page,
    required int perPage,
  });
}
```

Imports from `_shared`. No `username` parameter — global feed.

---

### 3) DOMAIN: USE CASE

File: `lib/features/posts/list_posts/domain/usecases/list_posts_usecase.dart`

`@injectable`. Takes `ListPostsPort` via constructor. Delegates directly.
Analogous to `UserPostsUseCase` — see it as a pattern.

---

### 4) DATA: ADAPTER

File: `lib/features/posts/list_posts/data/list_posts_adapter.dart`

`@LazySingleton(as: ListPostsPort)`. Takes `PostsApiClient` and `AppLogger`.

Call: `_api.getPosts(page: page, perPage: perPage)`.

Double catch (mandatory per CLAUDE.md):
```
outer: on Object catch (e, st) → _logger.error(...) → Left(Failure.unknown())
inner: on DioException catch (e) → _mapHttp(e) → Left(mapped)
```

`_mapHttp`:
- `statusCode == 404` → `Failure.notFound()`
- `statusCode != null && statusCode >= 500` → `Failure.server(statusCode: statusCode)`
- otherwise → `Failure.network(message: e.message)`

Success mapping: `dto.items.map((p) => Post(...)).toList()` — analogous to `UserPostsAdapter`.

---

### 5) APPLICATION: STATE

File: `lib/features/posts/list_posts/application/list_posts_state.dart`

Define `enum LoadMoreStatus { idle, loading, error }` here — do not import
from `user_posts_state.dart`.

```dart
@freezed
sealed class ListPostsState with _$ListPostsState {
  const factory ListPostsState.initial() = ListPostsInitial;
  const factory ListPostsState.loading() = ListPostsLoading;
  const factory ListPostsState.loaded({
    required List<Post> posts,
    required int page,
    required bool hasMore,
    @Default(LoadMoreStatus.idle) LoadMoreStatus loadMoreStatus,
    Failure? loadMoreError,
  }) = ListPostsLoaded;
  const factory ListPostsState.error(Failure failure) = ListPostsError;
}
```

After creating: `dart run build_runner build --delete-conflicting-outputs`.

---

### 6) APPLICATION: CUBIT

File: `lib/features/posts/list_posts/application/list_posts_cubit.dart`

`@injectable`. Constructor: `ListPostsUseCase _useCase, PostEventBus _eventBus`.

```dart
const int _pageSize = 10;
```

**Event bus subscription (in constructor):**
```dart
_sub = _eventBus.stream.listen(_onPostEvent);
```

**Event handler:**
```dart
void _onPostEvent(PostEvent event) {
  if (event is PostDeleted) {
    final current = state;
    if (current is ListPostsLoaded) {
      emit(current.copyWith(
        posts: current.posts.where((p) => p.id != event.id).toList(),
      ));
    }
  }
}
```

**Methods:**
- `load()` — `emit(loading)` → useCase(page:1, perPage:_pageSize) → fold → emit loaded/error
- `refresh()` — identical to `load()` (resets to first page)
- `loadMore()`:
  1. Guard: `state is! ListPostsLoaded` → return
  2. Guard: `!current.hasMore` → return
  3. Guard: `current.loadMoreStatus == LoadMoreStatus.loading` → return
  4. `emit(current.copyWith(loadMoreStatus: LoadMoreStatus.loading, loadMoreError: null))`
  5. `useCase(page: current.page + 1, perPage: _pageSize)`
  6. fold:
     - Left → `emit(current.copyWith(loadMoreStatus: LoadMoreStatus.error, loadMoreError: failure))`
     - Right → `emit(ListPostsState.loaded(posts: [...current.posts, ...paginated.items], page: paginated.page, hasMore: paginated.hasMore))`

**close():** `unawaited(_sub.cancel()); return super.close();`

No `username` parameter on any method.

---

### 7) PRESENTATION: LIST POST TILE

File: `lib/features/posts/list_posts/presentation/widgets/list_post_tile.dart`

`StatelessWidget`. Fields: `final Post post`, `final VoidCallback onOpenTap`.

Content inside a `Card`:
- `post.username ?? ''` — author name (style `bodySmall`, above or below title)
- `post.title` — `titleMedium`, bold
- Stripped preview `post.text` (duplicate `_stripMarkdown` logic locally — do not import from `user_posts`)
- Date: `DateFormat('d MMM yyyy').format(post.createdAt)`
- `TextButton.icon(icon: Icon(Icons.open_in_new), label: Text(context.t.posts.listPosts.openPost), onPressed: onOpenTap)` — right-aligned

IMPORTANT: `_stripMarkdown` is a pure function, duplicated in this file. Do not import
from `user_posts`. If needed, move to `_shared/presentation/` in the future.

---

### 8) PRESENTATION: SCREEN

File: `lib/features/posts/list_posts/presentation/list_posts_screen.dart`

`StatefulWidget` — needs `ScrollController`.

**initState:**
```dart
_scrollController.addListener(_onScroll);
unawaited(context.read<ListPostsCubit>().load());
```

**dispose:** `_scrollController.dispose()`

**_onScroll:**
```dart
if (_scrollController.position.pixels >=
    _scrollController.position.maxScrollExtent - 200) {
  unawaited(context.read<ListPostsCubit>().loadMore());
}
```

**build:**
- `AppBar(title: Text(context.t.nav.posts))`
- `floatingActionButton: BlocBuilder<AuthCubit, AuthState>(...)`:
  - `AuthAuthenticated` → `FloatingActionButton(tooltip: context.t.posts.listPosts.fabTooltip, onPressed: () => context.router.push(CreatePostRoute(username: authState.currentUser!.username)), child: Icon(Icons.add))`
  - otherwise → `SizedBox.shrink()`
- `body: BlocBuilder<ListPostsCubit, ListPostsState>(builder: ... switch(state) {...})`

Switch branches:
- `ListPostsInitial()` → `SizedBox.shrink()`
- `ListPostsLoading()` → `Center(child: CircularProgressIndicator())`
- `ListPostsLoaded(:final posts, :final loadMoreStatus)`:
  - `posts.isEmpty` → `Center(child: Text(context.t.posts.listPosts.empty))`
  - otherwise → `RefreshIndicator(onRefresh: () => context.read<ListPostsCubit>().refresh(), child: ListView.builder(controller: _scrollController, ...))`
  - `itemCount: posts.length + _trailingCount(loadMoreStatus)`
  - if `index < posts.length` → `ListPostTile(post: posts[index], onOpenTap: () => context.router.push(PostDetailsRoute(username: posts[index].username!, id: posts[index].id)))`
  - trailer: loading spinner / TextButton retry (calls `loadMore()`) / SizedBox
- `ListPostsError()` → `Center(Column([Text(context.t.posts.listPosts.loadError), FilledButton(onPressed: () => unawaited(cubit.load()), child: Text(context.t.common.retry))]))` 

---

### 9) PRESENTATION: ROUTE

File: `lib/features/posts/list_posts/presentation/list_posts_route.dart`

Update the existing `ListPostsPage.build`:

```dart
@override
Widget build(BuildContext context) {
  return BlocProvider(
    create: (_) => getIt<ListPostsCubit>(),
    child: const ListPostsScreen(),
  );
}
```

`AuthCubit` does not need to be provided — it is `@lazySingleton`, available via `context.read` from the app widget tree.

---

### 10) LOCALIZATION

`lib/core/i18n/i18n/en.json` — add under `"posts"`:
```json
"listPosts": {
  "empty": "No posts yet",
  "loadError": "Failed to load posts",
  "fabTooltip": "New post",
  "openPost": "Open"
}
```

`lib/core/i18n/i18n/ru.json` — same:
```json
"listPosts": {
  "empty": "Постов пока нет",
  "loadError": "Не удалось загрузить посты",
  "fabTooltip": "Новый пост",
  "openPost": "Открыть"
}
```

After editing: `dart run slang`

---

## TESTS

`test/features/posts/list_posts/`

### a) `domain/usecases/list_posts_usecase_test.dart`
- `call` delegates to port and returns `Right(paginatedPosts)` — success
- `call` returns `Left(failure)` when port returned Left

Mock: `MockListPostsPort extends Mock implements ListPostsPort`

### b) `data/list_posts_adapter_test.dart`
- success 200 → `Right(PaginatedPosts)`, fields mapped, `hasMore` correct
- `DioException` with `statusCode == 404` → `Left(NotFoundFailure)`
- `DioException` with `statusCode == 500` → `Left(ServerFailure(statusCode: 500))`
- `DioException` without statusCode (network) → `Left(NetworkFailure)`
- unexpected `Exception` → `Left(UnknownFailure)`, `logger.error` called with non-null `error` and `stackTrace`

Mocks: `MockPostsApiClient`, `MockAppLogger`

### c) `application/list_posts_cubit_test.dart`
- `load()` success → emits `[ListPostsLoading, ListPostsLoaded(posts, page:1, hasMore:true)]`
- `load()` failure → emits `[ListPostsLoading, ListPostsError(failure)]`
- `loadMore()` success → emits `[ListPostsLoaded(...loadMoreStatus.loading), ListPostsLoaded(combinedPosts, page:2)]`
- `loadMore()` failure → emits `[ListPostsLoaded(...loadMoreStatus.loading), ListPostsLoaded(...loadMoreStatus.error)]`
- `loadMore()` when `!hasMore` → nothing emitted
- `loadMore()` when already `loadMoreStatus.loading` → nothing emitted
- `loadMore()` when state is not loaded → nothing emitted
- `refresh()` → emits `[ListPostsLoading, ListPostsLoaded(freshPosts, page:1)]`
- `PostDeleted` event when `ListPostsLoaded` → removes post from list, emits new loaded state without it
- `PostDeleted` event when `ListPostsInitial` → ignored, nothing emitted

Mocks: `MockListPostsUseCase`, `MockPostEventBus` (broadcast stream with no events)

### d) `presentation/list_posts_screen_test.dart`
Mocks: `MockListPostsCubit`, `MockAuthCubit`

- state=loading → `CircularProgressIndicator` visible
- state=loaded(empty list) → empty state text visible
- state=loaded(one post) → author username rendered in tile
- state=loaded(loadMoreStatus.loading) → progress indicator at bottom of list
- state=loaded(loadMoreStatus.error) → retry TextButton at bottom, tap → `cubit.loadMore()` called
- state=error → error text visible, retry tap → `cubit.load()` called
- authState=authenticated → FAB visible
- authState=unauthenticated → FAB not visible
- FAB tap when authenticated → navigation to `CreatePostRoute`

Prior art: `user_posts_screen_test.dart`

### e) Outside-in test (generated by `/slice-test-red`)
Real: `ListPostsAdapter → ListPostsUseCase → ListPostsCubit`
Mock: Dio (HTTP), `AppLogger`, `PostEventBus`
Entry point: `cubit.load()`

Scenarios:
1. First page: `total_count=100, page=1, items_per_page=10` → `hasMore=true`, post fields mapped correctly
2. Last page: `total_count=10, page=1, items_per_page=10` → `hasMore=false`

Prior art: `adapt_paginated_posts_contract_outside_in_test.dart`

---

## REPORT

On completion provide:
- List of created files
- List of modified files (including migration from step 0)
- Confirmation that `flutter test test/features/posts/user_posts/` is green after migration
- Confirmation that other slices were NOT touched (except `_shared`)
- Confirmation `dart format .` — no diff
- Confirmation `dart analyze` — no warnings
- Confirmation codegen (`dart run slang` + `dart run build_runner build`) — no errors

---

## WHAT NOT TO DO

- DO NOT start `list_posts` code before step 0 is complete — migrate shared entities first
- DO NOT import from `user_posts/` in `list_posts/` — slice isolation violation
- DO NOT use `PostTile` from `user_posts/` — create a separate `ListPostTile`
- DO NOT import `LoadMoreStatus` from `user_posts_state.dart` — define it in `list_posts_state.dart`
- DO NOT add `username` parameter to `ListPostsCubit` methods — global feed
- DO NOT add auth guard to `ListPostsRoute` — the feed is public
- DO NOT touch `app_router.dart` — `ListPostsRoute` routes are already registered
- DO NOT touch `app_shell_screen.dart` — the Posts tab is already added
- DO NOT hardcode strings in UI — only via `context.t`
- DO NOT use `setState` — Cubit only
- DO NOT call Dio directly from presentation
