# 0034 · pending_posts — Outside-in test spec

## Goal

Prove that `PendingPostsCubit.load()` calls `GET /posts/pending`, maps the
paginated response — including nested `moderation_log` entries and `status` —
to `PendingPostItem` domain objects, computes `hasMore` from the pagination
fields, and emits the correct state sequence, wiring the real adapter, use case,
and cubit together with Dio mocked at the HTTP boundary.

## Entry point

`cubit.load()`

Called once per scenario against a freshly constructed cubit wired to real
production layers (`PendingPostsAdapter` → `GetPendingPostsUseCase` →
`PendingPostsCubit`), with Dio intercepted at the network boundary.

## Wired real (production code in the test)

- `PendingPostsAdapter` (data layer — calls `PostsApiClient.getPendingPosts`,
  parses `PendingPostsDto` / `PendingPostItemDto` / `ModerationLogEntryDto`,
  maps to `PaginatedResult<PendingPostItem>`)
- `PendingPostsPort` (bound to `PendingPostsAdapter` — wired manually, no DI container)
- `GetPendingPostsUseCase` (domain layer — delegates to the port)
- `PendingPostsCubit` (application layer — system under test)

## Mocked (system boundaries only)

- **Dio**: intercepted with a mock HTTP handler; returns a pre-configured JSON
  body for `GET /posts/pending`.
- **PostEventBus**: a mock that exposes an empty broadcast stream — required
  because `PendingPostsCubit` subscribes to the event bus in its constructor;
  the subscription must not throw, but no events need to be delivered for these
  scenarios.
- **AppLogger**: a mock that records calls — needed to verify it is NOT called
  on the success path and IS called on the unexpected-exception path (if tested).

---

## Test scenarios

### Scenario 1: first-page load — items mapped, moderationLog count correct, `hasMore = true`

**Setup:**
- Dio returns `200` for `GET /posts/pending?page=1&items_per_page=10` with body:
  ```
  {
    "items": [
      {
        "post_uuid": "abc-001",
        "title": "Review this post",
        "text": "Post body text that goes on for a while.",
        "media_url": null,
        "status": "pending_review",
        "created_at": "2026-05-16T10:00:00.000Z",
        "updated_at": "2026-05-16T10:00:00.000Z",
        "author_username": "alice",
        "moderation_log": [
          {
            "id": 1,
            "event_type": "moderator_review",
            "action": "changes_requested",
            "message": "Please revise.",
            "created_at": "2026-05-16T11:00:00.000Z",
            "actor_user_id": 42,
            "actor_username": "mod1"
          },
          {
            "id": 2,
            "event_type": "author_revision",
            "action": null,
            "message": null,
            "created_at": "2026-05-16T12:00:00.000Z",
            "actor_user_id": 7,
            "actor_username": "alice"
          }
        ]
      }
    ],
    "total_count": 25,
    "page": 1,
    "items_per_page": 10
  }
  ```

**Act:**
- `cubit.load()`

**Expect:**
- States emitted by the Cubit:
  `[PendingPostsLoading(), PendingPostsLoaded(items: [PendingPostItem(postUuid: 'abc-001', title: 'Review this post', authorUsername: 'alice', status: PostStatus.pendingReview, moderationLog: <2 entries>)], page: 1, hasMore: true)]`
- `hasMore` is `true` because `1 × 10 < 25`.
- `PendingPostItem.postUuid` is `'abc-001'`, `title` is `'Review this post'`,
  `authorUsername` is `'alice'`, `status` is `PostStatus.pendingReview`.
- `PendingPostItem.moderationLog` contains exactly 2 entries; the first has
  `eventType: ModerationEventType.moderatorReview` and `action: ModerationAction.changesRequested`;
  the second has `eventType: ModerationEventType.authorRevision` and `action: null`.
- `AppLogger.error` is NOT called.

---

### Scenario 2: server returns 403 — adapter maps to `PermissionDenied`, cubit emits error state

**Setup:**
- Dio returns `403` for `GET /posts/pending?page=1&items_per_page=10` with no body.

**Act:**
- `cubit.load()`

**Expect:**
- States emitted by the Cubit:
  `[PendingPostsLoading(), PendingPostsError(PermissionDenied())]`
- `AppLogger.error` is NOT called (a mapped HTTP error is handled by the inner
  `DioException` catch; the outer catch-all and its logger call are not reached).

---

## Out of scope for this test

- `loadMore()` and `refresh()` cubit flows (covered by `pending_posts_cubit_test.dart` unit tests).
- `PostModeratedEvent` integration — item removal from the loaded list (covered by `pending_posts_cubit_test.dart` unit tests).
- 401, 404, 5xx, and network-error failure paths (covered by `pending_posts_adapter_test.dart` unit tests).
- `hasMore = false` boundary case (covered by adapter and cubit unit tests).
- Widget rendering, tile content display, scroll behaviour, pull-to-refresh gesture (covered by widget tests).
- Route navigation to the moderation screen (covered by widget tests).
- Nav-bar tab visibility based on `moderatePosts` permission (covered by `app_shell_screen` widget tests or manual M-scenarios in `validation.md`).
