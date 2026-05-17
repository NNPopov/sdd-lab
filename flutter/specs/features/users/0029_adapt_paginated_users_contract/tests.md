# 0029 · adapt_paginated_users_contract — Outside-in test spec

## Goal

Prove that `UsersListCubit.load()` correctly parses the new `GET /users` response
shape (field `items`, no `has_more`) and derives `hasMore` from the numeric
pagination fields.

## Entry point

`cubit.load()`

Called once per scenario against a freshly constructed Cubit wired to real
production layers (Adapter → UseCase → Cubit), with Dio mocked at the network
boundary.

## Wired real (production code in the test)

- `ListUsersAdapter` (data layer — parses `PaginatedUsersDto`, maps to `PaginatedUsers`)
- `ListUsersPort` (bound to `ListUsersAdapter` — wired manually, no DI container needed)
- `GetUsersUseCase` (domain layer — receives the port)
- `UsersListCubit` (application layer — system under test)

## Mocked (system boundaries only)

- **Dio**: intercepted with `DioAdapter` (or equivalent mock HTTP handler); returns
  a pre-configured JSON body for `GET /users`.
- **AppLogger**: mock that records calls — needed only to verify it is NOT called
  on the success path.

---

## Test scenarios

### Scenario 1: first-page load — new contract parsed, `hasMore = true`

**Setup:**
- Dio returns `200` for `GET /users?page=1&items_per_page=20` with body:
  ```json
  {
    "items": [
      {
        "id": 1,
        "name": "Alice",
        "username": "alice",
        "email": "alice@example.com",
        "profile_image_url": null,
        "tier_id": null
      }
    ],
    "total_count": 100,
    "page": 1,
    "items_per_page": 20
  }
  ```

**Act:**
- `cubit.load()`

**Expect:**
- States emitted by the Cubit:
  `[UsersListLoading, UsersListLoaded(users: [User(id:1, name:'Alice', username:'alice', email:'alice@example.com')], page: 1, hasMore: true)]`
- `hasMore` is `true` because `1 * 20 < 100`.
- `AppLogger.error` is NOT called.
- No `Failure` is returned.

---

### Scenario 2: single-page load — `hasMore = false` when totalCount equals page × itemsPerPage

**Setup:**
- Dio returns `200` for `GET /users?page=1&items_per_page=20` with body:
  ```json
  {
    "items": [
      {
        "id": 1,
        "name": "Alice",
        "username": "alice",
        "email": "alice@example.com",
        "profile_image_url": null,
        "tier_id": null
      }
    ],
    "total_count": 20,
    "page": 1,
    "items_per_page": 20
  }
  ```

**Act:**
- `cubit.load()`

**Expect:**
- States emitted by the Cubit:
  `[UsersListLoading, UsersListLoaded(users: [User(id:1, ...)], page: 1, hasMore: false)]`
- `hasMore` is `false` because `1 * 20 < 20` is false (last page, exactly full).
- `AppLogger.error` is NOT called.

---

## Out of scope for this test

- Network failure paths (covered by `list_users_adapter_test.dart` unit tests).
- `loadMore()` and `refresh()` cubit flows (covered by `users_list_cubit_test.dart`
  unit tests).
- Widget rendering, load-more indicator visibility, pull-to-refresh gesture
  (covered by widget tests and manual M-scenarios in `validation.md`).
- `UserDto` field mapping (unchanged; covered by existing unit tests).
