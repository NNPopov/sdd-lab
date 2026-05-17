# Plan: revise_post (0036)

## Task

Extend the existing `edit_post` slice so it becomes moderation-aware.
When a post is in `changes_requested` status, the edit screen routes the save
action to `PATCH /posts/{post_uuid}/revise`, shows a required revision-message
field, and displays the moderation log alongside the editor. For all other
statuses the existing flow is unchanged.

---

## READ

- `CLAUDE.md` — fully
- `specs/features/posts/0036_revise_post/prd.md` — this spec
- `lib/features/posts/edit_post/**` — the slice being extended (primary)
- `lib/features/posts/_shared/**` — shared entities, event bus, API client
- `lib/features/posts/moderate_post/**` — reference for adaptive layout and
  moderation log infrastructure (do NOT copy state management logic)
- `lib/features/posts/pending_posts/application/pending_posts_cubit.dart` —
  event bus subscription pattern
- `lib/core/errors/failure.dart`
- `lib/core/theme/app_breakpoints.dart`
- `lib/core/routing/app_router.dart`
- `agent_docs/error_handling.md` — double-catch adapter pattern
- `agent_docs/testing.md`

## DO NOT READ

- `lib/features/posts/list_posts/**`
- `lib/features/posts/create_post/**`
- `lib/features/posts/delete_post/**`
- `lib/features/posts/post_details/**`
- `lib/features/posts/user_posts/**`
- `lib/features/users/**`
- `lib/features/tiers/**`

---

## API

### Revise post

```
PATCH /posts/{post_uuid}/revise
Authorization: Bearer <token>
Body: { "title": string?, "text": string?, "message": string }
Response 200/204: no body consumed by the client
```

`title` and `text` are nullable in the contract but in practice both are always
sent (pre-filled from the form). `message` is required and non-empty.

**Errors:**

| Code | Failure type |
|------|-------------|
| 403  | `ForbiddenFailure` |
| 404  | `NotFoundFailure` |
| 409  | `ConflictFailure` — post is not in `changes_requested` state (e.g. moderator approved while author was editing) |
| 422  | `ValidationFailure` |
| network | `NetworkFailure` |
| other | `ServerFailure` |
| unexpected | `UnknownFailure` + `AppLogger.error` |

### Moderation log (already implemented in `PostsApiClient`)

```
GET /posts/{post_uuid}/moderation-log
```

Already wired. No changes to the endpoint itself.

---

## Pre-condition: move moderation log infrastructure to `_shared/`

`edit_post` cannot import from `moderate_post` (cross-slice rule). The
moderation log infrastructure currently lives in `moderate_post/`. Before
extending `edit_post`, move the following four artefacts into `_shared/`:

| Current path | New path |
|---|---|
| `moderate_post/domain/ports/i_moderation_log_port.dart` | `_shared/domain/ports/i_moderation_log_port.dart` |
| `moderate_post/application/moderation_log_cubit.dart` | `_shared/application/moderation_log_cubit.dart` |
| `moderate_post/application/moderation_log_state.dart` | `_shared/application/moderation_log_state.dart` |
| `moderate_post/application/moderation_log_state.freezed.dart` | `_shared/application/moderation_log_state.freezed.dart` |
| `moderate_post/data/moderation_log_adapter.dart` | `_shared/data/moderation_log_adapter.dart` |
| `moderate_post/data/dto/moderation_log_response_dto.dart` | `_shared/data/dto/moderation_log_response_dto.dart` |
| `moderate_post/data/dto/moderation_log_response_dto.freezed.dart` | `_shared/data/dto/moderation_log_response_dto.freezed.dart` |
| `moderate_post/data/dto/moderation_log_response_dto.g.dart` | `_shared/data/dto/moderation_log_response_dto.g.dart` |

After moving, update every import in `moderate_post/` that references the old
paths. This is a pure refactor — the public API and behavior of `moderate_post`
do not change, so its outside-in test must stay green throughout.

`posts_api_client.dart` already imports `moderation_log_response_dto` from the
old `moderate_post/data/dto/` path — update that import too.

---

## Target file structure

### New files

```
lib/features/posts/edit_post/
├── data/
│   ├── dto/
│   │   └── revise_post_request_dto.dart   # freezed DTO: title?, text?, message
│   └── revise_post_adapter.dart           # IRevisePostPort impl, double-catch
└── domain/
    └── ports/
        └── i_revise_post_port.dart        # Future<Either<Failure, void>> call(UpdatedPostData)

lib/features/posts/_shared/
├── application/
│   ├── moderation_log_cubit.dart          # moved from moderate_post
│   ├── moderation_log_state.dart          # moved from moderate_post
│   └── moderation_log_state.freezed.dart  # moved from moderate_post (regen)
├── data/
│   ├── dto/
│   │   ├── moderation_log_response_dto.dart          # moved from moderate_post
│   │   ├── moderation_log_response_dto.freezed.dart  # regen
│   │   └── moderation_log_response_dto.g.dart        # regen
│   └── moderation_log_adapter.dart        # moved from moderate_post
└── domain/
    └── ports/
        └── i_moderation_log_port.dart     # moved from moderate_post
```

### Modified files

```
lib/features/posts/edit_post/
├── data/
│   └── edit_post_adapter.dart             # unchanged (EditPostPort still valid)
├── domain/
│   ├── entities/
│   │   └── updated_post_data.dart         # add postUuid, status, revisionMessage
│   └── usecases/
│       └── edit_post_usecase.dart         # inject IRevisePostPort; branch on status
├── application/
│   └── edit_post_cubit.dart               # unchanged (submit signature stays)
└── presentation/
    ├── edit_post_route.dart               # also provide ModerationLogCubit
    └── edit_post_screen.dart              # adaptive layout + revision message field

lib/features/posts/_shared/
├── application/
│   └── post_event.dart                    # add PostRevisedEvent
└── data/
    └── posts_api_client.dart              # add revisePost() method
                                           # update moderation_log_response_dto import

lib/features/posts/moderate_post/
    (import paths only — no logic changes)

lib/features/posts/pending_posts/application/
    └── pending_posts_cubit.dart           # _onPostEvent also handles PostRevisedEvent → refresh()
```

---

## Implementation steps

### 0) REFACTOR — move moderation log infrastructure to `_shared/`

Move the eight files listed in the pre-condition table. Update every affected
import. After moving, verify `moderate_post/` tests still pass.

### 1) `_shared/application/post_event.dart` — add `PostRevisedEvent`

```dart
final class PostRevisedEvent extends PostEvent {
  PostRevisedEvent(this.postUuid);
  final String postUuid;
}
```

### 2) `_shared/data/posts_api_client.dart` — add `revisePost`

```dart
@PATCH('/posts/{post_uuid}/revise')
Future<void> revisePost(
  @Path('post_uuid') String postUuid,
  @Body() RevisePostRequestDto body,
);
```

Add the import for `RevisePostRequestDto`. Run `build_runner` after this step.

### 3) `edit_post/data/dto/revise_post_request_dto.dart`

```dart
@freezed
sealed class RevisePostRequestDto with _$RevisePostRequestDto {
  const factory RevisePostRequestDto({
    String? title,
    String? text,
    @JsonKey(name: 'message') required String message,
  }) = _RevisePostRequestDto;

  factory RevisePostRequestDto.fromJson(Map<String, dynamic> json) =>
      _$RevisePostRequestDtoFromJson(json);
}
```

### 4) `edit_post/domain/ports/i_revise_post_port.dart`

```dart
abstract interface class IRevisePostPort {
  Future<Either<Failure, void>> call(UpdatedPostData data);
}
```

### 5) `edit_post/data/revise_post_adapter.dart`

Implements `IRevisePostPort`. Calls `PostsApiClient.revisePost`. Double-catch
pattern identical to `EditPostAdapter` and `ModerationLogAdapter`.

Error mapping:
- 403 → `ForbiddenFailure`
- 404 → `NotFoundFailure`
- 409 → `ConflictFailure(message: '...')`
- 422 → `ValidationFailure(fieldErrors: {})`
- network → `NetworkFailure`
- other DioException → `ServerFailure`
- unexpected object → `UnknownFailure` + `_logger.error`

DI annotation: `@LazySingleton(as: IRevisePostPort)`

### 6) `edit_post/domain/entities/updated_post_data.dart` — extend

Add three fields:

```dart
final String postUuid;           // from Post.postUuid
final PostStatus status;         // from Post.status, drives use-case branching
final String? revisionMessage;   // non-null only for changesRequested path
```

No other changes to the class.

### 7) `edit_post/domain/usecases/edit_post_usecase.dart` — smart routing

Inject `IRevisePostPort` alongside existing `EditPostPort`.

```dart
EditPostUseCase(this._editPort, this._revisePort, this._authCubit);
```

Branching logic (ownership decision — neither cubit nor screen need to know):

```dart
Future<Either<Failure, void>> call(UpdatedPostData data) async {
  final currentUser = _authCubit.currentUser;
  if (currentUser == null || currentUser.username != data.username) {
    return Left(Failure.forbidden(message: "Cannot edit another user's post"));
  }

  if (data.status == PostStatus.changesRequested) {
    final msg = data.revisionMessage?.trim() ?? '';
    if (msg.isEmpty) {
      return Left(Failure.validation(
        fieldErrors: {'message': 'Revision message is required'},
      ));
    }
    return _revisePort(data);
  }

  return _editPort(data);
}
```

IMPORTANT: `approved` status is NOT blocked here. The Save button is disabled
in the UI for approved posts, but the use-case itself does not gate on it.

### 8) `edit_post/presentation/edit_post_route.dart` — provide `ModerationLogCubit`

Change `BlocProvider` to `MultiBlocProvider` and add `ModerationLogCubit`:

```dart
MultiBlocProvider(
  providers: [
    BlocProvider(create: (_) => getIt<EditPostCubit>()),
    BlocProvider(create: (_) => getIt<ModerationLogCubit>()),
  ],
  child: EditPostScreen(post: post, username: username),
)
```

Pattern: identical to `ModeratePostPage`.

### 9) `edit_post/presentation/edit_post_screen.dart` — adaptive layout

Replace the current single-column `Scaffold` body with a `StatefulWidget` that:

**initState:**
- Create controllers for title, mediaUrl, text.
- If status is `changesRequested`: also create `_revisionMessageController`.
- Call `ModerationLogCubit.load(post.postUuid)` immediately (via `addPostFrameCallback`) when width ≥ `AppBreakpoints.medium`.
- On tab switch to Log tab (narrow): call `load()` only if state is still
  `ModerationLogInitial` (guarded — same pattern as `ModeratePostScreen`).

**Save button gating:**
- `PostStatus.approved` → `onPressed: null`.
- Other statuses → `onPressed: () => _onSubmit(context)`.

**`_onSubmit`:**
```dart
context.read<EditPostCubit>().submit(
  UpdatedPostData(
    username: widget.username,
    id: widget.post.id,
    postUuid: widget.post.postUuid,
    status: widget.post.status,
    title: _titleController.text.trim(),
    text: _textController.text.trim(),
    mediaUrl: ...,
    revisionMessage: widget.post.status == PostStatus.changesRequested
        ? _revisionMessageController.text.trim()
        : null,
  ),
);
```

**Revision message field** (rendered only when `status == changesRequested`):
- `TextFormField`, multiline (3 lines min), label and hint from `slang`.
- Validator: returns localised error if empty.
- Appears below the text field, above the Save button.

**"Approved — cannot edit" helper text** (rendered only when `status == approved`):
- Small text below the disabled Save button, via `slang`.

**BlocListener on `EditPostSuccess`:**
```dart
PostEventBus.publish(PostRevisedEvent(widget.post.postUuid));
context.router.maybePop();
```

**Adaptive layout** (mirror of `ModeratePostScreen`):

Wide (≥ `AppBreakpoints.medium`):
```
Row
├── Expanded(flex: 1) → ModerationLogPanel (new reusable widget)
├── VerticalDivider
└── Expanded(flex: 1) → post editor form (existing form, extracted to widget)
```

Narrow (< `AppBreakpoints.medium`):
```
DefaultTabController(length: 2)
├── TabBar [ t.posts.editPost.tabs.edit | t.posts.editPost.tabs.log ]
└── TabBarView
    ├── tab 0: post editor form
    └── tab 1: ModerationLogPanel
```

Extract the form body into a private widget `_EditForm` to avoid duplicating it
in both branches.

`ModerationLogPanel` is a new widget inside
`edit_post/presentation/widgets/moderation_log_panel.dart`. It reads
`ModerationLogState` from `BlocBuilder<ModerationLogCubit, ModerationLogState>`
and renders:
- Loading: `CircularProgressIndicator`
- Error: error text
- Loaded/empty: localised empty-state message
- Loaded/non-empty: `ListView` of log entries (each entry shows type, actor,
  timestamp, action label, message)

IMPORTANT: Do NOT import from `moderate_post/presentation/` to reuse its
`ModerationPanel` widget — that would violate slice isolation.

### 10) `pending_posts/application/pending_posts_cubit.dart` — handle `PostRevisedEvent`

Extend `_onPostEvent`:

```dart
void _onPostEvent(PostEvent event) {
  if (event is PostModeratedEvent) {
    // existing: remove post from list
    ...
  }
  if (event is PostRevisedEvent) {
    refresh();  // reload the full pending list
  }
}
```

IMPORTANT: Confirm with user before touching this file, as it belongs to the
`pending_posts` slice.

### 11) Localisation — add keys to `en.json` and `ru.json`

New keys under `posts.editPost`:

```json
"tabs": {
  "edit": "Edit",
  "log": "Moderation Log"
},
"revisionMessage": {
  "label": "Revision message",
  "hint": "Describe what you changed to address the moderator's feedback"
},
"approvedHint": "This post is approved and can no longer be edited.",
"errors": {
  "revisionMessageRequired": "A revision message is required.",
  "conflict": "The post status changed while you were editing. Check the current status.",
  "notFound": "Post not found.",
  "forbidden": "You do not have permission to edit this post.",
  "generic": "Something went wrong. Please try again."
}
```

Run `slang` after updating JSON.

### 12) `build_runner` + `dart format` + `dart analyze`

Run after all code is written. Resolve any generated-file conflicts.

---

## Tests

### `test/features/posts/edit_post/data/revise_post_adapter_test.dart` (new)

- 200/204 success → `Right(null)`
- 403 → `Left(ForbiddenFailure)`
- 404 → `Left(NotFoundFailure)`
- 409 → `Left(ConflictFailure)`
- 422 → `Left(ValidationFailure)`
- `DioException` with no status code → `Left(NetworkFailure)` or `Left(ServerFailure)`
- unexpected exception → `Left(UnknownFailure)`, verify `_logger.error` called

Prior art: `test/features/posts/edit_post/data/edit_post_adapter_test.dart`

### `test/features/posts/edit_post/domain/edit_post_usecase_test.dart` (extend)

Add to existing test file:

- `changesRequested` + empty `revisionMessage` → `Left(ValidationFailure)`, neither port called
- `changesRequested` + non-empty `revisionMessage` → calls `_revisePort`, not `_editPort`
- `pendingReview` → calls `_editPort`, not `_revisePort`
- `approved` → calls `_editPort` (save button is disabled in UI; use-case does not block it)
- Adapter failure propagates unchanged

### `test/features/posts/edit_post/application/edit_post_cubit_test.dart` (extend)

Add:

- `submit(changesRequestedData)` → emits `[loading, success]`

### `test/features/posts/edit_post/presentation/edit_post_screen_test.dart` (new / extend)

Wide layout (set window width ≥ 600):
- Both panes rendered (editor and log panel)
- `ModerationLogCubit.load()` called on build
- Revision message field visible when `status == changesRequested`
- Save button disabled (`onPressed == null`) when `status == approved`
- Log loading indicator shown while `ModerationLogLoading`

Narrow layout (window width < 600):
- Only "Edit" tab visible initially; log panel absent
- Switching to "Log" tab renders log panel and calls `ModerationLogCubit.load()`
- Switching back and forth does NOT call `load()` again

Prior art: `test/features/posts/moderate_post/presentation/`

---

## Report

Provide on completion:

- Full list of new files, moved files, and modified files.
- Confirmation that `moderate_post/` behaviour is unchanged (only imports updated).
- Confirmation that `pending_posts/` outside-in test (if it exists) is still green.
- Confirmation that no other slice was touched beyond the scope above.
- UX walkthrough: `changesRequested` flow, `pendingReview` flow, `approved` read-only view.
- All new tests written and green; existing tests still green.

---

## Do NOT do

- Create a new top-level route or screen for revisions — the existing `EditPostRoute` is extended in place.
- Import from `moderate_post/` in `edit_post/` — move shared code to `_shared/` first.
- Reuse `ModerationPanel` from `moderate_post/presentation/` in `edit_post/` — that violates slice isolation.
- Block `approved` status in the use-case — the UI disables the button; the use-case does not gatekeep it.
- Show a generic "session expired" snackbar on success — the screen calls `maybePop()` directly.
- Send only a message without title/text to `/revise` — always send all three fields.
- Modify `_shared/domain/entities/` (Post, PostStatus) — they are already correct.
- Touch `moderate_post/` logic, tests, or presentation — import-path updates only.
