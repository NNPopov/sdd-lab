# 0029 · adapt_paginated_users_contract — Validation Checklist

## Manual testing

| # | Step | Expected result |
|---|---|---|
| M1 | Launch the app and navigate to the Users list tab. | The users list loads without a crash or empty screen; user items are visible. |
| M2 | Scroll to the bottom of the users list while more pages exist. | A loading indicator appears at the bottom; the next page of users loads and is appended to the list. |
| M3 | Continue scrolling until all users have been loaded (last page). | The load-more indicator disappears and no further network request is triggered on additional scrolls. |
| M4 | On the last page, confirm the total number of visible users matches the server's `total_count`. | All users are present; no duplicates; no missing entries. |
| M5 | Pull down on the users list to trigger refresh. | The list reloads from page 1; previously loaded pages beyond page 1 are replaced by the fresh first page. |
| M6 | Pull to refresh on the last page of results. | The list returns to page 1 with the load-more indicator visible again if more pages exist. |
| M7 | With airplane mode enabled, navigate to the Users list. | The error state is shown with a retry button; no crash occurs. |
| M8 | On the error screen, re-enable the network and tap the retry button. | The users list loads successfully. |
| M9 | Load the first page (20 items), then load exactly one more page so `page=2` and `totalCount=40` (exactly full last page). | After the second load, no load-more indicator appears — `hasMore` is correctly `false` when `page * itemsPerPage == totalCount`. |
| M10 | Load a page where `totalCount` is not a multiple of `itemsPerPage` (partial last page). | The load-more indicator appears until the partial page is loaded; after loading it, the indicator disappears. |

## Code review

- [ ] `PaginatedUsersDto` has an `items` field (JSON key `items`), not `data`
- [ ] `PaginatedUsersDto` has no `has_more` / `hasMore` field
- [ ] All four fields of `PaginatedUsersDto` (`items`, `totalCount`, `page`, `itemsPerPage`) are declared `required`
- [ ] `PaginatedUsers.hasMore` is a computed getter `bool get hasMore => page * itemsPerPage < totalCount;`, not a constructor parameter
- [ ] `PaginatedUsers` constructor no longer accepts a `hasMore` parameter
- [ ] `ListUsersAdapter` maps `dto.items` (not `dto.data`) to the users list
- [ ] `ListUsersAdapter` does not pass `hasMore` to the `PaginatedUsers(...)` constructor
- [ ] `ListUsersAdapter` contains the double-catch pattern: inner `on DioException` and outer `catch (e, st)` with `_logger.error(...)`
- [ ] `UsersListCubit`, `UsersListState`, `GetUsersUseCase`, and `ListUsersPort` are **unchanged** in the diff
- [ ] No presentation layer files appear in the diff
- [ ] `PaginatedUsers` imports no `package:flutter/` or `package:dio/` symbols
- [ ] Adapter test has a success case asserting `hasMore == true` when `page * itemsPerPage < totalCount`
- [ ] Adapter test has a success case asserting `hasMore == false` when `page * itemsPerPage >= totalCount`
- [ ] Adapter test has a case for unexpected exception → `Left(UnknownFailure)` with `AppLogger.error` called
- [ ] Cubit test `_page()` helper accepts `totalCount` instead of `hasMore`, and all call sites pass numeric `totalCount` values
- [ ] No other slice under `lib/features/users/` appears in the diff
- [ ] `dart run build_runner build --delete-conflicting-outputs` — no errors
- [ ] `dart run slang` — no errors
- [ ] `dart analyze` — no warnings
- [ ] All tests green
