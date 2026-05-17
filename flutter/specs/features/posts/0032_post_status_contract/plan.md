# Plan: post_status_contract (0032)

## Overview

This is a pure data-contract slice — no new cubit, usecase, port, screen, or route.
The change extends existing shared types (`Post`, `PostDto`, `PostItemDto`) and updates
the three adapters that map DTOs to the `Post` domain entity.

There is no `0032_post_status_contract/` slice folder under `lib/features/posts/`.
All changes land in `_shared/` and in the existing per-slice `data/` adapters.

---

## Files to create

| File | Purpose |
|---|---|
| `lib/features/posts/_shared/domain/entities/post_status.dart` | New `PostStatus` enum |

---

## Files to modify

| File | What changes |
|---|---|
| `lib/features/posts/_shared/domain/entities/post.dart` | Add `postUuid` and `status` fields |
| `lib/features/posts/_shared/data/dto/post_dto.dart` | Add `post_uuid` and `status` fields |
| `lib/features/posts/_shared/data/dto/post_item_dto.dart` | Add `post_uuid` and `status` fields |
| `lib/features/posts/post_details/data/get_post_adapter.dart` | Map new fields to `Post` |
| `lib/features/posts/user_posts/data/user_posts_adapter.dart` | Map new fields to each `Post` item |
| `lib/features/posts/list_posts/data/list_posts_adapter.dart` | Map new fields to each `Post` item |

The following adapters return `Future<Either<Failure, void>>` and do **not** map to
`Post`, so they are **not touched**:
- `create_post/data/create_post_adapter.dart`
- `edit_post/data/edit_post_adapter.dart`
- `delete_post/data/delete_post_adapter.dart`
- `erase_db_post/data/erase_db_post_adapter.dart`

---

## Implementation steps

### Step 1 — New domain enum: PostStatus

**Create** `lib/features/posts/_shared/domain/entities/post_status.dart`:

```dart
enum PostStatus { pendingReview, approved, changesRequested }
```

Pure Dart — zero imports. The enum lives in `_shared/domain/entities/` because all
three adapters (and downstream slices 0033–0037) will reference it.

---

### Step 2 — Extend the Post entity

**Modify** `lib/features/posts/_shared/domain/entities/post.dart`.

Add two required fields to the constructor:
- `required this.postUuid` — `String`
- `required this.status` — `PostStatus`

`Post` is a plain Dart class (not freezed), so no codegen is needed for this file.

---

### Step 3 — Extend PostDto

**Modify** `lib/features/posts/_shared/data/dto/post_dto.dart`.

Add two fields inside the freezed factory:
- `@JsonKey(name: 'post_uuid') required String postUuid`
- `required String status`

`status` stays as `String` at the DTO level; the adapter converts it. This keeps
`domain/` free of any JSON-mapping knowledge.

After the edit, run:
```
dart run build_runner build --delete-conflicting-outputs
```

---

### Step 4 — Extend PostItemDto

**Modify** `lib/features/posts/_shared/data/dto/post_item_dto.dart`.

Same two fields as `PostDto`. `PostItemDto` is used by both `getPosts` and
`getUserPosts` — both paginated list endpoints.

After the edit, rebuild via build_runner (can be batched with Step 3 rebuild).

---

### Step 5 — Update GetPostAdapter

**Modify** `lib/features/posts/post_details/data/get_post_adapter.dart`.

In the `Post(...)` constructor call, add:
```dart
postUuid: dto.postUuid,
status: _parseStatus(dto.status),
```

Add a private helper `_parseStatus`:
```dart
PostStatus _parseStatus(String raw) {
  return switch (raw) {
    'approved' => PostStatus.approved,
    'changes_requested' => PostStatus.changesRequested,
    _ => () {
        if (raw != 'pending_review') {
          _logger.warning('Unknown post status: $raw, falling back to pendingReview');
        }
        return PostStatus.pendingReview;
      }(),
  };
}
```

Import `PostStatus` from `_shared/domain/entities/post_status.dart`.

> Note: The `_logger` field already exists in this adapter. The `warning` method is
> called (not `error`) because an unknown status is recoverable — the app falls back
> gracefully without crashing.

---

### Step 6 — Update UserPostsAdapter

**Modify** `lib/features/posts/user_posts/data/user_posts_adapter.dart`.

Inside the `.map((p) => Post(...))` call, add:
```dart
postUuid: p.postUuid,
status: _parseStatus(p.status),
```

Add the same `_parseStatus` helper as in Step 5.

---

### Step 7 — Update ListPostsAdapter

**Modify** `lib/features/posts/list_posts/data/list_posts_adapter.dart`.

Same change as Step 6 (this adapter also maps `PostItemDto` items via `PaginatedPostsDto`).

---

### Step 8 — Run codegen and verify

```
dart run build_runner build --delete-conflicting-outputs
dart format .
dart analyze
flutter test
```

Expected: no warnings, no test regressions.

---

## Test plan

No new cubit/usecase/widget layer exists for this slice. Testing is adapter-only.
The three adapter tests already exist; this plan extends them with `postUuid` and
`status` assertions.

### `test/features/posts/post_details/data/get_post_adapter_test.dart`

New cases to add (keep existing cases intact):

- `status 'approved' maps to PostStatus.approved` — assert `post.status == PostStatus.approved`
- `status 'pending_review' maps to PostStatus.pendingReview`
- `status 'changes_requested' maps to PostStatus.changesRequested`
- `unknown status falls back to PostStatus.pendingReview and logs warning` —
  verify `logger.warning(any(), ...)` called once
- `post_uuid round-trips correctly` — assert `post.postUuid == 'uuid-abc'`

### `test/features/posts/user_posts/data/user_posts_adapter_test.dart`

New cases to add (keep existing cases intact):

- `status 'approved' on PostItemDto maps to PostStatus.approved on Post`
- `status 'pending_review' maps to PostStatus.pendingReview`
- `status 'changes_requested' maps to PostStatus.changesRequested`
- `unknown status falls back to PostStatus.pendingReview and logs warning`
- `post_uuid round-trips correctly`

### `test/features/posts/list_posts/data/list_posts_adapter_test.dart`

Same five new cases as `user_posts_adapter_test`.

---

## What NOT to do

- Do **not** add `status` conversion inside the DTO (DTO is JSON-only; conversion belongs
  in the adapter).
- Do **not** make `postUuid` nullable on the `Post` entity. The backend guarantees
  it is always present after this contract update.
- Do **not** create a new `lib/features/posts/0032_post_status_contract/` folder in
  `lib/` — this slice has no application/domain/presentation layers.
- Do **not** modify `PostsApiClient` — the return types already cover all affected
  endpoints.
- Do **not** touch any UI, cubit, or navigation file — no UI changes are in scope.
- Do **not** add a `PostStatus` test file separate from the adapter tests; enum
  coverage comes from adapter tests.
