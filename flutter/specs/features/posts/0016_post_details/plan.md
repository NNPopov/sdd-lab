# plan.md — 0016 · post_details

## 1. TITLE

Create the `post_details` slice in the `posts` feature.
A screen for viewing an individual post at the route `/user/:username/posts/:id`:
title → image (if present) → Markdown text → publication date.
The screen is public — accessible without authentication (guest and authenticated user alike).

---

## 2. CONTEXT

### READ:
- `@CLAUDE.md` — in full
- `@lib/features/posts/user_posts/**` — closest slice analogue (DO NOT copy, use as reference)
- `@lib/features/posts/_shared/data/posts_api_client.dart` — will be modified
- `@lib/features/posts/_shared/data/dto/post_dto.dart` — PostDto (nullable fields!)
- `@lib/features/posts/_shared/domain/entities/post.dart` — Post entity
- `@lib/core/errors/failure.dart` — Failure sealed class
- `@lib/core/routing/app_router.dart` — will be modified
- `@lib/core/logging/domain/app_logger.dart` — for the double catch in the adapter
- `@test/features/tiers/tier_details/application/tier_details_cubit_test.dart` — exact test analogue
- `@.claude/skills/bloc/SKILL.md`

### DO NOT READ:
- `@lib/features/posts/create_post/**`
- `@lib/features/posts/list_posts/**`
- `@lib/features/users/**`
- `@lib/features/tiers/**`
- `@lib/core/routing/app_router.gr.dart` — generated

---

## 3. API

```
GET /api/v1/{username}/post/{id}

Path params:
  username : String
  id       : int

Authentication: not required

Response 200:
{
  "id"                : 1,
  "title"             : "Post title",
  "text"              : "Full **markdown** text",
  "media_url"         : "https://...",           // may be null
  "created_by_user_id": 42,                      // may be null
  "created_at"        : "2026-01-15T14:30:00"    // may be null
}

Errors:
  404          → NotFoundFailure
  5xx          → ServerFailure(statusCode: ...)
  network fail → NetworkFailure
```

**Nullable fields in the adapter:**
- `dto.createdAt == null` → `DateTime(0)` — pattern from `UserPostsAdapter`
- `dto.createdByUserId == null` → `0`

---

## 4. TARGET STRUCTURE

```
lib/features/posts/post_details/
├── domain/
│   ├── ports/
│   │   └── post_details_port.dart       # abstract class, one method call(username, id)
│   └── usecases/
│       └── get_post_usecase.dart        # @injectable, delegates to port
├── data/
│   └── get_post_adapter.dart            # @LazySingleton(as: PostDetailsPort), double catch
├── application/
│   ├── post_details_cubit.dart          # @injectable, load(username, id)
│   └── post_details_state.dart          # sealed via freezed: initial/loading/loaded/error
└── presentation/
    ├── post_details_route.dart          # @RoutePage(), BlocProvider + cascade ..load
    └── post_details_screen.dart         # StatelessWidget, accepts username + id
```

**Modified existing files:**

| File | Change |
|---|---|
| `lib/features/posts/_shared/data/posts_api_client.dart` | Add `getPost` method |
| `lib/core/routing/app_router.dart` | Add `AutoRoute` for `PostDetailsRoute` |
| `lib/core/i18n/i18n/en.json` | Add `posts.postDetails.*` keys |
| `lib/core/i18n/i18n/ru.json` | Add `posts.postDetails.*` keys |

---

## 5. WHAT TO DO

### Step 1 — _shared: add method to PostsApiClient

File: `lib/features/posts/_shared/data/posts_api_client.dart`

```dart
@GET('/{username}/post/{id}')
Future<PostDto> getPost(
  @Path('username') String username,
  @Path('id') int id,
);
```

Run codegen:
```
dart run build_runner build --delete-conflicting-outputs
```

---

### Step 2 — domain

**`post_details_port.dart`:**
```dart
abstract class PostDetailsPort {
  Future<Either<Failure, Post>> call(String username, int id);
}
```

**`get_post_usecase.dart`:**
```dart
@injectable
class GetPostUseCase {
  GetPostUseCase(this._port);
  final PostDetailsPort _port;

  Future<Either<Failure, Post>> call(String username, int id) =>
      _port(username, id);
}
```

No business logic — delegates to the port directly.

---

### Step 3 — data: GetPostAdapter

File: `lib/features/posts/post_details/data/get_post_adapter.dart`

Annotation: `@LazySingleton(as: PostDetailsPort)`

Double catch is required (§8.4 CLAUDE.md):
```dart
@override
Future<Either<Failure, Post>> call(String username, int id) async {
  try {
    try {
      final dto = await _api.getPost(username, id);
      return Right(Post(
        id: dto.id,
        title: dto.title,
        text: dto.text,
        createdAt: dto.createdAt ?? DateTime(0),
        createdByUserId: dto.createdByUserId ?? 0,
        mediaUrl: dto.mediaUrl,
      ));
    } on DioException catch (e) {
      return Left(_mapHttp(e));
    }
  } catch (e, st) {
    _logger.error('GetPostAdapter.call failed', error: e, stackTrace: st);
    return const Left(Failure.unknown());
  }
}
```

HTTP mapping:
```dart
Failure _mapHttp(DioException e) {
  final statusCode = e.response?.statusCode;
  if (statusCode == 404) return const Failure.notFound();
  if (statusCode != null && statusCode >= 500) return Failure.server(statusCode: statusCode);
  return Failure.network(message: e.message);
}
```

---

### Step 4 — application

**`post_details_state.dart`** — sealed via freezed:
```dart
@freezed
sealed class PostDetailsState with _$PostDetailsState {
  const factory PostDetailsState.initial()                        = PostDetailsInitial;
  const factory PostDetailsState.loading()                        = PostDetailsLoading;
  const factory PostDetailsState.loaded({required Post post})     = PostDetailsLoaded;
  const factory PostDetailsState.error({required Failure failure}) = PostDetailsError;
}
```

**`post_details_cubit.dart`:**
```dart
@injectable
class PostDetailsCubit extends Cubit<PostDetailsState> {
  PostDetailsCubit(this._useCase) : super(const PostDetailsState.initial());
  final GetPostUseCase _useCase;

  Future<void> load(String username, int id) async {
    emit(const PostDetailsState.loading());
    final result = await _useCase(username, id);
    result.fold(
      (failure) => emit(PostDetailsState.error(failure: failure)),
      (post)    => emit(PostDetailsState.loaded(post: post)),
    );
  }
}
```

Run codegen for freezed:
```
dart run build_runner build --delete-conflicting-outputs
```

---

### Step 5 — presentation

**`post_details_route.dart`** — `@RoutePage()`, BlocProvider initialises via cascade:

```dart
@RoutePage()
class PostDetailsPage extends StatelessWidget {
  const PostDetailsPage({
    @PathParam('username') required this.username,
    @PathParam('id') required this.id,
    super.key,
  });

  final String username;
  final int id;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<PostDetailsCubit>()..load(username, id),
      child: PostDetailsScreen(username: username, id: id),
    );
  }
}
```

**`post_details_screen.dart`** — `StatelessWidget`, accepts `username` and `id`
(needed for Retry without access to route params):

**CRITICAL — screen structure:**
`Scaffold` with `AppBar` are OUTSIDE `BlocBuilder`.
`BlocBuilder` manages only the `body`. This way the AppBar is always visible — during loading,
error, and success:

```dart
class PostDetailsScreen extends StatelessWidget {
  const PostDetailsScreen({
    required this.username,
    required this.id,
    super.key,
  });

  final String username;
  final int id;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Scaffold(
      appBar: AppBar(title: Text(t.posts.postDetails.title)),
      body: BlocBuilder<PostDetailsCubit, PostDetailsState>(
        builder: (context, state) => switch (state) {
          PostDetailsInitial() || PostDetailsLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
          PostDetailsError() => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(t.posts.postDetails.loadError),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: () => unawaited(
                      context.read<PostDetailsCubit>().load(username, id),
                    ),
                    child: Text(t.common.retry),
                  ),
                ],
              ),
            ),
          PostDetailsLoaded(:final post) => SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(post.title,
                      style: Theme.of(context).textTheme.titleLarge),
                  if (post.mediaUrl != null) ...[
                    const SizedBox(height: 12),
                    Image.network(
                      post.mediaUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.broken_image, size: 48),
                    ),
                  ],
                  const SizedBox(height: 12),
                  MarkdownBody(data: post.text),
                  const SizedBox(height: 12),
                  Text(
                    DateFormat('dd MMM yyyy, HH:mm').format(post.createdAt),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
        },
      ),
    );
  }
}
```

`MarkdownBody` — from `flutter_markdown` (already in the project).
`DateFormat` — from `intl` (already in the project).
`unawaited` — from `dart:async`.

---

### Step 6 — integration: app_router.dart

Add import:
```dart
import 'package:flutter_application_1/features/posts/post_details/presentation/post_details_route.dart';
```

Add the route **AFTER** `/user/:username/posts/create` (the literal segment must be
above the parametric one — even if auto_route would not parse `create` as `int`,
explicit ordering is safer):

```dart
AutoRoute(
  page: PostDetailsRoute.page,
  path: '/user/:username/posts/:id',
),
```

Run codegen for router:
```
dart run build_runner build --delete-conflicting-outputs
```

---

### Step 7 — localisation

In `lib/core/i18n/i18n/en.json` add under the `"posts"` key:
```json
"postDetails": {
  "title": "Post",
  "loadError": "Failed to load post"
}
```

In `lib/core/i18n/i18n/ru.json` add under the `"posts"` key:
```json
"postDetails": {
  "title": "Пост",
  "loadError": "Не удалось загрузить пост"
}
```

The Retry button uses the already existing key `t.common.retry` — do not add a new one.

Run codegen:
```
dart run slang
```

---

### Step 8 — tests

**`test/features/posts/post_details/domain/usecases/get_post_usecase_test.dart`:**

```
class _MockPostDetailsPort extends Mock implements PostDetailsPort {}

group('GetPostUseCase'):
  - call(username, id) → port Right(post) → Right(post)
  - call(username, id) → port Left(NotFoundFailure) → Left(NotFoundFailure)
```

**`test/features/posts/post_details/application/post_details_cubit_test.dart`:**

```
class _MockGetPostUseCase extends Mock implements GetPostUseCase {}

group('PostDetailsCubit'):
  blocTest: load(username, id) → Right(post)           → emits [loading, loaded(post)]
  blocTest: load(username, id) → Left(NotFoundFailure) → emits [loading, error(NotFoundFailure)]
  blocTest: load(username, id) → Left(UnknownFailure)  → emits [loading, error(UnknownFailure)]
```

Exact structural analogue:
`test/features/tiers/tier_details/application/tier_details_cubit_test.dart`

---

## 6. REPORT

On completion, provide:
- Full list of new files (paths)
- Full list of modified files (paths)
- Confirmation that `create_post/`, `list_posts/`, `user_posts/` were not modified
  (exception: `_shared/data/posts_api_client.dart`)
- Confirmation that in `core/` only `routing/app_router.dart` and `i18n/` were modified
- Number of new tests, all green

---

## 7. WHAT NOT TO DO

- DO NOT add `authGuard` — the screen is public
- DO NOT create a separate DTO for `getPost` — use the existing `PostDto`
- DO NOT add a `retry` method to Cubit — the UI calls `load` again
- DO NOT add navigation from `user_posts` or `list_posts` — out of scope
- DO NOT render the author's name — `created_by_user_id` is an `int`, a separate request is not in scope
- DO NOT add `flutter_markdown` or `intl` to `pubspec.yaml` — they are already present
- DO NOT write a widget test — out of scope
- DO NOT use `*Repository` naming — only `*Port` and `*Adapter`
- DO NOT call `load` in `initState` — initialisation is via `..load()` in `BlocProvider.create`
- DO NOT add the key `posts.postDetails.retry` — use `t.common.retry`
- DO NOT put `Scaffold` inside `BlocBuilder` — Scaffold is outside, AppBar is always visible
