# Plan: moderate_post (0035)

## Goal

Create the `moderate_post` slice inside `features/posts`. A moderator opens a post from
the pending queue, reads its content and moderation history, types an optional message,
and presses Approve or Request Changes. On success the post is removed from the queue and
the screen returns to the pending list.

---

## Prior art and reading list

| Read | Reason |
|---|---|
| `lib/features/posts/pending_posts/**` | Direct predecessor; adapter/cubit/state patterns |
| `lib/features/posts/_shared/domain/entities/` | All shared entities used here |
| `lib/features/posts/_shared/data/posts_api_client.dart` | To be extended with 2 new methods |
| `lib/features/posts/_shared/application/post_event.dart` | `PostModeratedEvent` already declared here |
| `lib/core/errors/failure.dart` | All failure types (ConflictFailure, ForbiddenFailure, etc.) |
| `lib/core/routing/app_router.dart` | Pending tab route subtree; where to add the new child |
| `lib/core/routing/tabs/pending_tab_route.dart` | Parent route page |
| `lib/core/theme/app_breakpoints.dart` | `AppBreakpoints.medium = 600` |
| `agent_docs/error_handling.md` | Double-catch adapter pattern |
| `agent_docs/navigation.md` | auto_route extras, guards |
| `agent_docs/localization.md` | slang key conventions |

Do **not** read other post slices (list_posts, create_post, edit_post, etc.) —
they are unrelated to moderation.

---

## New files

```
lib/features/posts/moderate_post/
├── domain/
│   ├── ports/
│   │   ├── i_moderate_post_port.dart       # single method: moderate(...)
│   │   └── i_moderation_log_port.dart      # single method: getModerationLog(...)
│   └── usecases/
│       └── moderate_post_usecase.dart      # validates message, delegates to IModeratePostPort
├── data/
│   ├── dto/
│   │   ├── moderate_post_request_dto.dart  # action + message?
│   │   ├── moderate_post_request_dto.freezed.dart
│   │   ├── moderate_post_request_dto.g.dart
│   │   ├── moderate_post_result_dto.dart   # postUuid + status string
│   │   ├── moderate_post_result_dto.freezed.dart
│   │   ├── moderate_post_result_dto.g.dart
│   │   ├── moderation_log_response_dto.dart  # wrapper: items: List<ModerationLogEntryDto>
│   │   ├── moderation_log_response_dto.freezed.dart
│   │   └── moderation_log_response_dto.g.dart
│   ├── moderate_post_adapter.dart          # implements IModeratePostPort
│   └── moderation_log_adapter.dart         # implements IModerationLogPort
├── application/
│   ├── moderate_post_cubit.dart            # approve/request-changes flow
│   ├── moderate_post_state.dart            # sealed: initial/loading/success/error
│   ├── moderate_post_state.freezed.dart
│   ├── moderation_log_cubit.dart           # lazy log loading
│   ├── moderation_log_state.dart           # sealed: initial/loading/loaded/error
│   └── moderation_log_state.freezed.dart
└── presentation/
    ├── moderate_post_route.dart            # @RoutePage(), provides both cubits
    ├── moderate_post_screen.dart           # StatefulWidget, adaptive layout
    └── widgets/
        ├── post_content_view.dart          # read-only PendingPostItem display
        ├── moderation_panel.dart           # log list + message field + action buttons
        └── moderation_log_list_view.dart   # scrollable list of ModerationLogEntry
```

**New DTOs also needed in `_shared/data/dto/`** — `ModerationLogEntryDto` (the item
inside the log response). Check if it already exists from slice C before creating it.
If it does, reuse it; if not, create:
```
lib/features/posts/_shared/data/dto/moderation_log_entry_dto.dart  (may already exist)
```

---

## Files to modify

| File | Change |
|---|---|
| `lib/features/posts/_shared/data/posts_api_client.dart` | Add `moderatePost` and `getModerationLog` methods |
| `lib/core/routing/app_router.dart` | Add `ModeratePostRoute` as child of `PendingTabRoute` |
| `lib/features/posts/pending_posts/presentation/pending_posts_screen.dart` | Wire `onTap` to `ModeratePostRoute` (replaces the `TODO(0035)`) |
| `lib/core/i18n/i18n/en.json` | Add `posts.moderatePost.*` keys |
| `lib/core/i18n/i18n/ru.json` | Add same keys in Russian |

---

## Implementation steps

### Step 1 — `_shared/data/posts_api_client.dart`: add two methods

```dart
@POST('/posts/{post_uuid}/moderate')
Future<ModeratePostResultDto> moderatePost(
  @Path('post_uuid') String postUuid,
  @Body() ModeratePostRequestDto body,
);

@GET('/posts/{post_uuid}/moderation-log')
Future<ModerationLogResponseDto> getModerationLog(
  @Path('post_uuid') String postUuid,
);
```

Run `build_runner` after adding to regenerate `posts_api_client.g.dart`.

### Step 2 — DTOs

**`ModeratePostRequestDto`** (`moderate_post/data/dto/`):
```dart
@freezed
sealed class ModeratePostRequestDto with _$ModeratePostRequestDto {
  const factory ModeratePostRequestDto({
    required String action,
    String? message,
  }) = _ModeratePostRequestDto;

  factory ModeratePostRequestDto.fromJson(Map<String, dynamic> json) =>
      _$ModeratePostRequestDtoFromJson(json);
}
```

**`ModeratePostResultDto`**:
```dart
@freezed
sealed class ModeratePostResultDto with _$ModeratePostResultDto {
  const factory ModeratePostResultDto({
    required String postUuid,
    required String status,
  }) = _ModeratePostResultDto;

  factory ModeratePostResultDto.fromJson(Map<String, dynamic> json) =>
      _$ModeratePostResultDtoFromJson(json);
}
```

**`ModerationLogEntryDto`** (may already exist in `_shared/data/dto/` from slice C —
verify before creating):
```dart
@freezed
sealed class ModerationLogEntryDto with _$ModerationLogEntryDto {
  const factory ModerationLogEntryDto({
    required int id,
    required String eventType,
    String? action,
    String? message,
    required DateTime createdAt,
    required int actorUserId,
    required String actorUsername,
  }) = _ModerationLogEntryDto;

  factory ModerationLogEntryDto.fromJson(Map<String, dynamic> json) =>
      _$ModerationLogEntryDtoFromJson(json);
}
```

**`ModerationLogResponseDto`** (`moderate_post/data/dto/`):
```dart
@freezed
sealed class ModerationLogResponseDto with _$ModerationLogResponseDto {
  const factory ModerationLogResponseDto({
    required List<ModerationLogEntryDto> items,
  }) = _ModerationLogResponseDto;

  factory ModerationLogResponseDto.fromJson(Map<String, dynamic> json) =>
      _$ModerationLogResponseDtoFromJson(json);
}
```

### Step 3 — Domain ports

**`IModeratePostPort`**:
```dart
abstract class IModeratePostPort {
  Future<Either<Failure, PostStatus>> call({
    required String postUuid,
    required String action,
    String? message,
  });
}
```

**`IModerationLogPort`**:
```dart
abstract class IModerationLogPort {
  Future<Either<Failure, List<ModerationLogEntry>>> call(String postUuid);
}
```

### Step 4 — Use-case: `ModeratePostUseCase`

```dart
@injectable
class ModeratePostUseCase {
  ModeratePostUseCase(this._port);
  final IModeratePostPort _port;

  Future<Either<Failure, PostStatus>> call({
    required String postUuid,
    required String action,
    String? message,
  }) {
    if (action == 'changes_requested' &&
        (message == null || message.trim().isEmpty)) {
      return Future.value(
        Left(Failure.validation(fieldErrors: {'message': 'required'})),
      );
    }
    return _port(postUuid: postUuid, action: action, message: message);
  }
}
```

The validation guard fires before any network call — no adapter is invoked.

### Step 5 — Adapters (use double-catch pattern from `agent_docs/error_handling.md`)

**`ModeratePostAdapter implements IModeratePostPort`**:

- Happy path: call `_api.moderatePost(postUuid, body)` → parse `dto.status` via
  `_parseStatus()` (same logic as `PendingPostsAdapter`) → `Right(status)`.
- HTTP errors: 403 → `ForbiddenFailure`, 404 → `NotFoundFailure`,
  409 → `ConflictFailure(message: 'Post already moderated')`, others → `ServerFailure`.
- Outer catch: log with `AppLogger.error` → `Left(Failure.unknown())`.

**`ModerationLogAdapter implements IModerationLogPort`**:

- Happy path: call `_api.getModerationLog(postUuid)` → map each `ModerationLogEntryDto`
  to `ModerationLogEntry` using the same parse helpers as `PendingPostsAdapter`.
- HTTP errors: 401 → `UnauthorizedFailure`, 403 → `ForbiddenFailure`,
  404 → `NotFoundFailure`.
- Outer catch: log → `Left(Failure.unknown())`.

Register both with `@LazySingleton(as: IModeratePostPort)` /
`@LazySingleton(as: IModerationLogPort)`.

### Step 6 — `ModeratePostState` (freezed, sealed)

```dart
@freezed
sealed class ModeratePostState with _$ModeratePostState {
  const factory ModeratePostState.initial() = ModeratePostInitial;
  const factory ModeratePostState.loading() = ModeratePostLoading;
  const factory ModeratePostState.success(PostStatus newStatus) = ModeratePostSuccess;
  const factory ModeratePostState.error(Failure failure) = ModeratePostError;
}
```

### Step 7 — `ModeratePostCubit`

```dart
@injectable
class ModeratePostCubit extends Cubit<ModeratePostState> {
  ModeratePostCubit(this._useCase, this._eventBus)
      : super(const ModeratePostState.initial());

  final ModeratePostUseCase _useCase;
  final PostEventBus _eventBus;

  Future<void> moderate({
    required String postUuid,
    required String action,
    String? message,
  }) async {
    emit(const ModeratePostState.loading());
    final result = await _useCase(postUuid: postUuid, action: action, message: message);
    result.fold(
      (f) => emit(ModeratePostState.error(f)),
      (status) {
        _eventBus.add(PostModeratedEvent(postUuid));
        emit(ModeratePostState.success(status));
      },
    );
  }
}
```

IMPORTANT: The event bus emission happens inside the cubit, before emitting `success`.
The screen only listens to `success` and calls `context.router.pop()` — it does NOT
touch the event bus directly.

### Step 8 — `ModerationLogState` (freezed, sealed)

```dart
@freezed
sealed class ModerationLogState with _$ModerationLogState {
  const factory ModerationLogState.initial() = ModerationLogInitial;
  const factory ModerationLogState.loading() = ModerationLogLoading;
  const factory ModerationLogState.loaded(List<ModerationLogEntry> entries) =
      ModerationLogLoaded;
  const factory ModerationLogState.error(Failure failure) = ModerationLogError;
}
```

### Step 9 — `ModerationLogCubit`

```dart
@injectable
class ModerationLogCubit extends Cubit<ModerationLogState> {
  ModerationLogCubit(this._port) : super(const ModerationLogState.initial());

  final IModerationLogPort _port;
  bool _loaded = false;

  Future<void> load(String postUuid) async {
    if (_loaded) return;   // idempotent: call multiple times safely
    _loaded = true;
    emit(const ModerationLogState.loading());
    final result = await _port(postUuid);
    result.fold(
      (f) {
        _loaded = false;   // allow retry on error
        emit(ModerationLogState.error(f));
      },
      (entries) => emit(ModerationLogState.loaded(entries)),
    );
  }
}
```

Empty list (`entries.isEmpty`) → emit `loaded([])`, not error. The UI renders an
empty-state message.

### Step 10 — Route: `ModeratePostRoute`

```dart
@RoutePage()
class ModeratePostPage extends StatelessWidget {
  const ModeratePostPage({
    @PathParam('post_uuid') required this.postUuid,
    super.key,
  });

  final String postUuid;

  @override
  Widget build(BuildContext context) {
    final item = context.routeData.extra<PendingPostItem>()!;
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<ModeratePostCubit>()),
        BlocProvider(create: (_) => getIt<ModerationLogCubit>()),
      ],
      child: ModeratePostScreen(postUuid: postUuid, post: item),
    );
  }
}
```

### Step 11 — Screen: `ModeratePostScreen`

`StatefulWidget`. Uses `LayoutBuilder` to check against `AppBreakpoints.medium`.

**Wide layout (≥ 600 dp):**
- `Row` → two `Expanded(flex: 1)` children separated by `VerticalDivider`.
- Left pane: `PostContentView(post: widget.post)`.
- Right pane: `ModerationPanel(postUuid: widget.postUuid)`.
- In `initState`: `context.read<ModerationLogCubit>().load(widget.postUuid)`.

**Narrow layout (< 600 dp):**
- `DefaultTabController(length: 2)` with tabs "Post" / "Moderation".
- `TabBarView` children: `PostContentView` + `ModerationPanel`.
- `ModerationLogCubit.load()` called the **first time** the Moderation tab becomes
  active. Use a `TabController` listener that checks `index == 1` and the cubit state
  is `initial`.

**`BlocListener<ModeratePostCubit, ModeratePostState>`** (wraps the layout):
- `success` → `context.router.pop()`.
- `error` → show `SnackBar` with localized error message.

Both action buttons in `ModerationPanel` are disabled while `ModeratePostCubit` is in
`loading` state (use `BlocBuilder` scoped to `ModeratePostCubit`).

### Step 12 — Widget: `PostContentView`

Stateless. Displays `PendingPostItem`:
- Title (`Text`, headline style).
- Optional media: `Image.network(mediaUrl)` if `post.mediaUrl != null`.
- Body text (`Text`, scrollable).

No edit/delete actions.

### Step 13 — Widget: `ModerationPanel`

Column, top to bottom:
1. `Expanded` → `ModerationLogListView` (scrollable).
2. `Divider`.
3. `TextField` for message (multiline; hint text clarifies it is required for rejection).
4. `Row` → "Approve" (`FilledButton`) + "Request Changes" (`OutlinedButton`).
   - Both disabled when `ModeratePostCubit` is loading.
   - "Request Changes" calls `moderate(action: 'changes_requested', message: _controller.text)`.
   - "Approve" calls `moderate(action: 'approved', message: _controller.text.isEmpty ? null : _controller.text)`.

### Step 14 — Widget: `ModerationLogListView`

`BlocBuilder<ModerationLogCubit, ModerationLogState>`:
- `initial` / `loading` → `CircularProgressIndicator`.
- `loaded([])` → centred empty-state text (`t.posts.moderatePost.log.empty`).
- `loaded(entries)` → `ListView` of `ModerationLogEntry` tiles (icon, username,
  timestamp, optional action chip, message).
- `error` → centred error text.

### Step 15 — Router: add child route

In `app_router.dart`, inside the `PendingTabRoute` children list, add:

```dart
AutoRoute(
  page: ModeratePostRoute.page,
  path: ':post_uuid/moderate',
  guards: [
    authGuard,
    PermissionGuard({Permission.moderatePosts}, permissionCubit),
  ],
),
```

Also add the import for `moderate_post_route.dart`.

### Step 16 — Wire `onTap` in `pending_posts_screen.dart`

Replace the empty `onTap: () {}` in `PendingPostTile` with:

```dart
onTap: () => context.router.push(
  ModeratePostRoute(
    postUuid: items[index].postUuid,
    extra: items[index],
  ),
),
```

### Step 17 — Localisation keys

Add under `posts.moderatePost` in `en.json`:

```json
"moderatePost": {
  "title": "Moderate Post",
  "tabs": {
    "post": "Post",
    "moderation": "Moderation"
  },
  "log": {
    "empty": "No moderation history yet",
    "loadError": "Failed to load moderation history",
    "eventTypes": {
      "moderatorReview": "Moderator Review",
      "authorRevision": "Author Revision"
    },
    "actions": {
      "approved": "Approved",
      "changesRequested": "Changes Requested"
    }
  },
  "actions": {
    "approve": "Approve",
    "requestChanges": "Request Changes",
    "messageHint": "Add a comment (required for rejection)",
    "messageRequiredError": "A message is required when requesting changes"
  },
  "errors": {
    "forbidden": "You do not have permission to moderate this post",
    "notFound": "Post not found",
    "conflict": "This post has already been moderated. Return to the queue.",
    "generic": "Failed to submit. Please try again."
  }
}
```

Mirror all keys in `ru.json`.

### Step 18 — Regenerate code

```
dart run build_runner build --delete-conflicting-outputs
dart run slang
dart format .
dart analyze
```

---

## Tests

### `test/features/posts/0035_moderate_post/data/moderate_post_adapter_test.dart`

- 200 → `Right(PostStatus.approved)` when dto.status = "approved".
- 200 → `Right(PostStatus.changesRequested)` when dto.status = "changes_requested".
- 403 → `Left(ForbiddenFailure)`.
- 404 → `Left(NotFoundFailure)`.
- 409 → `Left(ConflictFailure)`.
- Unexpected exception → `Left(UnknownFailure)`, `logger.error` called once.

### `test/features/posts/0035_moderate_post/data/moderation_log_adapter_test.dart`

- 200 with 2 entries → `Right([ModerationLogEntry, ModerationLogEntry])`, all fields
  correctly mapped (both event types; null and non-null action/message).
- 200 with empty list → `Right([])`.
- 401 → `Left(UnauthorizedFailure)`.
- 403 → `Left(ForbiddenFailure)`.
- 404 → `Left(NotFoundFailure)`.
- Unexpected exception → `Left(UnknownFailure)`, logger called.

### `test/features/posts/0035_moderate_post/domain/moderate_post_usecase_test.dart`

- `action == 'changes_requested'`, empty message → `Left(ValidationFailure)`, port
  **not** called.
- `action == 'changes_requested'`, null message → same.
- `action == 'approved'`, null message → port called → returns `Right(PostStatus)`.
- Port returns `Left(failure)` → use-case propagates it unchanged.

### `test/features/posts/0035_moderate_post/application/moderate_post_cubit_test.dart`

- `moderate(approved)` success → emits `[loading, success(PostStatus.approved)]`,
  `PostEventBus.add` called with `PostModeratedEvent`.
- `moderate(approved)` port failure → emits `[loading, error(failure)]`.
- `moderate(changes_requested)` + empty message → emits `[loading, error(ValidationFailure)]`.

### `test/features/posts/0035_moderate_post/application/moderation_log_cubit_test.dart`

- `load()` success with entries → emits `[loading, loaded(entries)]`.
- `load()` with empty list → emits `[loading, loaded([])]`.
- `load()` port failure → emits `[loading, error(failure)]`, second `load()` retries.
- `load()` called twice → second call is a no-op (only one `loading` emitted).

### `test/features/posts/0035_moderate_post/presentation/moderate_post_screen_wide_test.dart`

Mock both cubits. Set `MediaQuery.size.width = 800`.
- Both panes rendered (find `PostContentView`, find `ModerationPanel`).
- Approve and Request Changes buttons present and enabled (log cubit in `loaded`).
- Buttons disabled when `ModeratePostCubit` is `loading`.
- `ModerationLogCubit.load()` triggered in `initState` (use `verify` on mock).

### `test/features/posts/0035_moderate_post/presentation/moderate_post_screen_narrow_test.dart`

Mock both cubits. Set `MediaQuery.size.width = 400`.
- Initially only "Post" tab content visible.
- After tapping "Moderation" tab: `ModerationPanel` visible.
- `ModerationLogCubit.load()` called only once (not on every tab switch).

---

## What NOT to do

- **Do NOT** create a `PostStatusDto` — the raw status string is parsed inline in each
  adapter using the same `_parseStatus()` helper already in `PendingPostsAdapter`.
- **Do NOT** emit `PostModeratedEvent` from the screen or widget layer — only
  `ModeratePostCubit` emits it.
- **Do NOT** call `context.router.pop()` inside the cubit — navigation is a side effect
  handled in the screen's `BlocListener`.
- **Do NOT** load the moderation log eagerly on narrow layout — it must wait for the
  first tab switch.
- **Do NOT** show a validation error SnackBar for the missing-message case before the
  user taps the button — only on button press.
- **Do NOT** add a `_shared/domain/ports/` interface — ports belong inside the slice
  (`moderate_post/domain/ports/`), not in `_shared/`.
- **Do NOT** touch any other slice's files except `pending_posts_screen.dart` (onTap
  wiring) and `_shared/data/posts_api_client.dart` (two new methods).
- **Do NOT** add a fat `ModerationRepository` — use narrow `IModeratePostPort` and
  `IModerationLogPort` as two separate ports.
