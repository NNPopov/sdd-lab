# Implementation Plan — `delete_post` slice (0022)

## Task

Implement the `delete_post` slice in `features/posts/`.  
A post author can permanently delete their own post from the Post Details screen.
The deleted post disappears from the `UserPostsCubit` in-memory list immediately,
without a network round-trip, via an event bus.

---

## Context

**READ:**
- `@CLAUDE.md` — project rules (always)
- `@lib/features/users/delete_user/**` — primary reference implementation;
  mirrors state machine shape, adapter double-catch, button/dialog pattern.
  Do **not** copy blindly — adapt to posts domain.
- `@lib/features/posts/_shared/data/posts_api_client.dart` — add `deletePost` here
- `@lib/features/posts/_shared/domain/entities/post.dart` — Post entity
- `@lib/features/posts/post_details/presentation/post_details_route.dart` — add `DeletePostCubit` to `MultiBlocProvider`
- `@lib/features/posts/post_details/presentation/post_details_screen.dart` — add `DeletePostButton` to AppBar
- `@lib/features/posts/user_posts/application/user_posts_cubit.dart` — subscribe to `PostEventBus`
- `@lib/features/posts/user_posts/application/user_posts_state.dart` — verify `UserPostsLoaded` shape
- `@lib/features/posts/edit_post/domain/usecases/edit_post_usecase.dart` — ownership-check pattern
- `@lib/features/posts/posts_feature_module.dart` — DI module for posts
- `@lib/core/auth/application/auth_cubit.dart` — inject for ownership check
- `@lib/core/errors/failure.dart` — Failure sealed class
- `@lib/core/routing/app_router.dart` — no new route needed, verify existing path
- `@lib/core/i18n/i18n/en.json` and `ru.json` — add `posts.deletePost` keys
- `@.claude/skills/bloc-state-management/` — Cubit + freezed state conventions

**DO NOT READ:**
- `lib/features/posts/create_post/**`
- `lib/features/posts/list_posts/**`
- `lib/features/users/list_users/**`
- `lib/features/users/edit_user/**`
- Any `*.freezed.dart` or `*.g.dart` generated files

---

## API

```
DELETE /api/v1/{username}/post/{id}
Authorization: Bearer <token>

Success: 204 No Content  (or 200, treat any 2xx as success)

Errors:
  401 — Unauthorized (token invalid or missing)
  403 — Forbidden (caller is not the post owner)
  404 — Post not found
  5xx — Server error
```

No request body. No response body to deserialize.

---

## Target File Structure

```
lib/features/posts/
├── _shared/
│   ├── data/
│   │   └── posts_api_client.dart        ← ADD deletePost method
│   └── application/
│       ├── post_event.dart              ← NEW: sealed PostEvent + PostDeleted(int id)
│       └── post_event_bus.dart          ← NEW: @lazySingleton PostEventBus
│
└── delete_post/
    ├── domain/
    │   ├── ports/
    │   │   └── delete_post_port.dart    ← Future<Either<Failure, Unit>> call(String username, int id)
    │   └── usecases/
    │       └── delete_post_usecase.dart ← ownership check + delegates to port
    ├── data/
    │   └── delete_post_adapter.dart     ← double-catch, AppLogger
    ├── application/
    │   ├── delete_post_cubit.dart
    │   └── delete_post_state.dart       ← sealed freezed: initial/confirming/deleting/success/failure
    └── presentation/
        ├── delete_post_button.dart      ← self-contained widget with BlocProvider
        └── widgets/
            └── delete_post_confirmation_dialog.dart

Modified files:
  lib/features/posts/_shared/data/posts_api_client.dart
  lib/features/posts/post_details/presentation/post_details_route.dart
  lib/features/posts/post_details/presentation/post_details_screen.dart
  lib/features/posts/user_posts/application/user_posts_cubit.dart
  lib/core/i18n/i18n/en.json
  lib/core/i18n/i18n/ru.json
```

---

## Step-by-Step Implementation

### 1) _shared: PostsApiClient — add deletePost

File: `lib/features/posts/_shared/data/posts_api_client.dart`

Add one method to the existing Retrofit interface:

```dart
@DELETE('/{username}/post/{id}')
Future<void> deletePost(
  @Path('username') String username,
  @Path('id') int id,
);
```

Run `build_runner` after adding to regenerate `posts_api_client.g.dart`.

---

### 2) _shared: PostEvent + PostEventBus

**IMPORTANT:** The event bus lives in `_shared/application/`, not in `core/`.
`core/` must not know about features.

`lib/features/posts/_shared/application/post_event.dart`:
```dart
sealed class PostEvent {}

final class PostDeleted extends PostEvent {
  PostDeleted(this.id);
  final int id;
}
```

`lib/features/posts/_shared/application/post_event_bus.dart`:
```dart
import 'dart:async';
import 'package:injectable/injectable.dart';
import 'post_event.dart';

@lazySingleton
class PostEventBus {
  final _controller = StreamController<PostEvent>.broadcast();
  Stream<PostEvent> get stream => _controller.stream;

  void publish(PostEvent event) => _controller.add(event);

  Future<void> dispose() => _controller.close();
}
```

Register in DI: add `PostEventBus` to `PostsFeatureModule`
(`lib/features/posts/posts_feature_module.dart`) as a `@lazySingleton` if
`injectable` doesn't pick it up automatically from the annotation. Since
`@lazySingleton` is on the class itself, it should be auto-registered —
verify after codegen.

---

### 3) DOMAIN — port

`lib/features/posts/delete_post/domain/ports/delete_post_port.dart`:
```dart
import 'package:dartz/dartz.dart';
import 'package:flutter_application_1/core/errors/failure.dart';

abstract interface class DeletePostPort {
  Future<Either<Failure, Unit>> call(String username, int id);
}
```

---

### 4) DOMAIN — use case

`lib/features/posts/delete_post/domain/usecases/delete_post_usecase.dart`

Mirror `EditPostUseCase` ownership pattern:

```dart
@injectable
class DeletePostUseCase {
  DeletePostUseCase(this._port, this._authCubit);

  final DeletePostPort _port;
  final AuthCubit _authCubit;

  Future<Either<Failure, Unit>> call(String username, int id) async {
    final currentUser = _authCubit.currentUser;
    if (currentUser == null || currentUser.username != username) {
      return const Left(Failure.forbidden(message: "Cannot delete another user's post"));
    }
    return _port(username, id);
  }
}
```

---

### 5) DATA — adapter

`lib/features/posts/delete_post/data/delete_post_adapter.dart`

Mirror `DeleteUserAdapter` double-catch pattern exactly:

```dart
@LazySingleton(as: DeletePostPort)
class DeletePostAdapter implements DeletePostPort {
  DeletePostAdapter(this._api, this._logger);

  final PostsApiClient _api;
  final AppLogger _logger;

  @override
  Future<Either<Failure, Unit>> call(String username, int id) async {
    try {
      try {
        await _api.deletePost(username, id);
        return const Right(unit);
      } on DioException catch (e) {
        switch (e.response?.statusCode) {
          case 401:
            return Left(Failure.unauthorized(message: _detail(e) ?? 'Unauthorized'));
          case 403:
            return Left(Failure.forbidden(message: _detail(e) ?? 'Forbidden'));
          case 404:
            return Left(Failure.notFound(message: _detail(e) ?? 'Post not found'));
          default:
            final f = e.error;
            if (f is Failure) return Left(f);
            return Left(Failure.network(message: e.message));
        }
      }
    } on Object catch (e, st) {
      _logger.error('DeletePostAdapter.call failed', error: e, stackTrace: st);
      return const Left(Failure.unknown());
    }
  }

  String? _detail(DioException e) =>
      ((e.response?.data as Map<String, dynamic>?)?['detail'])?.toString();
}
```

---

### 6) APPLICATION — state

`lib/features/posts/delete_post/application/delete_post_state.dart`

Sealed freezed class mirroring `DeleteUserState`:

```dart
@freezed
sealed class DeletePostState with _$DeletePostState {
  const factory DeletePostState.initial() = DeletePostInitial;
  const factory DeletePostState.confirming() = DeletePostConfirming;
  const factory DeletePostState.deleting() = DeletePostDeleting;
  const factory DeletePostState.success() = DeletePostSuccess;
  const factory DeletePostState.failure(Failure failure) = DeletePostFailure;
}
```

---

### 7) APPLICATION — cubit

`lib/features/posts/delete_post/application/delete_post_cubit.dart`

**Unlike `DeleteUserCubit`**, this cubit also publishes to `PostEventBus` on
success. It does NOT call `forceLogout` — that is specific to `delete_user`.

```dart
@injectable
class DeletePostCubit extends Cubit<DeletePostState> {
  DeletePostCubit(this._deletePost, this._eventBus)
      : super(const DeletePostState.initial());

  final DeletePostUseCase _deletePost;
  final PostEventBus _eventBus;

  void requestConfirmation() => emit(const DeletePostState.confirming());

  Future<void> confirmAndDelete(String username, int id) async {
    emit(const DeletePostState.deleting());
    final result = await _deletePost(username, id);
    result.fold(
      (f) => emit(DeletePostState.failure(f)),
      (_) {
        _eventBus.publish(PostDeleted(id));
        emit(const DeletePostState.success());
      },
    );
  }

  void cancel() {
    if (state is DeletePostConfirming) emit(const DeletePostState.initial());
  }
}
```

---

### 8) PRESENTATION — confirmation dialog

`lib/features/posts/delete_post/presentation/widgets/delete_post_confirmation_dialog.dart`

Mirror `delete_confirmation_dialog.dart` from `delete_user`. Show title and
irreversibility warning from `t.posts.deletePost`. Two actions: cancel and confirm
(destructive colour).

---

### 9) PRESENTATION — button widget

`lib/features/posts/delete_post/presentation/delete_post_button.dart`

Mirror `DeleteAccountButton` closely:

- `DeletePostButton({required String username, required int id})`
- Wraps its own `BlocProvider(create: (_) => getIt<DeletePostCubit>())`
- Inner `StatelessWidget` with `BlocListener`:
  - `DeletePostConfirming` → show dialog → `confirmAndDelete` or `cancel`
  - `DeletePostSuccess` → `ScaffoldMessenger.showSnackBar(success text)` → `router.pop()`
  - `DeletePostFailure` → `ScaffoldMessenger.showSnackBar(error text)` + reset to
    `initial` — the cubit already emits failure, **do not** call cancel
- `BlocBuilder`:
  - `isDeleting` → small `CircularProgressIndicator` (20×20, strokeWidth 2)
  - else → `Icon(Icons.delete_outline)` in `colorScheme.error`
  - `onPressed: null` when deleting

**IMPORTANT:** On success the screen pops with `router.pop()`, NOT `router.replaceAll`.
The user came from `UserPostsScreen` or a deep link; we just go back.

Failure message mapping:
```dart
String _failureMessage(Failure f, Translations t) => switch (f) {
  ForbiddenFailure() => t.posts.deletePost.errors.forbidden,
  UnauthorizedFailure() => t.posts.deletePost.errors.generic,
  NotFoundFailure() => t.posts.deletePost.errors.generic,
  _ => t.posts.deletePost.errors.generic,
};
```

---

### 10) INTEGRATION — PostDetailsPage (route)

`lib/features/posts/post_details/presentation/post_details_route.dart`

The route currently provides only `PostDetailsCubit`. Wrap with `MultiBlocProvider`:

```dart
MultiBlocProvider(
  providers: [
    BlocProvider(create: (_) {
      final cubit = getIt<PostDetailsCubit>();
      unawaited(cubit.load(username, id));
      return cubit;
    }),
    BlocProvider(create: (_) => getIt<DeletePostCubit>()),
  ],
  child: PostDetailsScreen(username: username, id: id),
)
```

---

### 11) INTEGRATION — PostDetailsScreen

`lib/features/posts/post_details/presentation/post_details_screen.dart`

The AppBar actions currently show the edit button when `isAuthor`. Add the delete
button alongside it, using the same `isAuthor` guard. Both buttons come from
`BlocBuilder<PostDetailsCubit>` + `BlocBuilder<AuthCubit>`:

```dart
if (isAuthor) DeletePostButton(username: widget.username, id: widget.id),
if (isAuthor) IconButton(/* existing edit button */),
```

Order: delete icon leftmost (destructive, secondary), edit icon rightmost (primary
action). Mirror the pattern from `UserDetailsScreen`.

---

### 12) INTEGRATION — UserPostsCubit subscribes to PostEventBus

`lib/features/posts/user_posts/application/user_posts_cubit.dart`

Add `PostEventBus` to the constructor and subscribe in a `StreamSubscription`:

```dart
@injectable
class UserPostsCubit extends Cubit<UserPostsState> {
  UserPostsCubit(this._useCase, this._eventBus) : super(const UserPostsState.initial()) {
    _sub = _eventBus.stream.listen(_onPostEvent);
  }

  final UserPostsUseCase _useCase;
  final PostEventBus _eventBus;
  late final StreamSubscription<PostEvent> _sub;

  void _onPostEvent(PostEvent event) {
    if (event is PostDeleted) {
      final current = state;
      if (current is UserPostsLoaded) {
        emit(current.copyWith(
          posts: current.posts.where((p) => p.id != event.id).toList(),
        ));
      }
    }
  }

  @override
  Future<void> close() {
    _sub.cancel();
    return super.close();
  }

  // ... existing load/refresh/loadMore unchanged
}
```

---

### 13) LOCALISATION

Add `posts.deletePost` key group to both `en.json` and `ru.json`:

```json
"deletePost": {
  "tooltip": "Delete post",
  "confirmTitle": "Delete post?",
  "confirmMessage": "This action is irreversible. The post will be permanently removed.",
  "confirmButton": "Delete",
  "cancelButton": "Cancel",
  "success": "Post deleted",
  "errors": {
    "forbidden": "You can only delete your own posts",
    "generic": "Failed to delete post. Please try again."
  }
}
```

After editing both JSON files, run slang codegen:
```
dart run build_runner build --delete-conflicting-outputs
```

---

## Tests

`test/features/posts/delete_post/`

### a) `application/delete_post_cubit_test.dart`

Use `bloc_test`. Mock `DeletePostUseCase` and `PostEventBus`.

| Scenario | Expected emissions |
|---|---|
| `requestConfirmation()` | `[confirming]` |
| `cancel()` from confirming | `[initial]` |
| `cancel()` from initial | `[]` (no-op) |
| `confirmAndDelete` → usecase returns `Right(unit)` | `[deleting, success]`; verify `_eventBus.publish(PostDeleted(id))` called |
| `confirmAndDelete` → usecase returns `Left(forbidden)` | `[deleting, failure(ForbiddenFailure)]` |
| `confirmAndDelete` → usecase returns `Left(unknown)` | `[deleting, failure(UnknownFailure)]` |

### b) `data/delete_post_adapter_test.dart`

Mock `PostsApiClient` and `AppLogger`.

| Scenario | Expected result |
|---|---|
| API returns success | `Right(unit)` |
| `DioException` with 401 | `Left(UnauthorizedFailure)` |
| `DioException` with 403 | `Left(ForbiddenFailure)` |
| `DioException` with 404 | `Left(NotFoundFailure)` |
| `DioException` with 500 | `Left(NetworkFailure)` |
| Unexpected `Exception` | `Left(UnknownFailure)`; verify `logger.error` called once |

### c) `domain/usecases/delete_post_usecase_test.dart`

Mock `DeletePostPort` and `AuthCubit`.

| Scenario | Expected result |
|---|---|
| `currentUser == null` | `Left(ForbiddenFailure)` without calling port |
| `currentUser.username != username` | `Left(ForbiddenFailure)` without calling port |
| `currentUser.username == username` | delegates to port, returns its result |

### d) `user_posts_cubit` integration — add to existing `user_posts_cubit_test.dart`

| Scenario | Expected state |
|---|---|
| `PostDeleted(id)` emitted when state is `UserPostsLoaded` | post with matching id removed from list |
| `PostDeleted(id)` when id not in list | list unchanged (no-op) |
| `PostDeleted(id)` when state is not `UserPostsLoaded` | no emission |

---

## Report

When done, provide:

1. Complete list of new files created and existing files modified.
2. Confirmation that no slice outside `delete_post/` and `_shared/` was touched
   (except `post_details_route`, `post_details_screen`, `user_posts_cubit`).
3. Confirmation that `core/` was not modified.
4. UX walkthrough: author taps delete → dialog appears → confirms → loading
   indicator → success snackbar → `router.pop()` → `UserPostsScreen` shows list
   without the deleted post.
5. Test results: number of new tests, all passing.

---

## What NOT To Do

- **DO NOT** create a `delete_post_route.dart` — this slice has no dedicated screen.
- **DO NOT** use `router.replaceAll` on success — just `router.pop()`.
- **DO NOT** call `forceLogout` — that is only for `delete_user` (token blacklist).
- **DO NOT** put `PostEventBus` or `PostEvent` in `core/` — core cannot know features.
- **DO NOT** place ownership check only in the UI; the use-case must also enforce it.
- **DO NOT** show the delete button to non-authors — check `authCubit.currentUser?.username == widget.username`.
- **DO NOT** add `500` as an explicit case in the adapter `switch` — fall through to the `default` branch which handles all non-2xx/4xx codes.
- **DO NOT** modify `PostsApiClient` to return a body — the endpoint returns no body; keep it `Future<void>`.
