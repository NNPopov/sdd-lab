# Plan — 0030: Adapt Paginated Posts Contract

## Header

Task: adapt the `user_posts` slice to the new `GET /{username}/posts` response shape.
The backend renamed `data` → `items`, removed `has_more`, added `total_count` and
`items_per_page`, and added `username` to each post item. No visible behaviour changes —
pagination, infinite scroll, and pull-to-refresh continue to work identically.

---

## Context

### Read

- `CLAUDE.md` — universal rules
- `lib/features/posts/user_posts/data/dto/paginated_posts_dto.dart` — DTO being changed
- `lib/features/posts/user_posts/domain/entities/paginated_posts.dart` — entity being changed
- `lib/features/posts/user_posts/data/user_posts_adapter.dart` — adapter being changed
- `lib/features/posts/_shared/domain/entities/post.dart` — entity being extended
- `lib/features/posts/_shared/data/dto/post_dto.dart` — stays unchanged; reference only
- `lib/features/posts/user_posts/domain/ports/user_posts_port.dart` — verify unchanged
- `lib/features/posts/user_posts/domain/usecases/user_posts_usecase.dart` — verify unchanged
- `lib/features/posts/user_posts/application/user_posts_cubit.dart` — verify unchanged
- `lib/features/posts/user_posts/application/user_posts_state.dart` — verify unchanged
- `test/features/posts/user_posts/data/user_posts_adapter_test.dart` — being updated
- `test/features/posts/user_posts/application/user_posts_cubit_test.dart` — being updated
- `lib/features/users/_shared/data/dto/paginated_users_dto.dart` — reference pattern (0029)
- `lib/features/users/list_users/domain/entities/paginated_users.dart` — reference pattern (0029)
- `agent_docs/error_handling.md` — DTO soft-contract rules and adapter template

### Do NOT read

- Any other slice under `lib/features/posts/`
- Presentation layer files (screen, widgets, route) — unchanged
- `core/` — not involved
- Generated files (`*.freezed.dart`, `*.g.dart`) — will be regenerated
- `lib/features/posts/_shared/data/posts_api_client.dart` — endpoint signature unchanged

---

## API

```
GET /{username}/posts?page={page}&items_per_page={per_page}
No Authorization header required — public endpoint

Response 200:
{
  "items": [
    {
      "id": 2,
      "title": "Test Post",
      "text": "test",
      "media_url": null,
      "created_at": "2026-04-29T21:26:38.178566Z",
      "created_by_user_id": 2,
      "username": "userson1"
    }
  ],
  "total_count": 1,
  "page": 1,
  "items_per_page": 10
}
```

**Changes from the previous contract:**
- `data` (list field) → renamed to `items`
- `has_more` (boolean) → **removed**; `hasMore` must now be derived as
  `page * itemsPerPage < totalCount`
- `username` added to each item (not present in the old contract)

**Per-item object:** all existing fields unchanged; `username: String` is new.

---

## Files changed

```
lib/features/posts/_shared/data/dto/
└── post_item_dto.dart               CREATE — new DTO with username field
    post_item_dto.freezed.dart       REGENERATE (build_runner)
    post_item_dto.g.dart             REGENERATE (build_runner)

lib/features/posts/_shared/domain/entities/
└── post.dart                        MODIFY — add String? username field

lib/features/posts/user_posts/data/dto/
└── paginated_posts_dto.dart         MODIFY — rename data→items, remove hasMore, add totals
    paginated_posts_dto.freezed.dart REGENERATE (build_runner)
    paginated_posts_dto.g.dart       REGENERATE (build_runner)

lib/features/posts/user_posts/domain/entities/
└── paginated_posts.dart             MODIFY — remove hasMore field, add totals + computed getter

lib/features/posts/user_posts/data/
└── user_posts_adapter.dart          MODIFY — update mapping to new DTO shape

test/features/posts/user_posts/data/
└── user_posts_adapter_test.dart     MODIFY — update fixture DTOs and add hasMore boundary tests

test/features/posts/user_posts/application/
└── user_posts_cubit_test.dart       MODIFY — update _page() helper constructor call sites
```

**Unchanged (verify only, do not edit):**
- `user_posts_port.dart`
- `user_posts_usecase.dart`
- `user_posts_cubit.dart`
- `user_posts_state.dart`
- `posts_api_client.dart`
- `post_dto.dart` and its generated files
- All presentation files (screen, route, widgets)
- All other post slices

---

## What to do

### Step 1 — Create `PostItemDto`

File: `lib/features/posts/_shared/data/dto/post_item_dto.dart`

New `@freezed sealed class` stored alongside `post_dto.dart` in `_shared/data/dto/`.
Carries all the same fields as `PostDto` **plus** `username`.

Apply the soft-contract rules from `agent_docs/error_handling.md`:
- `required int id` — without `id` the DTO is semantically meaningless
- `required String username` — primary identifier of the author; always present
- `@Default('') String title`
- `@Default('') String text`
- `@JsonKey(name: 'media_url') String? mediaUrl`
- `@JsonKey(name: 'created_at') DateTime? createdAt`
- `@JsonKey(name: 'created_by_user_id') int? createdByUserId`

After creating this file, run:
```
dart run build_runner build --delete-conflicting-outputs
```

### Step 2 — Update `PaginatedPostsDto`

File: `lib/features/posts/user_posts/data/dto/paginated_posts_dto.dart`

- Change the import: replace `PostDto` import with `PostItemDto`.
- Rename `data` → `items`; change list type to `List<PostItemDto>`.
- Remove `has_more` entirely.
- Add `totalCount` and `itemsPerPage`.
- All four fields are `required` — a response missing any of them is semantically
  invalid and should fail deserialization loudly (no `@Default` on the envelope fields).

Result:
```dart
@freezed
sealed class PaginatedPostsDto with _$PaginatedPostsDto {
  const factory PaginatedPostsDto({
    required List<PostItemDto> items,
    @JsonKey(name: 'total_count') required int totalCount,
    required int page,
    @JsonKey(name: 'items_per_page') required int itemsPerPage,
  }) = _PaginatedPostsDto;

  factory PaginatedPostsDto.fromJson(Map<String, dynamic> json) =>
      _$PaginatedPostsDtoFromJson(json);
}
```

Regenerate after editing.

### Step 3 — Update `Post` entity

File: `lib/features/posts/_shared/domain/entities/post.dart`

Add `this.username` as an **optional** named parameter (nullable, no default).
Single-post endpoints (`getPost`, `createPost`) do not return `username`, so
existing callers that construct `Post` without it must not break.

```dart
class Post {
  const Post({
    required this.id,
    required this.title,
    required this.text,
    required this.createdAt,
    required this.createdByUserId,
    this.mediaUrl,
    this.username,
  });

  final int id;
  final String title;
  final String text;
  final DateTime createdAt;
  final int createdByUserId;
  final String? mediaUrl;
  final String? username;
}
```

No codegen needed — this is a plain Dart class.

### Step 4 — Update `PaginatedPosts` entity

File: `lib/features/posts/user_posts/domain/entities/paginated_posts.dart`

- Remove `required this.hasMore` and `final bool hasMore`.
- Add `required this.totalCount` and `required this.itemsPerPage`.
- Add computed getter: `bool get hasMore => page * itemsPerPage < totalCount`.

Follows the exact pattern of `PaginatedUsers` (slice 0029).

Formula verification:

| Scenario | totalCount | page | itemsPerPage | result |
|---|---|---|---|---|
| Mid-pagination | 100 | 1 | 10 | `10 < 100` → `true` |
| Last page exactly full | 10 | 1 | 10 | `10 < 10` → `false` |
| Last page partial | 12 | 1 | 10 | `10 < 12` → `true` |
| Empty list | 0 | 1 | 10 | `10 < 0` → `false` |

No codegen needed — plain Dart class.

### Step 5 — Update `UserPostsAdapter`

File: `lib/features/posts/user_posts/data/user_posts_adapter.dart`

- Update import: replace `PostDto` with `PostItemDto` (or remove if no longer needed directly).
- Map `dto.items` instead of `dto.data`.
- In the `Post(...)` constructor call, add `username: p.username`.
- Replace `hasMore: dto.hasMore` with `totalCount: dto.totalCount` and
  `itemsPerPage: dto.itemsPerPage` in the `PaginatedPosts(...)` constructor.
- The double-catch structure, `_logger`, and `_mapHttp` are **unchanged**.

Result of the mapping block:
```dart
return Right(
  PaginatedPosts(
    items: dto.items
        .map(
          (p) => Post(
            id: p.id,
            title: p.title,
            text: p.text,
            createdAt: p.createdAt ?? DateTime(0),
            createdByUserId: p.createdByUserId ?? 0,
            mediaUrl: p.mediaUrl,
            username: p.username,
          ),
        )
        .toList(),
    totalCount: dto.totalCount,
    page: dto.page,
    itemsPerPage: dto.itemsPerPage,
  ),
);
```

### Step 6 — Update adapter test

File: `test/features/posts/user_posts/data/user_posts_adapter_test.dart`

The current `testDto` uses `PaginatedPostsDto(data: [...], ...)` with `PostDto` items.
Update it to use the new shape with `PostItemDto` items.

**a) Update imports and fixture DTO:**
- Replace `PostDto` import with `PostItemDto`.
- Rename `data:` → `items:` in `PaginatedPostsDto(...)`.
- Add `totalCount`, `page`, `itemsPerPage` to the DTO constructor (all now `required`).
- Replace `PostDto(...)` with `PostItemDto(...)` inside the items list; add `username: 'alice'`.

New `testDto`:
```dart
final testDto = PaginatedPostsDto(
  items: [
    PostItemDto(
      id: 1,
      title: 'Title',
      text: 'Text',
      createdAt: DateTime(2026),
      username: 'alice',
    ),
  ],
  totalCount: 100,
  page: 1,
  itemsPerPage: 10,
);
```

**b) Update existing test assertions:**
- `posts.hasMore` was `isFalse` before because `hasMore` defaulted to `false`.
  With `totalCount: 100, page: 1, itemsPerPage: 10` → `hasMore` is `true`.
  Update the assertion: `expect(posts.hasMore, isTrue)`.
- The `null createdAt` test: update `PaginatedPostsDto(data: [PostDto(id: 1)])` to
  `PaginatedPostsDto(items: [PostItemDto(id: 1, username: 'u')], totalCount: 10, page: 1, itemsPerPage: 10)`.

**c) Add `hasMore = false` boundary test:**
```
success with hasMore=false (last page):
  Arrange: totalCount: 10, page: 1, itemsPerPage: 10
  Assert:  posts.hasMore == false  (1*10 < 10 → false)
```

### Step 7 — Update cubit test

File: `test/features/posts/user_posts/application/user_posts_cubit_test.dart`

The only change needed is the `page()` fixture helper that constructs `PaginatedPosts`.
The `PaginatedPosts` constructor no longer accepts `hasMore`; it now requires
`totalCount` and `itemsPerPage`.

**Update the helper:**
```dart
// OLD
PaginatedPosts page(List<Post> items, {bool hasMore = false, int page = 1}) =>
    PaginatedPosts(items: items, hasMore: hasMore, page: page);

// NEW
PaginatedPosts page(List<Post> items, {int totalCount = 20, int page = 1}) =>
    PaginatedPosts(items: items, totalCount: totalCount, page: page, itemsPerPage: 10);
```

Default `totalCount: 20` with `itemsPerPage: 10` means `1 * 10 < 20 → true` — so the
default still represents `hasMore=true` (same as before).

**Update call sites** — every place that called `page(...)` with `hasMore: false`:

| Old call | New call | Formula |
|---|---|---|
| `page([post2], page: 2)` in loadMore test | `page([post2], page: 2, totalCount: 20)` | `2*10 < 20` → `false` ✓ |
| `page([post1])` in refresh test | `page([post1], totalCount: 10)` | `1*10 < 10` → `false` ✓ |

All existing `seed()` calls use `UserPostsState.loaded(hasMore: ...)` — those are
state fields, not entity constructor calls, and remain **unchanged**.

All existing test group assertions remain unchanged — `hasMore` is still a field on
`UserPostsState.loaded`.

---

## Tests summary

| File | Action | Scenarios affected |
|---|---|---|
| `user_posts_adapter_test.dart` | Update fixtures + add 1 test | 2 existing tests updated; 1 new `hasMore=false` boundary test |
| `user_posts_cubit_test.dart` | Update `page()` helper + 2 call sites | No scenario logic changes; only constructor call syntax |

No new test files. No changes to widget tests or screen tests.

---

## Report (expected at completion)

- List of files modified (5 production files, 2 test files, 3 generated files)
- Confirmation that no other slice was touched
- `dart format .` — no diff
- `dart analyze` — no warnings
- `build_runner` ran and generated files are up-to-date
- `flutter test test/features/posts/user_posts/` — all green

---

## What NOT to do

- ❌ Do NOT modify `post_dto.dart` — single-post endpoints are unaffected
- ❌ Do NOT add `hasMore` back as a constructor parameter to `PaginatedPosts` — it is a
  computed getter from this point forward
- ❌ Do NOT change `user_posts_cubit.dart`, `user_posts_state.dart`,
  `user_posts_usecase.dart`, or `user_posts_port.dart` — they have no dependency on
  the DTO shape
- ❌ Do NOT touch any presentation files
- ❌ Do NOT touch `list_posts`, `create_post`, `post_details`, `edit_post`, or any
  other post slice
- ❌ Do NOT make `PaginatedPostsDto.items` nullable or add `@Default([])` — a response
  without items is semantically meaningless and should deserialize as an error
- ❌ Do NOT add `username` as `required` to `Post` entity — single-post endpoints do
  not return it; it must be `String? username` (nullable, optional)
- ❌ Do NOT skip running `build_runner` after editing the DTOs
