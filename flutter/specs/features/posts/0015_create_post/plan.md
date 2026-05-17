# 0015 · create_post — Implementation Plan

## Title

Task: create a new `create_post` slice (0015) in the `posts` feature.  
An authenticated user fills in a form (Title, Media URL, Text with live Markdown preview)
and publishes a post. On success — redirect to `/user/:username/posts` with the updated list.

---

## Context

```
READ:
- @CLAUDE.md in full
- @lib/features/users/create_user/**         — closest analogue of a creation form
                                               (DO NOT copy, use as reference)
- @lib/features/posts/_shared/data/posts_api_client.dart
                                             — we will add the createPost method
- @lib/features/posts/user_posts/domain/entities/post.dart
                                             — move to _shared + add fields
- @lib/features/posts/user_posts/data/dto/post_dto.dart
                                             — move to _shared + add fields
- @lib/features/posts/user_posts/application/user_posts_cubit.dart
                                             — we will call refresh() from the UI after success
- @lib/features/posts/user_posts/presentation/user_posts_screen.dart
                                             — context needed for BlocListener
- @lib/core/auth/application/auth_cubit.dart — currentUser for the ownership check
- @lib/core/auth/domain/entities/current_user.dart
- @lib/core/errors/failure.dart
- @lib/core/routing/app_router.dart          — we will add CreatePostRoute
- @lib/core/i18n/i18n/en.json
- @lib/core/i18n/i18n/ru.json
- @.claude/skills/bloc/SKILL.md

DO NOT READ:
- @lib/features/posts/list_posts/**
- @lib/features/users/list_users/**
- @lib/features/users/edit_user/**
- @lib/features/users/delete_user/**
- @lib/features/tiers/**
- @lib/features/auth/**
```

---

## API

```
POST http://127.0.0.1:8000/api/v1/{username}/post
Header: Authorization: Bearer <token>
Body: { "title": string, "text": string, "media_url": string | null }
```

Response 200:
```json
{
  "id": 1,
  "title": "My post",
  "text": "Content in **markdown**",
  "media_url": null,
  "created_by_user_id": 42,
  "created_at": "2026-04-29T12:00:00Z"
}
```

Errors:
- `401` → `UnauthorizedFailure` (token invalid)
- `403` → `ForbiddenFailure` (attempt to create under another user's name)
- `422` → `ValidationFailure` (server-side constraints violated)
- `5xx` → `ServerFailure`
- network → `NetworkFailure`
- other → `UnknownFailure`

---

## Structure

```
lib/features/posts/
├── _shared/
│   ├── data/
│   │   ├── dto/
│   │   │   └── post_dto.dart               # MOVE from user_posts/data/dto/ +
│   │   │                                   #   add media_url, created_by_user_id
│   │   └── posts_api_client.dart           # MODIFY: add createPost method
│   └── domain/
│       └── entities/
│           └── post.dart                   # MOVE from user_posts/domain/entities/ +
│                                           #   add mediaUrl?, createdByUserId
├── user_posts/                             # MODIFY: update Post + PostDto imports
│   ├── data/
│   │   ├── dto/                            # DELETE post_dto.dart (moved to _shared)
│   │   └── user_posts_adapter.dart
│   └── domain/
│       └── entities/                       # DELETE post.dart (moved to _shared)
└── create_post/                            # NEW SLICE
    ├── domain/
    │   ├── entities/
    │   │   └── new_post_data.dart          # value object: username, title, text, mediaUrl?
    │   ├── ports/
    │   │   └── create_post_port.dart       # Future<Either<Failure, void>> call(NewPostData)
    │   └── usecases/
    │       └── create_post_usecase.dart    # ownership check + delegates to port
    ├── data/
    │   └── create_post_adapter.dart        # implements CreatePostPort, double catch
    ├── application/
    │   ├── create_post_cubit.dart
    │   └── create_post_state.dart          # sealed: initial, loading, success, error(Failure)
    └── presentation/
        ├── create_post_route.dart          # @RoutePage(), @PathParam username
        ├── create_post_screen.dart         # StatefulWidget, GlobalKey<FormState>
        └── widgets/
            └── markdown_preview.dart      # live preview widget

Modified existing files:
  lib/features/posts/_shared/data/posts_api_client.dart
  lib/features/posts/user_posts/data/dto/post_dto.dart        → DELETE, move
  lib/features/posts/user_posts/domain/entities/post.dart     → DELETE, move
  lib/features/posts/user_posts/data/user_posts_adapter.dart  → update import
  lib/features/posts/user_posts/domain/*/usecases/*           → update import
  lib/features/posts/user_posts/presentation/**               → update import
  lib/core/routing/app_router.dart
  lib/core/i18n/i18n/en.json
  lib/core/i18n/i18n/ru.json
  pubspec.yaml                                                 → add flutter_markdown
```

---

## What to Do

### 1) _SHARED REFACTORING — Moving Post + PostDto

**IMPORTANT:** This step must be done first to avoid breaking user_posts.
Move in a single commit together with updating imports.

**`lib/features/posts/_shared/domain/entities/post.dart`** (new location):
```dart
class Post {
  const Post({
    required this.id,
    required this.title,
    required this.text,
    required this.createdAt,
    this.mediaUrl,
    required this.createdByUserId,
  });

  final int id;
  final String title;
  final String text;
  final DateTime createdAt;
  final String? mediaUrl;
  final int createdByUserId;
}
```

**`lib/features/posts/_shared/data/dto/post_dto.dart`** (new location):
```dart
@freezed
sealed class PostDto with _$PostDto {
  const factory PostDto({
    required int id,
    @Default('') String title,
    @Default('') String text,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'media_url') String? mediaUrl,
    @JsonKey(name: 'created_by_user_id') int? createdByUserId,
  }) = _PostDto;

  factory PostDto.fromJson(Map<String, dynamic> json) =>
      _$PostDtoFromJson(json);
}
```

After moving:
- Delete `user_posts/data/dto/post_dto.dart` (and `.freezed.dart`, `.g.dart`)
- Delete `user_posts/domain/entities/post.dart`
- Update all imports in `user_posts/` to the new paths from `_shared/`
- Mapper `toDomain()` in `user_posts_adapter.dart`: add `createdByUserId: dto.createdByUserId ?? 0` as fallback

### 2) _SHARED — PostsApiClient

Add a method to `lib/features/posts/_shared/data/posts_api_client.dart`:

```dart
import 'package:flutter_application_1/features/posts/_shared/data/dto/create_post_request_dto.dart';
import 'package:flutter_application_1/features/posts/_shared/data/dto/post_dto.dart';

// inside PostsApiClient:
@POST('/{username}/post')
Future<PostDto> createPost(
  @Path('username') String username,
  @Body() CreatePostRequestDto body,
);
```

**IMPORTANT:** `CreatePostRequestDto` — new file in `_shared/data/dto/`:
```dart
@freezed
sealed class CreatePostRequestDto with _$CreatePostRequestDto {
  const factory CreatePostRequestDto({
    required String title,
    required String text,
    @JsonKey(name: 'media_url') String? mediaUrl,
  }) = _CreatePostRequestDto;

  factory CreatePostRequestDto.fromJson(Map<String, dynamic> json) =>
      _$CreatePostRequestDtoFromJson(json);
}
```

### 3) DOMAIN

**`new_post_data.dart`** — simple plain Dart class, no freezed:
```dart
class NewPostData {
  const NewPostData({
    required this.username,
    required this.title,
    required this.text,
    this.mediaUrl,
  });

  final String username;
  final String title;
  final String text;
  final String? mediaUrl;
}
```

**`create_post_port.dart`** — narrow port, 1 method:
```dart
abstract class CreatePostPort {
  Future<Either<Failure, void>> call(NewPostData data);
}
```

**`create_post_usecase.dart`** — ownership check + delegates to port.
Gets `AuthCubit` via `get_it<AuthCubit>()`:
```dart
class CreatePostUseCase {
  CreatePostUseCase(this._port, this._authCubit);

  final CreatePostPort _port;
  final AuthCubit _authCubit;

  Future<Either<Failure, void>> call(NewPostData data) async {
    final currentUser = _authCubit.currentUser;
    if (currentUser == null || currentUser.username != data.username) {
      return const Left(Failure.forbidden(message: 'Cannot post as another user'));
    }
    return _port(data);
  }
}
```

### 4) DATA

**`create_post_adapter.dart`** — implements `CreatePostPort`. Double catch per §8.4:

```dart
@LazySingleton(as: CreatePostPort)
class CreatePostAdapter implements CreatePostPort {
  CreatePostAdapter(this._api, this._logger);
  final PostsApiClient _api;
  final AppLogger _logger;

  @override
  Future<Either<Failure, void>> call(NewPostData data) async {
    try {
      try {
        await _api.createPost(
          data.username,
          CreatePostRequestDto(
            title: data.title,
            text: data.text,
            mediaUrl: data.mediaUrl,
          ),
        );
        return const Right(null);
      } on DioException catch (e) {
        return Left(_mapHttp(e));
      }
    } catch (e, st) {
      _logger.error('CreatePostAdapter.call failed unexpectedly', error: e, stackTrace: st);
      return const Left(Failure.unknown());
    }
  }

  Failure _mapHttp(DioException e) {
    return switch (e.response?.statusCode) {
      401 => const Failure.unauthorized(message: 'Unauthorized'),
      403 => const Failure.forbidden(message: 'Forbidden'),
      422 => const Failure.validation(fieldErrors: {}),
      _ => e.type == DioExceptionType.connectionError
          ? const Failure.network()
          : Failure.server(statusCode: e.response?.statusCode),
    };
  }
}
```

### 5) APPLICATION

**`create_post_state.dart`** — sealed via freezed:
```dart
@freezed
sealed class CreatePostState with _$CreatePostState {
  const factory CreatePostState.initial() = CreatePostInitial;
  const factory CreatePostState.loading() = CreatePostLoading;
  const factory CreatePostState.success() = CreatePostSuccess;
  const factory CreatePostState.error(Failure failure) = CreatePostError;
}
```

**`create_post_cubit.dart`**:
```dart
@injectable
class CreatePostCubit extends Cubit<CreatePostState> {
  CreatePostCubit(this._useCase) : super(const CreatePostState.initial());

  final CreatePostUseCase _useCase;

  Future<void> submit(NewPostData data) async {
    emit(const CreatePostState.loading());
    final result = await _useCase(data);
    result.fold(
      (failure) => emit(CreatePostState.error(failure)),
      (_) => emit(const CreatePostState.success()),
    );
  }
}
```

### 6) PRESENTATION

**`create_post_route.dart`**:
```dart
@RoutePage()
class CreatePostPage extends StatelessWidget {
  const CreatePostPage({
    @PathParam('username') required this.username,
    super.key,
  });

  final String username;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<CreatePostCubit>(),
      child: CreatePostScreen(username: username),
    );
  }
}
```

**`create_post_screen.dart`** — `StatefulWidget` with `GlobalKey<FormState>`:
- Three `TextFormField`: title, mediaUrl (optional), text
- `TextEditingController` for the text field → live preview
- `BlocConsumer`:
  - builder: when `loading` — Publish button disabled + `CircularProgressIndicator`; when `error` — `Text` with error message above the button
  - listener: on `success` → `context.router.maybePop()` + `context.read<UserPostsCubit>().refresh(username)`
- `SingleChildScrollView` for scrolling all content
- Widget order: title → mediaUrl → text → preview → button

**`widgets/markdown_preview.dart`** — simple widget:
```dart
class MarkdownPreview extends StatelessWidget {
  const MarkdownPreview({required this.text, super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.t.posts.createPost.previewLabel, style: ...),
        const Divider(),
        MarkdownBody(data: text),
      ],
    );
  }
}
```

### 7) FORM VALIDATION (in the form, not in Cubit)

| Field | Rules |
|---|---|
| Title | required, length 2–30 characters |
| Media URL | optional; if entered — not an empty string |
| Text | required, length 100–63206 characters |

Use `validator:` in `TextFormField`. Call `_formKey.currentState!.validate()` before calling `cubit.submit()`.

### 8) INTEGRATION

**`app_router.dart`** — add the route (with `authGuard`, after `UserPostsRoute`):
```dart
AutoRoute(
  page: CreatePostRoute.page,
  path: '/user/:username/posts/create',
  guards: [authGuard],
),
```

Add import for `create_post_route.dart`.

**`pubspec.yaml`** — add:
```yaml
flutter_markdown: ^0.7.7   # or the latest stable version
```

Run:
```
flutter pub get
dart run build_runner build --delete-conflicting-outputs
dart run slang
```

### 9) LOCALISATION

`en.json` — add to the `posts` section:
```json
"createPost": {
  "title": "New Post",
  "titleLabel": "Title",
  "titleHint": "Post title",
  "mediaUrlLabel": "Media URL (optional)",
  "mediaUrlHint": "https://...",
  "textLabel": "Text (Markdown)",
  "textHint": "Write your post...",
  "previewLabel": "Preview",
  "publishButton": "Publish",
  "errors": {
    "titleTooShort": "Title must be at least 2 characters",
    "titleTooLong": "Title must be at most 30 characters",
    "mediaUrlEmpty": "Media URL cannot be empty if provided",
    "textTooShort": "Text must be at least 100 characters",
    "textTooLong": "Text must be at most 63206 characters",
    "forbidden": "You can only publish posts as yourself",
    "generic": "Failed to publish post. Please try again."
  }
}
```

`ru.json`:
```json
"createPost": {
  "title": "Новый пост",
  "titleLabel": "Заголовок",
  "titleHint": "Заголовок поста",
  "mediaUrlLabel": "Ссылка на медиа (опционально)",
  "mediaUrlHint": "https://...",
  "textLabel": "Текст (Markdown)",
  "textHint": "Напишите пост...",
  "previewLabel": "Предпросмотр",
  "publishButton": "Опубликовать",
  "errors": {
    "titleTooShort": "Заголовок должен содержать не менее 2 символов",
    "titleTooLong": "Заголовок не должен превышать 30 символов",
    "mediaUrlEmpty": "Ссылка на медиа не может быть пустой, если указана",
    "textTooShort": "Текст должен содержать не менее 100 символов",
    "textTooLong": "Текст не должен превышать 63206 символов",
    "forbidden": "Вы можете публиковать посты только от своего имени",
    "generic": "Не удалось опубликовать пост. Попробуйте ещё раз."
  }
}
```

### 10) TESTS

`test/features/posts/create_post/`

**a) `domain/usecases/create_post_usecase_test.dart`:**
- `call` with `data.username != currentUser.username` → `Left(ForbiddenFailure)`, port not called
- `call` with `data.username == currentUser.username`, port returns `Right(null)` → `Right(null)`
- `call` with `data.username == currentUser.username`, port returns `Left(NetworkFailure)` → `Left(NetworkFailure)`
- `call` when `currentUser == null` → `Left(ForbiddenFailure)`, port not called

**b) `data/create_post_adapter_test.dart`:**
- success: api 201/200 → `Right(null)`
- DioException 403 → `Left(ForbiddenFailure)`
- DioException 401 → `Left(UnauthorizedFailure)`
- DioException 422 → `Left(ValidationFailure)`
- DioException network → `Left(NetworkFailure)`
- unexpected `Exception` (TypeError) → `Left(UnknownFailure)`, `logger.error` called with stackTrace

**c) `application/create_post_cubit_test.dart`:**
- `submit` success → emits `[CreatePostLoading, CreatePostSuccess]`
- `submit` failure → emits `[CreatePostLoading, CreatePostError(failure)]`

---

## Report

On completion, provide:
- List of created and modified files
- Confirmation that `user_posts` is updated (imports, mapper) and tests are green
- Confirmation that `list_posts` and other slices were not touched
- `dart run build_runner build --delete-conflicting-outputs` — no errors
- `dart run slang` — no errors
- `dart analyze` — no errors
- Tests: number of test cases, all green

---

## What Not to Do

- ❌ Touch `list_posts` — leave it as-is
- ❌ Store live preview state in Cubit — `TextEditingController` manages it in the widget
- ❌ Do field validation in Cubit — only in `Form` via `validator:`
- ❌ Show a dialog on error — only inline text below the form
- ❌ Navigate directly via `pushReplacement` — only `maybePop()`, then `refresh()`
- ❌ Import `UserPostsCubit` into Cubit or UseCase — only in presentation via `BlocListener`
- ❌ Add `flutter_markdown` without coordinating the version with `pubspec.yaml`
- ❌ Move `PaginatedPosts` or `PaginatedPostsDto` to `_shared/` — they are only used in `user_posts`
- ❌ Create a separate `CreatePostRequestDto` inside the slice — it goes in `_shared/data/dto/` since it is used by PostsApiClient
