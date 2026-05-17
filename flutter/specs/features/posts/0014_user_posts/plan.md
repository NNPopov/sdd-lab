# 0014 · user_posts — Implementation Plan

## Title

Task: create a new `user_posts` slice (0014) in the `posts` feature.  
A paginated list of posts for a specific user: post title, text preview (100 characters plain text,
stripped markdown), creation date.
Route `/user/:username/posts`, no guard, accessible to all (including unauthenticated users).

---

## Context

```
READ:
- @CLAUDE.md in full
- @lib/features/users/list_users/**          — closest pagination analogue
                                               (DO NOT copy, use as reference)
- @lib/features/users/_shared/data/users_api_client.dart
                                             — template for PostsApiClient
- @lib/features/posts/list_posts/presentation/list_posts_route.dart
                                             — existing route, do not touch
- @lib/features/posts/posts_feature_module.dart
                                             — we will add PostsApiClient
- @lib/core/routing/app_router.dart          — we will add UserPostsRoute
- @lib/core/errors/failure.dart
- @lib/core/i18n/i18n/en.json
- @lib/core/i18n/i18n/ru.json
- @.claude/skills/bloc/SKILL.md

DO NOT READ:
- @lib/features/users/create_user/**
- @lib/features/users/edit_user/**
- @lib/features/users/delete_user/**
- @lib/features/users/user_details/**
- @lib/features/tiers/**
- @lib/features/auth/**
```

---

## API

```
GET http://127.0.0.1:8000/api/v1/{username}/posts
Query: page (int), items_per_page (int, default 10)
Authorization: not required — public endpoint
```

Response 200:
```json
{
  "data": [
    {
      "id": 0,
      "title": "This is my post",
      "text": "This is the content of my post.",
      "created_at": "2026-04-29T12:45:40.442Z"
    }
  ],
  "total_count": 0,
  "has_more": true,
  "page": 0,
  "items_per_page": 0
}
```

Server-side `text` field constraints:
- `min_length=1, max_length=63206`
- Content is stored in **Markdown** format

Errors:
- `404` → `NotFoundFailure` (user not found)
- `5xx` → `ServerFailure`
- network → `NetworkFailure`
- other → `UnknownFailure`

---

## Structure

```
lib/features/posts/
├── _shared/                                  # NEW FOLDER
│   └── data/
│       └── posts_api_client.dart             # Retrofit client for the posts feature
├── list_posts/                               # DO NOT TOUCH
├── user_posts/                               # NEW SLICE
│   ├── domain/
│   │   ├── entities/
│   │   │   ├── post.dart                     # id, title, text, createdAt
│   │   │   └── paginated_posts.dart          # items, hasMore, page
│   │   ├── ports/
│   │   │   └── user_posts_port.dart          # 1 method: call(username, page, perPage)
│   │   └── usecases/
│   │       └── user_posts_usecase.dart
│   ├── data/
│   │   ├── dto/
│   │   │   ├── post_dto.dart                 # freezed, soft contract
│   │   │   └── paginated_posts_dto.dart
│   │   └── user_posts_adapter.dart           # implements UserPostsPort, double catch
│   ├── application/
│   │   ├── user_posts_cubit.dart             # load / refresh / loadMore
│   │   └── user_posts_state.dart             # sealed + LoadMoreStatus
│   └── presentation/
│       ├── user_posts_screen.dart
│       ├── user_posts_route.dart
│       └── widgets/
│           └── post_tile.dart                # title + stripped preview + date
└── posts_feature_module.dart                 # MODIFY: add PostsApiClient

Modified existing files:
  lib/features/posts/posts_feature_module.dart
  lib/core/routing/app_router.dart
  lib/core/i18n/i18n/en.json
  lib/core/i18n/i18n/ru.json
```

---

## What to Do

### 1) _SHARED — PostsApiClient

Create `lib/features/posts/_shared/data/posts_api_client.dart`:

```dart
@RestApi()
abstract class PostsApiClient {
  factory PostsApiClient(Dio dio) = _PostsApiClient;

  @GET('/{username}/posts')
  Future<PaginatedPostsDto> getUserPosts(
    @Path('username') String username, {
    @Query('page') required int page,
    @Query('items_per_page') required int perPage,
  });
}
```

Modify `posts_feature_module.dart` — add registration:

```dart
@module
abstract class PostsFeatureModule {
  @lazySingleton
  PostsApiClient postsApiClient(Dio dio) => PostsApiClient(dio);
}
```

### 2) DOMAIN

`post.dart` — strict plain Dart class, no freezed (not necessary):
- `required int id`
- `required String title`
- `required String text` (full markdown, truncation happens in the UI)
- `required DateTime createdAt`

`paginated_posts.dart`:
- `required List<Post> items`
- `required bool hasMore`
- `required int page`

`user_posts_port.dart` — narrow port, 1 method:
```dart
abstract class UserPostsPort {
  Future<Either<Failure, PaginatedPosts>> call({
    required String username,
    required int page,
    required int perPage,
  });
}
```

`user_posts_usecase.dart` — delegates to the port without any logic.

### 3) DATA

`post_dto.dart` — soft contract (`@freezed sealed class`):
- `required int id`
- `@Default('') String title`
- `@Default('') String text`
- `@JsonKey(name: 'created_at') DateTime? createdAt`

`paginated_posts_dto.dart`:
- `@Default([]) List<PostDto> data`
- `@JsonKey(name: 'has_more') @Default(false) bool hasMore`
- `@Default(1) int page`

`user_posts_adapter.dart` — double catch per §8.4 CLAUDE.md:
- inner: `on DioException` → mapping to Failure
- outer: `catch (e, st)` → logger.error + Left(Failure.unknown())
- Error mapping: 404 → NotFoundFailure, 5xx → ServerFailure
- Mapper `dto.toDomain()`: if `createdAt == null` → `DateTime(0)` as fallback

### 4) APPLICATION

`user_posts_state.dart` — following the `UsersListState` template:

```dart
enum LoadMoreStatus { idle, loading, error }

@freezed
sealed class UserPostsState with _$UserPostsState {
  const factory UserPostsState.initial() = UserPostsInitial;
  const factory UserPostsState.loading() = UserPostsLoading;
  const factory UserPostsState.loaded({
    required List<Post> posts,
    required int page,
    required bool hasMore,
    @Default(LoadMoreStatus.idle) LoadMoreStatus loadMoreStatus,
    Failure? loadMoreError,
  }) = UserPostsLoaded;
  const factory UserPostsState.error(Failure failure) = UserPostsError;
}
```

`user_posts_cubit.dart` — three public methods:
- `load(String username)` — initial load, page=1, emit Loading → Loaded/Error
- `refresh(String username)` — reset to page=1, emit Loading → Loaded/Error
- `loadMore(String username)` — append, only if `state is UserPostsLoaded && hasMore && loadMoreStatus != loading`

**IMPORTANT:** `username` is passed as a parameter to each method. The Cubit does not
store username in its fields — that is presentation layer data.

### 5) PRESENTATION

`user_posts_route.dart`:
```dart
@RoutePage()
class UserPostsPage extends StatelessWidget {
  const UserPostsPage({@PathParam('username') required this.username, super.key});
  final String username;
  // BlocProvider<UserPostsCubit> → UserPostsScreen
}
```

`user_posts_screen.dart` — `StatefulWidget`:
- `initState` calls `context.read<UserPostsCubit>().load(widget.username)`
- `Scaffold` with `AppBar(title: Text(context.t.posts.userPosts.title(username: widget.username)))`
- `RefreshIndicator` + `ListView.builder` with `NotificationListener<ScrollNotification>`
  for loadMore — identical to the pattern in `UsersScreen`
- Empty list: `Center(child: Text(context.t.posts.userPosts.empty))`
- Error: text + `FilledButton` Retry

`post_tile.dart` — `Card` > `InkWell(onTap: null)` > `Padding` > `Column`:
- `Text(post.title, style: bold)`
- `Text(_stripMarkdown(post.text))`
- `Text(DateFormat('d MMM yyyy').format(post.createdAt))`

Private strip function (only in this file, no dependencies):
```dart
String _stripMarkdown(String text) {
  final stripped = text
      .replaceAll(RegExp(r'#+\s'), '')
      .replaceAll(RegExp(r'\*\*(.+?)\*\*', dotAll: true), r'$1')
      .replaceAll(RegExp(r'\*(.+?)\*', dotAll: true), r'$1')
      .replaceAll(RegExp(r'!\[.*?\]\(.*?\)'), '')
      .replaceAll(RegExp(r'\[(.+?)\]\(.+?\)', dotAll: true), r'$1')
      .replaceAll(RegExp(r'`+.+?`+', dotAll: true), '')
      .replaceAll(RegExp(r'\n+'), ' ')
      .trim();
  return stripped.length > 100 ? '${stripped.substring(0, 100)}...' : stripped;
}
```

`DateFormat` — from the `intl` package, which is already in the dependencies.  
**Do not add flutter_markdown** — it is only needed for the detail page.

### 6) INTEGRATION

`app_router.dart` — add the route (no guard, at root level):
```dart
AutoRoute(
  page: UserPostsRoute.page,
  path: '/user/:username/posts',
),
```

Run codegen:
```
dart run build_runner build --delete-conflicting-outputs
dart run slang
```

### 7) LOCALISATION

`en.json` — add to the `posts` section:
```json
"userPosts": {
  "title": "@{username}'s posts",
  "empty": "No posts yet",
  "loadError": "Failed to load posts"
}
```

`ru.json`:
```json
"userPosts": {
  "title": "Посты @{username}",
  "empty": "Нет постов",
  "loadError": "Не удалось загрузить посты"
}
```

### 8) TESTS

`test/features/posts/user_posts/`

**a) `application/user_posts_cubit_test.dart`:**
- `load` success → emits `[UserPostsLoading, UserPostsLoaded(posts, hasMore, page=1)]`
- `load` failure → emits `[UserPostsLoading, UserPostsError]`
- `refresh` → emits `[UserPostsLoading, UserPostsLoaded(page=1)]` (list is not appended)
- `loadMore` with `hasMore=true` → emits `UserPostsLoaded` with incremented page and merged posts
- `loadMore` with `hasMore=false` → port is not called
- `loadMore` while `loadMoreStatus == loading` → port is not called twice

**b) `data/user_posts_adapter_test.dart`:**
- success: api 200 → `Right(PaginatedPosts)`
- 404 → `Left(NotFoundFailure)`
- DioException (network) → `Left(NetworkFailure)`
- unexpected `Exception` → `Left(UnknownFailure)`, `logger.error` called with stackTrace

---

## Report

On completion, provide:
- List of created and modified files
- Confirmation that `list_posts` and other slices were not touched
- Codegen completed (`build_runner` + `slang`), no errors
- `dart analyze` without errors
- Tests: number of test cases, all green

---

## What Not to Do

- ❌ Touch `list_posts` — leave it as-is
- ❌ Add `AuthGuard` or `PermissionGuard` to `UserPostsRoute`
- ❌ Render Markdown — only strip for the preview, do not add `flutter_markdown`
- ❌ Store `username` in Cubit fields — pass it to each method
- ❌ Put the `Post` entity in `_shared/` — until a second slice actually uses it
- ❌ Add navigation from `UserDetailsScreen` here — that is a separate task
- ❌ Add new packages to `pubspec.yaml` — `intl` is already in the dependencies
