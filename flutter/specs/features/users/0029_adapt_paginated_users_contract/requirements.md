# 0029 · adapt_paginated_users_contract — Requirements

## Functional Requirements

| ID | Requirement |
|---|---|
| F1 | The system correctly deserializes the `GET /users` response using `items` as the list field name. |
| F2 | The system determines whether more pages are available by computing `page * itemsPerPage < totalCount`, without relying on a `has_more` field from the server. |
| F3 | `hasMore` is `false` when `page * itemsPerPage >= totalCount` (last page reached or list empty). |
| F4 | `hasMore` is `true` when `page * itemsPerPage < totalCount` (more pages exist). |
| F5 | The users list loads and displays correctly after the contract change — no crash and no empty screen caused by deserialization failure. |
| F6 | Infinite scroll continues to load the next page and append users to the list when `hasMore` is `true`. |
| F7 | Pull-to-refresh continues to reload the users list from page 1. |
| F8 | The load-more indicator is not shown when `hasMore` is `false`. |
| F9 | The error state is shown when the network request fails, with a retry option. |

## Non-functional Requirements

| ID | Requirement |
|---|---|
| N1 | `PaginatedUsersDto` is a Freezed sealed class with an `items` field (JSON key `items`) and no `has_more` field. |
| N2 | All fields of `PaginatedUsersDto` are `required` — each field is necessary for the entity to be semantically meaningful. |
| N3 | `PaginatedUsers.hasMore` is a computed getter derived from `page`, `itemsPerPage`, and `totalCount`; it is not a stored constructor parameter. |
| N4 | `ListUsersAdapter` follows the mandatory double-catch pattern: inner `on DioException`, outer `catch (e, st)` with `AppLogger.error` logging per `agent_docs/error_handling.md`. |
| N5 | `UsersListCubit`, `UsersListState`, `GetUsersUseCase`, and `ListUsersPort` are not modified. |
| N6 | No presentation layer files are modified. |
| N7 | The `PaginatedUsers` domain entity imports nothing from `package:flutter/`, `package:dio/`, or any package outside `dartz`/`freezed`/pure Dart. |
| N8 | After modifying `PaginatedUsersDto`, code generation is re-run via `build_runner` to regenerate the Freezed and `json_serializable` files before any tests are executed. |
| N9 | The adapter test covers: success with `hasMore = true`, success with `hasMore = false` (last page), and unexpected exception → `UnknownFailure` with `AppLogger.error` called. |
| N10 | Cubit tests continue to cover all existing state transitions; the `_page()` fixture helper controls `hasMore` through a `totalCount` parameter, not a boolean. |
| N11 | No other slice in the `users` feature is imported by or modified as part of this change. |

## Out of scope

- Changes to any other slice that consumes the users API (none exist).
- Changes to the `UserDto` per-item fields (unchanged in the new contract).
- UI changes, new features, or modifications to the pagination strategy.
- Changes to any other paginated DTO in the project (e.g. `PaginatedTierOptionsDto`).
