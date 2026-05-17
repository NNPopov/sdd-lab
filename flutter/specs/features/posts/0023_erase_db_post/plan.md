# plan.md — `erase_db_post` slice

## Task

Create the `erase_db_post` slice inside `features/posts/`. A superuser can permanently
erase any post that does not belong to them directly from the Post Details screen.
Owners use the existing `delete_post` action for their own content. An `AlertDialog`
confirmation precedes the destructive call. On success the detail screen closes and
the post disappears from the in-memory posts list via `PostEventBus`.

---

## CONTEXT

### READ

- `@CLAUDE.md` — fully; hard rules govern every decision
- `@lib/features/posts/delete_post/**` — primary reference for state machine shape,
  event-bus wiring, and button/dialog pattern (DO NOT copy blindly — adapt)
- `@lib/features/users/erase_db_user/**` — primary reference for superuser dual-layer
  permission check and `isSuperuser` call-site parameter pattern
- `@lib/features/posts/_shared/data/posts_api_client.dart` — add method here
- `@lib/features/posts/_shared/application/post_event.dart` — reused as-is
- `@lib/features/posts/_shared/application/post_event_bus.dart` — reused as-is
- `@lib/features/posts/_shared/domain/entities/post.dart` — entity shape
- `@lib/features/posts/post_details/presentation/post_details_screen.dart` — modified
- `@lib/features/posts/post_details/presentation/post_details_route.dart` — modified
- `@lib/core/auth/application/auth_cubit.dart` — `currentUser?.isSuperuser`
- `@lib/core/auth/domain/entities/current_user.dart` — `isSuperuser: bool`
- `@lib/core/errors/failure.dart` — failure variants
- `@lib/core/i18n/i18n/en.json` — add keys
- `@lib/core/i18n/i18n/ru.json` — add keys
- `@.claude/skills/bloc/SKILL.md`

### DO NOT READ

- `@lib/features/posts/create_post/**`
- `@lib/features/posts/edit_post/**`
- `@lib/features/posts/user_posts/**`
- `@lib/features/posts/list_posts/**`
- `@lib/features/users/**` (except `erase_db_user/` already listed above)

---

## API

```
DELETE /{username}/db_post/{id}
Header: Authorization: Bearer <token>
Body: none
Response 2xx: no body

Errors:
  401 — token invalid / expired  →  Failure.unauthorized
  403 — caller is not a superuser  →  Failure.forbidden
  404 — post not found  →  Failure.notFound
  5xx — server error  →  Failure.server
  catch-all unexpected exception  →  Failure.unknown  (logger.error required)
```

**Note:** The server performs the superuser check independently. The use-case guard
is an extra client-side safety net, not a replacement.

**New method added to `PostsApiClient`:**

```dart
@DELETE('/{username}/db_post/{id}')
Future<void> eraseDbPost(
  @Path('username') String username,
  @Path('id') int id,
);
```

---

## Target file structure

```
lib/features/posts/erase_db_post/
├── domain/
│   ├── ports/
│   │   └── erase_db_post_port.dart        # Future<Either<Failure,Unit>> call(String username, int id)
│   └── usecases/
│       └── erase_db_post_usecase.dart     # isSuperuser guard → port
├── data/
│   └── erase_db_post_adapter.dart         # @LazySingleton(as: EraseDbPostPort)
├── application/
│   ├── erase_db_post_state.dart           # sealed freezed: initial/confirming/deleting/success/failure
│   └── erase_db_post_cubit.dart           # @injectable; injects EraseDbPostUseCase + AuthCubit
└── presentation/
    ├── erase_db_post_button.dart          # self-contained: owns BlocProvider + listener
    └── widgets/
        └── erase_db_post_confirmation_dialog.dart

Files modified (outside the slice):
  lib/features/posts/_shared/data/posts_api_client.dart    — add eraseDbPost method
  lib/features/posts/post_details/presentation/post_details_screen.dart — add erase button
  lib/features/posts/post_details/presentation/post_details_route.dart  — add EraseDbPostCubit provider
  lib/core/i18n/i18n/en.json   — add posts.eraseDbPost key group
  lib/core/i18n/i18n/ru.json   — add posts.eraseDbPost key group
```

---

## What to do

### Step 1 — `_shared`: add API endpoint

**File:** `lib/features/posts/_shared/data/posts_api_client.dart`

Append after the existing `deletePost` method:

```dart
@DELETE('/{username}/db_post/{id}')
Future<void> eraseDbPost(
  @Path('username') String username,
  @Path('id') int id,
);
```

Run `dart run build_runner build --delete-conflicting-outputs` after this step.

---

### Step 2 — DOMAIN: port + use-case

**`erase_db_post_port.dart`**

```dart
abstract interface class EraseDbPostPort {
  Future<Either<Failure, Unit>> call(String username, int id);
}
```

**`erase_db_post_usecase.dart`**

Mirror `EraseDbUserUseCase` exactly. The use-case receives `isSuperuser` as a
named call-site parameter (the cubit reads it from `AuthCubit.currentUser`):

```dart
@injectable
class EraseDbPostUseCase {
  EraseDbPostUseCase(this._port);
  final EraseDbPostPort _port;

  Future<Either<Failure, Unit>> call({
    required String username,
    required int id,
    required bool isSuperuser,
  }) async {
    if (!isSuperuser) return const Left(Failure.permissionDenied());
    return _port(username, id);
  }
}
```

---

### Step 3 — DATA: adapter

**`erase_db_post_adapter.dart`**

Mirror `DeletePostAdapter` and `EraseDbUserAdapter`. Double-catch pattern required.

```dart
@LazySingleton(as: EraseDbPostPort)
class EraseDbPostAdapter implements EraseDbPostPort {
  EraseDbPostAdapter(this._api, this._logger);
  final PostsApiClient _api;
  final AppLogger _logger;

  @override
  Future<Either<Failure, Unit>> call(String username, int id) async {
    try {
      try {
        await _api.eraseDbPost(username, id);
        return const Right(unit);
      } on DioException catch (e) {
        return switch (e.response?.statusCode) {
          401 => Left(Failure.unauthorized(message: _detail(e) ?? 'Unauthorized')),
          403 => Left(Failure.forbidden(message: _detail(e) ?? 'Forbidden')),
          404 => Left(Failure.notFound(message: _detail(e) ?? 'Post not found')),
          _ => Left(e.error is Failure ? e.error as Failure : Failure.network(message: e.message)),
        };
      }
    } on Object catch (e, st) {
      _logger.error('EraseDbPostAdapter.call failed', error: e, stackTrace: st);
      return const Left(Failure.unknown());
    }
  }

  String? _detail(DioException e) =>
      ((e.response?.data as Map<String, dynamic>?)?['detail'])?.toString();
}
```

---

### Step 4 — APPLICATION: state + cubit

**`erase_db_post_state.dart`**

Sealed freezed class mirroring `EraseDbUserState`:

```dart
@freezed
sealed class EraseDbPostState with _$EraseDbPostState {
  const factory EraseDbPostState.initial()               = EraseDbPostInitial;
  const factory EraseDbPostState.confirming()            = EraseDbPostConfirming;
  const factory EraseDbPostState.deleting()              = EraseDbPostDeleting;
  const factory EraseDbPostState.success()               = EraseDbPostSuccess;
  const factory EraseDbPostState.failure(Failure failure) = EraseDbPostFailure;
}
```

**`erase_db_post_cubit.dart`**

Mirror `DeletePostCubit` for the event-bus publish; mirror `EraseDbUserCubit`
for the `isSuperuser` read pattern. No `forceLogout` — erasing a post does NOT
blacklist the token.

```dart
@injectable
class EraseDbPostCubit extends Cubit<EraseDbPostState> {
  EraseDbPostCubit(this._eraseDbPost, this._authCubit, this._eventBus)
      : super(const EraseDbPostState.initial());

  final EraseDbPostUseCase _eraseDbPost;
  final AuthCubit _authCubit;
  final PostEventBus _eventBus;

  void requestConfirmation() => emit(const EraseDbPostState.confirming());

  void cancel() {
    if (state is EraseDbPostConfirming) {
      emit(const EraseDbPostState.initial());
    }
  }

  Future<void> confirmAndErase(String username, int id) async {
    emit(const EraseDbPostState.deleting());
    final result = await _eraseDbPost(
      username: username,
      id: id,
      isSuperuser: _authCubit.currentUser?.isSuperuser ?? false,
    );
    result.fold(
      (f) => emit(EraseDbPostState.failure(f)),
      (_) {
        _eventBus.publish(PostDeleted(id));
        emit(const EraseDbPostState.success());
      },
    );
  }
}
```

---

### Step 5 — PRESENTATION: dialog + button

**`erase_db_post_confirmation_dialog.dart`**

Mirror `EraseDbUserConfirmationDialog`. Returns `true` on confirm, `false`/null
on cancel. The dialog must clearly state that the action is irreversible.

```dart
class EraseDbPostConfirmationDialog extends StatelessWidget {
  const EraseDbPostConfirmationDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return AlertDialog(
      title: Text(t.posts.eraseDbPost.confirmTitle),
      content: Text(t.posts.eraseDbPost.confirmMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(t.posts.eraseDbPost.cancelButton),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(t.posts.eraseDbPost.confirmButton),
        ),
      ],
    );
  }
}
```

**`erase_db_post_button.dart`**

Self-contained widget. Owns a `BlocProvider` so it can be mounted anywhere.
Mirror `EraseDbUserButton` for structure; mirror `delete_post_button` for
navigation (pop, not replaceAll — erasing a post does not log out the user).

Key behaviours:
- `EraseDbPostConfirming` → show `EraseDbPostConfirmationDialog`; on `true`
  call `confirmAndErase(username, id)`; on cancel/null call `cancel()`.
- `EraseDbPostSuccess` → show snackbar (`t.posts.eraseDbPost.success`) → `router.pop()`.
- `EraseDbPostFailure` → show error snackbar; state stays at `failure` so the
  button becomes active again and the user can retry.
- While `EraseDbPostDeleting`: render `CircularProgressIndicator` and disable
  the button (set `onPressed: null`).
- Icon: `Icons.delete_forever` in `colorScheme.error` (same as `erase_db_user`).

```dart
class EraseDbPostButton extends StatelessWidget {
  const EraseDbPostButton({
    required this.username,
    required this.id,
    super.key,
  });

  final String username;
  final int id;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<EraseDbPostCubit>(),
      child: _EraseDbPostButtonInner(username: username, id: id),
    );
  }
}
```

The inner widget uses `BlocListener` + `BlocBuilder` (not `BlocConsumer`) so
that navigation side-effects are clearly separated from the rebuild path.

---

### Step 6 — INTEGRATION: wire into post details

**`post_details_route.dart`** — add `EraseDbPostCubit` to `MultiBlocProvider`:

```dart
MultiBlocProvider(
  providers: [
    BlocProvider(
      create: (_) {
        final cubit = getIt<PostDetailsCubit>();
        unawaited(cubit.load(username, id));
        return cubit;
      },
    ),
    BlocProvider(create: (_) => getIt<DeletePostCubit>()),
    BlocProvider(create: (_) => getIt<EraseDbPostCubit>()),   // ADD
  ],
  child: PostDetailsScreen(username: username, id: id),
)
```

**`post_details_screen.dart`** — restructure AppBar actions.

Currently the `BlocBuilder<AuthCubit>` checks `isAuthor` and shows an empty
widget for non-authors. Restructure to also check `isSuperuser`:

```dart
BlocBuilder<PostDetailsCubit, PostDetailsState>(
  builder: (context, postState) {
    if (postState is! PostDetailsLoaded) return const SizedBox.shrink();
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        final currentUser = authState is AuthAuthenticated
            ? authState.currentUser
            : null;
        final isAuthor = currentUser?.username == widget.username;
        final isSuperuser = currentUser?.isSuperuser ?? false;
        final showErase = isSuperuser && !isAuthor;

        if (!isAuthor && !showErase) return const SizedBox.shrink();

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isAuthor) ...[
              DeletePostButton(username: widget.username, id: widget.id),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: t.posts.editPost.title,
                onPressed: () async { /* existing logic unchanged */ },
              ),
            ],
            if (showErase)
              EraseDbPostButton(username: widget.username, id: widget.id),
          ],
        );
      },
    );
  },
),
```

**IMPORTANT:** `EraseDbPostButton` owns its own `BlocProvider` internally, so
it does NOT need to read `EraseDbPostCubit` from the tree above it. The cubit
provided in `post_details_route.dart` is provided for `BlocListener`-based side
effects (if any external listener is needed), but the button widget is
self-contained. Keep both — they don't conflict.

Actually — reconsider: since `EraseDbPostButton` creates its own `BlocProvider`
internally, the one added in `post_details_route.dart` is redundant. **Do NOT**
add `EraseDbPostCubit` to `post_details_route.dart`. The button widget is fully
self-contained (same pattern as `DeletePostButton` — check `delete_post_button.dart`
to confirm whether it also creates its own provider internally).

> **Check:** Read `delete_post_button.dart` — if it also contains its own
> `BlocProvider`, then `post_details_route.dart` should NOT get an extra provider
> for `EraseDbPostCubit`. Follow the same convention.

---

### Step 7 — LOCALISATION

**`lib/core/i18n/i18n/en.json`** — inside the `posts` object:

```json
"eraseDbPost": {
  "tooltip": "Erase post (superuser)",
  "confirmTitle": "Erase post?",
  "confirmMessage": "This post will be permanently erased. This action cannot be undone.",
  "confirmButton": "Erase",
  "cancelButton": "Cancel",
  "success": "Post erased",
  "errors": {
    "forbidden": "You do not have permission to erase posts",
    "generic": "Failed to erase post. Please try again."
  }
}
```

**`lib/core/i18n/i18n/ru.json`** — same structure, translated:

```json
"eraseDbPost": {
  "tooltip": "Удалить пост (суперпользователь)",
  "confirmTitle": "Удалить пост?",
  "confirmMessage": "Этот пост будет удалён безвозвратно. Действие нельзя отменить.",
  "confirmButton": "Удалить",
  "cancelButton": "Отмена",
  "success": "Пост удалён",
  "errors": {
    "forbidden": "Недостаточно прав для удаления поста",
    "generic": "Не удалось удалить пост. Попробуйте снова."
  }
}
```

Run `dart run build_runner build --delete-conflicting-outputs` to regenerate slang.

---

## Tests

```
test/features/posts/erase_db_post/
├── domain/usecases/erase_db_post_usecase_test.dart
├── data/erase_db_post_adapter_test.dart
├── application/erase_db_post_cubit_test.dart
└── presentation/erase_db_post_button_test.dart
```

**`erase_db_post_usecase_test.dart`**
- `isSuperuser: false` → `Left(PermissionDenied())`, port NOT called
- `isSuperuser: true`, port returns `Right(unit)` → `Right(unit)`
- `isSuperuser: true`, port returns `Left(Failure.notFound())` → `Left(NotFoundFailure)`

**`erase_db_post_adapter_test.dart`**
- API returns 2xx → `Right(unit)`
- DioException 401 → `Left(UnauthorizedFailure)`
- DioException 403 → `Left(ForbiddenFailure)`
- DioException 404 → `Left(NotFoundFailure)`
- DioException other (e.g. 500) → `Left(NetworkFailure)` or `Left(ServerFailure)`
- Unexpected `Exception` → `Left(UnknownFailure)`, `_logger.error` verified called

**`erase_db_post_cubit_test.dart`** (use `bloc_test`)
- `requestConfirmation()` → emits `[EraseDbPostConfirming]`
- `cancel()` from confirming → emits `[EraseDbPostInitial]`
- `cancel()` from initial → emits nothing
- `confirmAndErase(username, id)` when use-case returns `Right(unit)`:
  → emits `[EraseDbPostDeleting, EraseDbPostSuccess]`
  → `_eventBus.publish` called with `PostDeleted(id)`
- `confirmAndErase(username, id)` when use-case returns `Left(ForbiddenFailure)`:
  → emits `[EraseDbPostDeleting, EraseDbPostFailure]`
  → `_eventBus.publish` NOT called
- `confirmAndErase` when `isSuperuser: false`:
  → use-case returns `Left(PermissionDenied)` → emits `[EraseDbPostDeleting, EraseDbPostFailure]`

**`erase_db_post_button_test.dart`** (widget test, mocked cubit)
- Renders `delete_forever` icon when state is `initial`
- Does NOT render when `isSuperuser: false` (widget not mounted)
- Does NOT render when `isOwner` (widget not mounted)
- Tapping icon calls `requestConfirmation()`
- `EraseDbPostDeleting` state → spinner shown, button disabled
- `EraseDbPostSuccess` → snackbar shown, `router.pop()` called
- `EraseDbPostFailure` → error snackbar shown, icon is re-enabled
- `EraseDbPostConfirming` → dialog appears; tapping confirm calls
  `confirmAndErase(username, id)`; tapping cancel calls `cancel()`

Prior art for test patterns: `test/features/posts/delete_post/`,
`test/features/users/erase_db_user/`.

---

## Report (expected from the implementation agent)

On completion, provide:

1. List of all created files (with paths).
2. List of all modified files (with a one-line summary of what changed).
3. Confirmation that no other slice was touched.
4. UX walkthrough: superuser on a foreign post → erase button visible → dialog
   → confirm → snackbar → pop → post gone from list.
5. UX walkthrough: owner on their own post → erase button hidden, delete button visible.
6. UX walkthrough: non-superuser → erase button hidden.
7. Test count: new tests passing, zero failures.
8. Output of `dart analyze` — zero warnings.

---

## What NOT to do

- **Do NOT** add a navigation route for `erase_db_post` — this slice has no screen.
- **Do NOT** call `forceLogout` after erasing a post — the post owner's token is not
  blacklisted; only the user's own account deletion does that.
- **Do NOT** use `context.router.replaceAll` — use `context.router.pop()`. The user
  stays logged in and returns to the previous screen normally.
- **Do NOT** add `Permission.erasePosts` to the permission enum — visibility is
  controlled by `currentUser.isSuperuser`, not by the RBAC permission set.
- **Do NOT** modify `PostEventBus` or `PostEvent` — `PostDeleted` already covers
  this case.
- **Do NOT** modify `Post` entity — `createdByUserId` (int) is not needed for the
  erase button visibility; `widget.username` (the route param) serves as the
  author's username in `PostDetailsScreen`.
- **Do NOT** show the erase button when the current user is the post owner,
  even if they are a superuser — owners use `delete_post` for their own content.
- **Do NOT** duplicate the "not your own post" check in the use-case — that is a
  UI concern; the server enforces what it needs to on its end.
- **Do NOT** touch any slice outside `erase_db_post/`, `post_details/` (screen +
  route), `_shared/data/posts_api_client.dart`, and the two i18n JSON files.
