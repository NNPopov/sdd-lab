# 0039 · adapt_moderation_log_contract — Outside-in test spec

## Goal

Prove that `PendingPostsCubit.load()` emits `PendingPostsLoaded` (not `PendingPostsError`)
when the API returns a post whose moderation log entries omit the `actor_user_id` and
`actor_username` fields, and that the mapped log entries carry `null` for both actor
fields.

## Entry point

`cubit.load()`

## Wired real (production code in the test)

- `PendingPostsAdapter` (data layer, implements `PendingPostsPort`)
- `GetPendingPostsUseCase` (domain layer, delegates to the adapter)
- `PendingPostsCubit` (application layer, the system under test)

## Mocked (system boundaries only)

- **PostsApiClient**: configured per scenario below; returns a `PendingPostsDto`
  constructed in-test, or throws a `DioException`.
- **PostEventBus**: `stream` returns an empty broadcast stream (no event published
  during these scenarios).
- **AppLogger**: `error(...)` and `warning(...)` are stubbed to return null.

---

## Test scenarios

### Scenario 1: moderation log entry without actor fields — loads successfully

**Setup:**
- `PostsApiClient.getPendingPosts` returns a `PendingPostsDto` with one item:
  - `postUuid: 'uuid-changes-001'`
  - `title: 'Needs revision'`
  - `text: 'Body text.'`
  - `status: 'changes_requested'`
  - `createdAt: DateTime(2026, 5, 16, 20, 45)`
  - `authorUsername: 'userson3'`
  - `moderationLog`: one `ModerationLogEntryDto` with:
    - `id: 440`
    - `eventType: 'moderator_review'`
    - `action: 'changes_requested'`
    - `message: 'strange post'`
    - `createdAt: DateTime(2026, 5, 16, 21, 3)`
    - `actorUserId` and `actorUsername` **omitted** (rely on nullable defaults)
  - `totalCount: 1`, `page: 1`, `itemsPerPage: 10`

**Act:**
- `await cubit.load()`

**Expect:**
- States emitted: `[PendingPostsLoading, PendingPostsLoaded]`
- In the `PendingPostsLoaded` state:
  - `items.length == 1`
  - `items.first.postUuid == 'uuid-changes-001'`
  - `items.first.status == PostStatus.changesRequested`
  - `items.first.moderationLog.length == 1`
  - `items.first.moderationLog.first.actorUserId == null`
  - `items.first.moderationLog.first.actorUsername == null`
  - `items.first.moderationLog.first.action == ModerationAction.changesRequested`
  - `hasMore == false`
- `logger.error` never called (no deserialization exception propagated)

---

### Scenario 2: server returns 403 — cubit emits PermissionDenied error

**Setup:**
- `PostsApiClient.getPendingPosts` throws a `DioException` with:
  - `statusCode: 403`
  - `type: DioExceptionType.badResponse`
  - `path: '/posts/pending'`

**Act:**
- `await cubit.load()`

**Expect:**
- States emitted: `[PendingPostsLoading, PendingPostsError]`
- In the `PendingPostsError` state: `failure == const Failure.permissionDenied()`
- `logger.error` never called (a 403 is a handled HTTP error, not an unknown exception)

---

## Out of scope for this test

- Widget rendering of the pending posts list, the moderation log tile, or the null
  actor username display — covered by widget tests on the affected widget files
  separately.
- Route navigation to the Moderate Post screen.
- The `loadMore` and `refresh` methods — these exercise the same adapter code path and
  are covered by the existing 0034 cubit unit tests.
- The moderation log panel in the Edit Post screen — that widget is covered by widget
  tests for slice 0036/0021 separately.
