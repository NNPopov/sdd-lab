# PRD — 0029: Adapt Paginated Users Contract

## Problem Statement

The backend `GET /users` endpoint has changed its response shape. The list field was
renamed from `data` to `items`, and the boolean `has_more` field was removed. The
client currently parses the old shape, so every users list request will fail to
deserialize — crashing the list screen for all users.

## Solution

Update the data-layer DTO to match the new contract (`items` field, no `has_more`),
and derive `hasMore` as a computed property on the domain entity from the three
numeric fields that are still present: `total_count`, `page`, and `items_per_page`.
No change to visible behavior — pagination, infinite scroll, and pull-to-refresh
continue to work identically.

## User Stories

1. As a user of the app, I want the users list to load correctly after the backend
   upgrade, so that I can browse users without seeing a crash or empty screen.
2. As a user of the app, I want infinite scroll to continue working on the users list,
   so that I can load more users by scrolling to the bottom.
3. As a user of the app, I want pull-to-refresh to continue working on the users list,
   so that I can get the latest user data without restarting the app.
4. As a user of the app, I want the "no more results" state to be detected correctly,
   so that the load-more indicator disappears when I have seen all users.
5. As a developer, I want the `hasMore` flag to be derived from authoritative numeric
   fields, so that it cannot be out of sync with the actual pagination state.
6. As a developer, I want the domain entity to be self-consistent, so that any
   consumer of `PaginatedUsers` can trust `hasMore` without knowing the DTO shape.

## Implementation Decisions

### Modules modified

- **Paginated Users DTO** — the JSON contract boundary between the network and the
  application. Field `data` renamed to `items`; field `has_more` removed entirely.
  Generated serialization code must be regenerated after the change.

- **`PaginatedUsers` domain entity** — replaces the stored `hasMore: bool`
  constructor parameter with a computed getter:
  `hasMore = page * itemsPerPage < totalCount`.
  This makes the entity self-consistent: `hasMore` is always in agreement with the
  numeric pagination fields and cannot be supplied incorrectly by an adapter.

- **`ListUsersAdapter`** — the mapping from DTO to domain entity. The `hasMore`
  field is simply removed from the constructor call; the entity derives it
  automatically.

### Derivation formula

`hasMore = page * itemsPerPage < totalCount`

Verified against edge cases:
- Last page exactly full (`totalCount = 40`, `page = 2`, `itemsPerPage = 20`):
  `40 < 40 → false` ✓
- Last page partially full (`totalCount = 42`, `page = 2`, `itemsPerPage = 20`):
  `40 < 42 → true` ✓ (one more page needed)
- Only page, fully consumed (`totalCount = 10`, `page = 1`, `itemsPerPage = 10`):
  `10 < 10 → false` ✓
- Empty list (`totalCount = 0`): `10 < 0 → false` ✓

### No behavioral changes

- `UsersListCubit`, `UsersListState`, `GetUsersUseCase`, `ListUsersPort`, and
  all presentation widgets are **unchanged**.
- The `hasMore` boolean on `UsersListState.loaded` continues to exist and is
  populated from `PaginatedUsers.hasMore` exactly as before.

### Code generation

After changing the DTO, `dart run build_runner build --delete-conflicting-outputs`
must be run to regenerate the Freezed and `json_serializable` files.

## Testing Decisions

**What makes a good test here:** tests verify the external behavior of a module —
inputs in, outputs out — without asserting on internal implementation details such
as intermediate variable names or private method calls.

### Adapter unit test (`list_users_adapter_test.dart`)

- Existing test (unexpected exception → `UnknownFailure`) requires no change.
- Add a **success path** test: given an API response with `items` and numeric
  pagination fields, the adapter returns a `Right(PaginatedUsers)` with correctly
  computed `hasMore`.
- Add a **`hasMore = false`** case: last-page response where
  `page * itemsPerPage >= totalCount` → `hasMore` is false.

Prior art: existing adapter tests in `test/features/users/list_users/data/`.

### Cubit unit test (`users_list_cubit_test.dart`)

- The `_page()` test-fixture helper currently accepts a `hasMore` boolean and passes
  it to the `PaginatedUsers` constructor. That parameter no longer exists.
- Update `_page()` to accept a `totalCount` integer instead, defaulting to a value
  that yields `hasMore = true` for the default page/pageSize. Adjust each call site
  so the computed getter returns the intended boolean for each test scenario.
- All existing cubit state-transition scenarios remain valid and must continue to pass.

Prior art: `bloc_test` patterns in `test/features/users/list_users/application/`.

## Out of Scope

- Changes to any other slice that calls `GET /users` (there are none — only
  `list_users` consumes `PaginatedUsersDto`).
- Changes to the `UserDto` fields (the per-item schema is unchanged).
- UI changes, new features, or pagination strategy changes.
- Changes to any other paginated DTO in the project (e.g. `PaginatedTierOptionsDto`).

## Further Notes

The `PaginatedUsers` entity is a plain Dart class (not Freezed). Adding a computed
getter requires no code generation. Only the DTO layer triggers `build_runner`.
