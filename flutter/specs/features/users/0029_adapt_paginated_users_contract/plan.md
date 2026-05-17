# Plan — 0029: Adapt Paginated Users Contract

## Header

Task: adapt the `list_users` slice to the new `GET /users` response shape.
The backend renamed the list field from `data` to `items` and removed `has_more`.
No visible behavior changes — pagination, infinite scroll, and pull-to-refresh
continue to work identically. The change is entirely within the data and domain layers.

---

## Context

### Read

- `CLAUDE.md` — universal rules
- `lib/features/users/_shared/data/dto/paginated_users_dto.dart` — DTO being changed
- `lib/features/users/list_users/domain/entities/paginated_users.dart` — entity being changed
- `lib/features/users/list_users/data/list_users_adapter.dart` — adapter being changed
- `lib/features/users/list_users/domain/ports/list_users_port.dart` — verify signature is unchanged
- `lib/features/users/list_users/domain/usecases/get_users_usecase.dart` — verify unchanged
- `lib/features/users/list_users/application/users_list_cubit.dart` — verify unchanged
- `lib/features/users/list_users/application/users_list_state.dart` — verify unchanged
- `test/features/users/list_users/data/list_users_adapter_test.dart` — being updated
- `test/features/users/list_users/application/users_list_cubit_test.dart` — being updated
- `agent_docs/error_handling.md` — DTO soft-contract rules and adapter template

### Do NOT read

- Any other slice under `lib/features/users/`
- Presentation layer files (screen, widgets, route) — unchanged
- `core/` — not involved
- Generated files (`*.freezed.dart`, `*.g.dart`) — will be regenerated

---

## API

```
GET /users?page={page}&items_per_page={per_page}
Header: Authorization: Bearer <token>

Response 200:
{
  "items": [
    {
      "id": 0,
      "name": "string",
      "username": "string",
      "email": "string",
      "profile_image_url": "string",
      "tier_id": 0
    }
  ],
  "total_count": 0,
  "page": 0,
  "items_per_page": 0
}
```

**Changes from the previous contract:**
- `data` (list field) → renamed to `items`
- `has_more` (boolean) → **removed**; `hasMore` must now be derived as
  `page * itemsPerPage < totalCount`

**Per-item object (`UserDto`):** unchanged.

---

## Files changed

```
lib/features/users/_shared/data/dto/
└── paginated_users_dto.dart          MODIFY — rename data→items, remove hasMore
    paginated_users_dto.freezed.dart  REGENERATE (build_runner)
    paginated_users_dto.g.dart        REGENERATE (build_runner)

lib/features/users/list_users/domain/entities/
└── paginated_users.dart              MODIFY — remove hasMore param, add computed getter

lib/features/users/list_users/data/
└── list_users_adapter.dart           MODIFY — remove hasMore from PaginatedUsers(...)

test/features/users/list_users/data/
└── list_users_adapter_test.dart      MODIFY — add success + hasMore=false test cases

test/features/users/list_users/application/
└── users_list_cubit_test.dart        MODIFY — update _page() helper, adjust call sites
```

**Unchanged (verify only, do not edit):**
- `list_users_port.dart`
- `get_users_usecase.dart`
- `users_list_cubit.dart`
- `users_list_state.dart`
- All presentation files
- `user_dto.dart` (per-item schema unchanged)

---

## What to do

### Step 1 — Update `PaginatedUsersDto`

File: `lib/features/users/_shared/data/dto/paginated_users_dto.dart`

- Rename the `data` field to `items`. The JSON key changes from `data` to `items`
  (add `@JsonKey(name: 'items')` or omit it — Dart field name `items` matches the
  JSON key `items` directly, so no annotation needed).
- Remove the `hasMore` field entirely (was `@JsonKey(name: 'has_more') required bool hasMore`).
- All remaining fields stay `required` — they are all semantically necessary for
  the entity to be meaningful (per `agent_docs/error_handling.md` soft-contract rules).
- After editing, run:
  ```
  dart run build_runner build --delete-conflicting-outputs
  ```
  to regenerate `paginated_users_dto.freezed.dart` and `paginated_users_dto.g.dart`.

### Step 2 — Update `PaginatedUsers` domain entity

File: `lib/features/users/list_users/domain/entities/paginated_users.dart`

- Remove `required this.hasMore` from the constructor and remove the
  `final bool hasMore` field.
- Add a computed getter:
  ```dart
  bool get hasMore => page * itemsPerPage < totalCount;
  ```
- No other changes. The entity is a plain Dart class (not Freezed), so no
  code generation is needed for this file.

**Formula verification (do not change):**
| Scenario | totalCount | page | itemsPerPage | result |
|---|---|---|---|---|
| Mid-pagination | 100 | 1 | 20 | `20 < 100` → `true` ✓ |
| Last page exactly full | 40 | 2 | 20 | `40 < 40` → `false` ✓ |
| Last page partial | 42 | 2 | 20 | `40 < 42` → `true` ✓ |
| Only page consumed | 10 | 1 | 10 | `10 < 10` → `false` ✓ |
| Empty list | 0 | 1 | 10 | `10 < 0` → `false` ✓ |

### Step 3 — Update `ListUsersAdapter`

File: `lib/features/users/list_users/data/list_users_adapter.dart`

- In the mapping block, change `dto.data` → `dto.items` for the user list.
- Remove the `hasMore: dto.hasMore` line from the `PaginatedUsers(...)` constructor
  call — the entity derives it automatically.
- The double-catch structure and `_logger` remain **unchanged**.

Result after step 3:
```dart
return Right(
  PaginatedUsers(
    users: dto.items.map((u) => u.toDomain()).toList(),
    totalCount: dto.totalCount,
    page: dto.page,
    itemsPerPage: dto.itemsPerPage,
  ),
);
```

### Step 4 — Update adapter test

File: `test/features/users/list_users/data/list_users_adapter_test.dart`

The existing test (unexpected exception → `UnknownFailure`) requires no change.

Add the following tests inside `group('ListUsersAdapter.call', ...)`:

**a) Success path — `hasMore = true`**

Arrange: `apiClient.getUsers(...)` returns a `PaginatedUsersDto` with
`items: [userDto]`, `totalCount: 100`, `page: 1`, `itemsPerPage: 20`.
Assert: result is `Right(PaginatedUsers)` where `hasMore == true`
(`1 * 20 < 100`).

**b) Success path — `hasMore = false` (last page)**

Arrange: `apiClient.getUsers(...)` returns `PaginatedUsersDto` with
`items: [userDto]`, `totalCount: 20`, `page: 1`, `itemsPerPage: 20`.
Assert: result is `Right(PaginatedUsers)` where `hasMore == false`
(`1 * 20 < 20` is false).

Use `PaginatedUsersDto(items: [...], totalCount: ..., page: ..., itemsPerPage: ...)` —
note: the DTO no longer accepts `hasMore`. Do not add it back.

### Step 5 — Update cubit test

File: `test/features/users/list_users/application/users_list_cubit_test.dart`

The `_page()` fixture helper currently constructs `PaginatedUsers` with a `hasMore`
boolean. Since `hasMore` is now a computed getter, the constructor no longer accepts it.

**Update the helper:**
- Remove the `bool hasMore = true` parameter.
- Add an `int totalCount = 100` parameter instead.
- Pass `totalCount: totalCount` to `PaginatedUsers(...)` and remove `hasMore: hasMore`.

```dart
PaginatedUsers _page(
  List<User> users, {
  int page = 1,
  int totalCount = 100,    // 1*20 < 100 = true → default hasMore=true
}) => PaginatedUsers(
  users: users,
  totalCount: totalCount,
  page: page,
  itemsPerPage: 20,
);
```

**Update call sites** — every `_page(...)` call that currently passes `hasMore: false`
must be changed to pass a `totalCount` that makes the formula yield `false`:

| Old call | New call | Formula check |
|---|---|---|
| `_page(_users2, page: 2, hasMore: false)` | `_page(_users2, page: 2, totalCount: 40)` | `2*20 < 40` → `false` ✓ |
| `_page(_users1, hasMore: false)` (refresh test) | `_page(_users1, totalCount: 20)` | `1*20 < 20` → `false` ✓ |

All other test assertions (`UsersListState.loaded(hasMore: ...)`) remain unchanged —
`hasMore` is still a field on the state, populated from `PaginatedUsers.hasMore`.

---

## Tests summary

| File | Action | Scenarios |
|---|---|---|
| `list_users_adapter_test.dart` | Add 2 tests | success `hasMore=true`; success `hasMore=false` (last page) |
| `users_list_cubit_test.dart` | Update fixture | `_page()` helper + 2 call-site updates; all existing scenarios stay valid |

No new test files. No changes to `get_users_usecase_test.dart`, presentation tests, or widget tests — those are unaffected.

---

## Report (expected at completion)

- List of files modified (5 production files, 2 test files, 2 generated files)
- Confirmation that no other slice was touched
- `dart format .` — no diff
- `dart analyze` — no warnings
- `build_runner` ran and generated files are up-to-date
- `flutter test test/features/users/list_users/` — all green

---

## What NOT to do

- ❌ Do NOT change `users_list_cubit.dart`, `users_list_state.dart`,
  `get_users_usecase.dart`, or `list_users_port.dart` — they have no dependency on the
  DTO shape and are fully correct as-is
- ❌ Do NOT add `hasMore` back as a constructor parameter anywhere — it is a computed
  getter from this point forward
- ❌ Do NOT change `user_dto.dart` — per-item fields are unchanged
- ❌ Do NOT touch any presentation files
- ❌ Do NOT change `PaginatedTierOptionsDto` or any other paginated DTO — out of scope
- ❌ Do NOT make `PaginatedUsersDto.items` nullable or give it a `@Default([])` —
  a response without items is semantically meaningless and should deserialize as an error
- ❌ Do NOT skip running `build_runner` after editing the DTO
