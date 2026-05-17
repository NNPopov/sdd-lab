# 0021 · edit_post — Implementation Plan

## Title

Task: create a new `edit_post` slice (0021) in the `posts` feature.  
The post author sees an Edit button in the AppBar of the post details screen, taps it — lands
on a pre-filled edit form, saves — returns to the updated `PostDetailsScreen`.

---

## Context

```
READ:
- @CLAUDE.md in full
- @lib/features/posts/create_post/**               — closest form analogue
                                                     (DO NOT copy, use as reference)
- @lib/features/posts/post_details/presentation/post_details_screen.dart
                                                   — we will add the Edit button here
- @lib/features/posts/post_details/presentation/post_details_route.dart
- @lib/features/posts/post_details/application/post_details_cubit.dart
                                                   — we will call load() after success
- @lib/features/posts/_shared/data/posts_api_client.dart
                                                   — we will add patchPost
- @lib/features/posts/_shared/domain/entities/post.dart
                                                   — object for pre-filling the form
- @lib/core/auth/application/auth_cubit.dart       — currentUser for ownership check
- @lib/core/auth/application/auth_state.dart
- @lib/core/errors/failure.dart
- @lib/core/routing/app_router.dart                — we will add EditPostRoute
- @lib/core/i18n/i18n/en.json
- @lib/core/i18n/i18n/ru.json
- @.claude/skills/bloc/SKILL.md

DO NOT READ:
- @lib/features/posts/list_posts/**
- @lib/features/posts/user_posts/**
- @lib/features/users/**
- @lib/features/tiers/**
- @lib/features/auth/**
```

---

## API

```
PATCH http://127.0.0.1:8000/api/v1/{username}/post/{id}
Header: Authorization: Bearer <token>
Body: { "title": string, "text": string, "media_url": string | null }
Response 200: no body (or empty object)
```

Errors:
- `401` → `UnauthorizedFailure` (token invalid)
- `403` → `ForbiddenFailure` (attempt to edit another user's post)
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
│   │   │   └── update_post_request_dto.dart    # NEW: freezed DTO for the PATCH body
│   │   └── posts_api_client.dart               # MODIFY: add patchPost
│   └── presentation/
│       └── widgets/
│           └── markdown_preview.dart           # MOVE from create_post/presentation/widgets/
├── create_post/
│   └── presentation/
│       ├── create_post_screen.dart             # MODIFY: update MarkdownPreview import
│       └── widgets/
│           └── markdown_preview.dart           # DELETE (moved to _shared)
├── post_details/
│   └── presentation/
│       └── post_details_screen.dart            # MODIFY: StatefulWidget + Edit button
└── edit_post/                                  # NEW SLICE
    ├── domain/
    │   ├── entities/
    │   │   └── updated_post_data.dart          # value object: username, id, title, text, mediaUrl?
    │   ├── ports/
    │   │   └── edit_post_port.dart             # Future<Either<Failure, void>> call(UpdatedPostData)
    │   └── usecases/
    │       └── edit_post_usecase.dart          # ownership check + delegates to port
    ├── data/
    │   └── edit_post_adapter.dart              # implements EditPostPort, double catch
    ├── application/
    │   ├── edit_post_cubit.dart
    │   └── edit_post_state.dart                # sealed: initial, loading, success, error(Failure)
    └── presentation/
        ├── edit_post_route.dart                # @RoutePage(), Post parameter (not path param)
        └── edit_post_screen.dart               # StatefulWidget, pre-filled form

Modified existing files:
  lib/features/posts/_shared/data/posts_api_client.dart
  lib/features/posts/create_post/presentation/create_post_screen.dart   → update import
  lib/features/posts/create_post/presentation/widgets/markdown_preview.dart → DELETE
  lib/features/posts/post_details/presentation/post_details_screen.dart → StatefulWidget + Edit
  lib/core/routing/app_router.dart
  lib/core/i18n/i18n/en.json
  lib/core/i18n/i18n/ru.json
```

---

## What to Do

### 1) _SHARED — Moving MarkdownPreview

**IMPORTANT:** Move `MarkdownPreview` first, then create `edit_post`.
The move and import updates — in a single atomic change.

Create `lib/features/posts/_shared/presentation/widgets/markdown_preview.dart`
with the same content as `create_post/presentation/widgets/markdown_preview.dart`,
but update the localisation key reference: the widget accepts `label` as a parameter:

**SIMPLER:** pass `label` as a parameter:
```dart
class MarkdownPreview extends StatelessWidget {
  const MarkdownPreview({required this.text, required this.label, super.key});
  final String text;
  final String label;

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const Divider(),
        MarkdownBody(data: text),
      ],
    );
  }
}
```

Delete `lib/features/posts/create_post/presentation/widgets/markdown_preview.dart`.

Update the import in `create_post_screen.dart` to the new path from `_shared/`.
Update the `MarkdownPreview(...)` call: add the parameter
`label: context.t.posts.createPost.previewLabel`.

### 2) _SHARED — UpdatePostRequestDto + patchPost

**`lib/features/posts/_shared/data/dto/update_post_request_dto.dart`** (new):
```dart
@freezed
sealed class UpdatePostRequestDto with _$UpdatePostRequestDto {
  const factory UpdatePostRequestDto({
    required String title,
    required String text,
    @JsonKey(name: 'media_url') String? mediaUrl,
  }) = _UpdatePostRequestDto;

  factory UpdatePostRequestDto.fromJson(Map<String, dynamic> json) =>
      _$UpdatePostRequestDtoFromJson(json);
}
```

**`posts_api_client.dart`** — add method:
```dart
@PATCH('/{username}/post/{id}')
Future<void> patchPost(
  @Path('username') String username,
  @Path('id') int id,
  @Body() UpdatePostRequestDto body,
);
```

Add import for `update_post_request_dto.dart`.

### 3) DOMAIN

**`updated_post_data.dart`** — simple immutable plain Dart class, no freezed:
```dart
class UpdatedPostData {
  const UpdatedPostData({
    required this.username,
    required this.id,
    required this.title,
    required this.text,
    this.mediaUrl,
  });

  final String username;
  final int id;
  final String title;
  final String text;
  final String? mediaUrl;
}
```

**`edit_post_port.dart`** — narrow port, 1 method:
```dart
abstract class EditPostPort {
  Future<Either<Failure, void>> call(UpdatedPostData data);
}
```

**`edit_post_usecase.dart`** — ownership check + delegates to port:
```dart
class EditPostUseCase {
  EditPostUseCase(this._port, this._authCubit);

  final EditPostPort _port;
  final AuthCubit _authCubit;

  Future<Either<Failure, void>> call(UpdatedPostData data) async {
    final currentUser = _authCubit.currentUser;
    if (currentUser == null || currentUser.username != data.username) {
      return const Left(Failure.forbidden(message: 'Cannot edit another user\'s post'));
    }
    return _port(data);
  }
}
```

### 4) DATA

**`edit_post_adapter.dart`** — implements `EditPostPort`. Double catch per §8.4:

```dart
@LazySingleton(as: EditPostPort)
class EditPostAdapter implements EditPostPort {
  EditPostAdapter(this._api, this._logger);
  final PostsApiClient _api;
  final AppLogger _logger;

  @override
  Future<Either<Failure, void>> call(UpdatedPostData data) async {
    try {
      try {
        await _api.patchPost(
          data.username,
          data.id,
          UpdatePostRequestDto(
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
      _logger.error('EditPostAdapter.call failed unexpectedly', error: e, stackTrace: st);
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

**`edit_post_state.dart`** — sealed via freezed:
```dart
@freezed
sealed class EditPostState with _$EditPostState {
  const factory EditPostState.initial() = EditPostInitial;
  const factory EditPostState.loading() = EditPostLoading;
  const factory EditPostState.success() = EditPostSuccess;
  const factory EditPostState.error(Failure failure) = EditPostError;
}
```

**`edit_post_cubit.dart`**:
```dart
@injectable
class EditPostCubit extends Cubit<EditPostState> {
  EditPostCubit(this._useCase) : super(const EditPostState.initial());

  final EditPostUseCase _useCase;

  Future<void> submit(UpdatedPostData data) async {
    emit(const EditPostState.loading());
    final result = await _useCase(data);
    result.fold(
      (failure) => emit(EditPostState.error(failure)),
      (_) => emit(const EditPostState.success()),
    );
  }
}
```

### 6) PRESENTATION

**`edit_post_route.dart`** — we pass the `Post` object directly (not via path params):
```dart
@RoutePage()
class EditPostPage extends StatelessWidget {
  const EditPostPage({required this.post, required this.username, super.key});
  final Post post;
  final String username;
  ...
}
```
`EditPostScreen` also receives `username` and uses it for `UpdatedPostData`.

**`edit_post_screen.dart`** — `StatefulWidget`:
- Initialise `TextEditingController` with values from `post.title`, `post.text`,
  `post.mediaUrl ?? ''`
- Form structure identical to `CreatePostScreen`: title → mediaUrl → text → preview → button
- Live preview: `TextEditingController` for the text field → listener updates the preview
- `BlocConsumer`:
  - builder: on `EditPostLoading` — Save button disabled + `CircularProgressIndicator`;
    on `EditPostError` — error text above the button
  - listener: on `EditPostSuccess` → `context.router.maybePop()`
- Submit: `_formKey.currentState!.validate()` → `cubit.submit(UpdatedPostData(username: post.username, id: post.id, title: ..., text: ..., mediaUrl: ...))`

### 7) INTEGRATION — PostDetailsScreen

Convert `PostDetailsScreen` from `StatelessWidget` to `StatefulWidget`.
Do **not touch** the load initialisation (`cubit.load(username, id)`) — it
remains in `BlocProvider.create` in `PostDetailsPage`.

Add `actions` to `AppBar`:
```dart
actions: [
  BlocBuilder<PostDetailsCubit, PostDetailsState>(
    builder: (context, postState) {
      if (postState is! PostDetailsLoaded) return const SizedBox.shrink();
      return BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          final isAuthor = authState is AuthAuthenticated &&
              authState.currentUser?.username == widget.username;
          if (!isAuthor) return const SizedBox.shrink();
          return IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: context.t.posts.editPost.title,
            onPressed: () async {
              final cubit = context.read<PostDetailsCubit>();
              await context.router.push(
                EditPostRoute(post: postState.post, username: widget.username),
              );
              if (!mounted) return;
              unawaited(cubit.load(widget.username, widget.id));
            },
          );
        },
      );
    },
  ),
],
```

Add imports: `auth_cubit.dart`, `auth_state.dart`, `edit_post_route.dart`
(from `core/routing/app_router.dart` the generated `EditPostRoute`).

### 8) INTEGRATION — AppRouter

**`app_router.dart`** — add the route (with `authGuard`):
```dart
AutoRoute(
  page: EditPostRoute.page,
  path: '/user/:username/posts/:id/edit',
  guards: [authGuard],
),
```

Add import for `edit_post_route.dart`.

Run after all changes:
```
flutter pub get
dart run build_runner build --delete-conflicting-outputs
dart run slang
```

### 9) LOCALISATION

`en.json` — add to the `posts` section:
```json
"editPost": {
  "title": "Edit Post",
  "titleLabel": "Title",
  "titleHint": "Post title",
  "mediaUrlLabel": "Media URL (optional)",
  "mediaUrlHint": "https://...",
  "textLabel": "Text (Markdown)",
  "textHint": "Write your post...",
  "previewLabel": "Preview",
  "saveButton": "Save",
  "errors": {
    "titleTooShort": "Title must be at least 2 characters",
    "titleTooLong": "Title must be at most 30 characters",
    "mediaUrlEmpty": "Media URL cannot be empty if provided",
    "textTooShort": "Text must be at least 100 characters",
    "textTooLong": "Text must be at most 63206 characters",
    "forbidden": "You can only edit your own posts",
    "generic": "Failed to save post. Please try again."
  }
}
```

`ru.json`:
```json
"editPost": {
  "title": "Редактировать пост",
  "titleLabel": "Заголовок",
  "titleHint": "Заголовок поста",
  "mediaUrlLabel": "Ссылка на медиа (опционально)",
  "mediaUrlHint": "https://...",
  "textLabel": "Текст (Markdown)",
  "textHint": "Напишите пост...",
  "previewLabel": "Предпросмотр",
  "saveButton": "Сохранить",
  "errors": {
    "titleTooShort": "Заголовок должен содержать не менее 2 символов",
    "titleTooLong": "Заголовок не должен превышать 30 символов",
    "mediaUrlEmpty": "Ссылка на медиа не может быть пустой, если указана",
    "textTooShort": "Текст должен содержать не менее 100 символов",
    "textTooLong": "Текст не должен превышать 63206 символов",
    "forbidden": "Вы можете редактировать только свои посты",
    "generic": "Не удалось сохранить пост. Попробуйте ещё раз."
  }
}
```

### 10) TESTS

`test/features/posts/edit_post/`

**a) `domain/usecases/edit_post_usecase_test.dart`:**
- `call` with `currentUser == null` → `Left(ForbiddenFailure)`, port not called
- `call` with `data.username != currentUser.username` → `Left(ForbiddenFailure)`, port not called
- `call` with `data.username == currentUser.username`, port returns `Right(null)` → `Right(null)`
- `call` with `data.username == currentUser.username`, port returns `Left(NetworkFailure)` → `Left(NetworkFailure)`

**b) `data/edit_post_adapter_test.dart`:**
- success: api 200 → `Right(null)`
- DioException 401 → `Left(UnauthorizedFailure)`
- DioException 403 → `Left(ForbiddenFailure)`
- DioException 422 → `Left(ValidationFailure)`
- DioException connection error → `Left(NetworkFailure)`
- DioException 500 → `Left(ServerFailure)`
- unexpected `Exception` (TypeError) → `Left(UnknownFailure)`, `logger.error` called with stackTrace

**c) `application/edit_post_cubit_test.dart`:**
- `submit` success → emits `[EditPostLoading, EditPostSuccess]`
- `submit` failure → emits `[EditPostLoading, EditPostError(failure)]`

---

## Report

On completion, provide:
- List of created and modified files
- Confirmation that `MarkdownPreview` is moved to `_shared/` and the import in `create_post_screen.dart` is updated
- Confirmation that `PostDetailsScreen` is converted to StatefulWidget without regressions
- Confirmation that `list_posts`, `user_posts`, `create_post` (except the import) slices are not touched
- `dart run build_runner build --delete-conflicting-outputs` — no errors
- `dart run slang` — no errors
- `dart analyze` — no errors
- Tests: number of test cases, all green

---

## What Not to Do

- ❌ Touch `list_posts`, `user_posts` — they remain as-is
- ❌ Store live preview state in Cubit — `TextEditingController` manages it in the widget
- ❌ Do form validation in Cubit — only in `Form` via `validator:`
- ❌ Show a dialog on error — only inline text below the button
- ❌ Pass `username` to `EditPostRoute` via path params — it is passed as a named parameter together with `post`
- ❌ Move `PaginatedPosts` or `PaginatedPostsDto` to `_shared/` — they are only needed in `user_posts`
- ❌ Add the Edit button anywhere other than `PostDetailsScreen`
- ❌ Move the `cubit.load` initialisation from `PostDetailsPage.BlocProvider.create` to `initState` — the current approach stays
- ❌ Create the route without `authGuard` — editing is only for authenticated users
