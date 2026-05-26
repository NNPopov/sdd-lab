# 0050 · user_details_edit_user_route_to_user_id — Outside-in test spec

## Goal

Prove that the combined user-details + edit-user verticals read and update a user
**by integer `user_id`** on the wire, and that the edit ownership guard is decided
**by id** — without merging the two slices and without touching the PATCH-body handle.

## Entry point

Two public Cubit surfaces, exercised in one test file (the two slices share this
single acceptance gate per ADR-0001):

- `userDetailsCubit.load(42)`
- `editUserCubit.loadInitial(42)` and `editUserCubit.submit(UserUpdate(username: 'alice2'))`

## Wired real (production code in the test)

- `GetUserAdapter` → `GetUserPort` → `GetUserUseCase` → `UserDetailsCubit` (user-details vertical).
- `GetUserForEditAdapter` → `GetUserForEditPort` → `GetUserForEditUseCase` (edit read path).
- `UpdateUserAdapter` → `UpdateUserPort` → `UpdateUserUseCase` (edit write path).
- `EditUserCubit` (the system under test for the edit vertical).
- The real `User` / `UserUpdate` domain entities and `UserDto` mapping.

## Mocked (system boundaries only)

- **`UsersApiClient`**: the slice's network boundary. `getUser(int)` returns the
  `alice` fixture DTO (id 42, username `alice`); `updateUser(int, body)` returns
  normally (void, 200). A mock `AppLogger` is supplied to the adapters.
- **`AuthCubit`**: `currentUser` returns the `alice` fixture with `id == 42` (so
  `isMe(42)` is true, `isMe(99)` is false). `isMe(int)` is the real implementation
  delegating to `currentUser?.id`.

## Test scenarios

### Scenario 1: read, edit-read, and update all target the integer id

**Setup:**
- `UsersApiClient.getUser(42)` returns the `alice` DTO (id 42, username `alice`).
- `UsersApiClient.updateUser(42, any)` completes successfully (no body).
- `AuthCubit.currentUser` is `alice` with id 42.

**Act:**
- `userDetailsCubit.load(42)`
- `editUserCubit.loadInitial(42)`
- `editUserCubit.submit(const UserUpdate(username: 'alice2'))`

**Expect:**
- States from `UserDetailsCubit`: `[UserDetailsLoading, UserDetailsLoaded(alice)]`.
- States from `EditUserCubit`:
  `[EditUserLoadingInitialData, EditUserLoaded(alice), EditUserSubmitting(alice), EditUserSuccess(alice2)]`.
- Mocks verified:
  - `UsersApiClient.getUser(42)` called with the **integer** `42` (twice — details and edit-read).
  - `UsersApiClient.updateUser(42, body)` called once, where `body.username == 'alice2'`
    (the new **handle** survives unchanged in the PATCH body) and the path identity is `42`.

### Scenario 2: edit ownership is rejected by id, not by handle

**Setup:**
- `AuthCubit.currentUser` is `alice` with id 42.
- `UsersApiClient.getUser` is stubbed but expected **not** to be called.

**Act:**
- `editUserCubit.loadInitial(99)` (a different user's id).

**Expect:**
- States from `EditUserCubit`: `[EditUserLoadingInitialData, EditUserLoadError(ForbiddenFailure)]`.
- Side effects: no read is attempted — `UsersApiClient.getUser` is never called.

## Out of scope for this test

- Widget rendering, route path parsing, and `@PathParam` binding (covered by widget
  and routing tests separately).
- Navigation call-site changes in `users_screen.dart` and `app_shell_screen.dart`
  (covered by the routing/navigation widget tests).
- The pre-existing owner-only outside-in test in
  `test/features/users/0038_owner_only_user_edit/` is updated separately to express
  ownership by id; it is not re-authored here.
- Full `getUser`/`updateUser` failure-code mapping (covered by adapter unit tests).
