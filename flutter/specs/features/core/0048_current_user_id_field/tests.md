# 0048 · current_user_id_field — Outside-in test spec

## Goal

Prove that the user's numeric `id` flows end-to-end — from a `GET /user/me/`
payload, through DTO deserialization and the `toDomain()` mapping, into the
domain `CurrentUser` exposed by `AuthCubit` — and that `id` participates in
`CurrentUser` identity. This is the slice's acceptance gate.

## Entry point

`authCubit.bootstrap()`

`bootstrap()` is the realistic, no-extra-request path: it reads a stored session
and calls `GET /user/me/`, which is exactly how `id` arrives in the app. The
behavior under test is observed on the resulting `AuthAuthenticated.currentUser`.

## Wired real (production code in the test)

- `CurrentUser` (the domain entity gaining the `id` field — its `==`/`hashCode`).
- `CurrentUserDto` + `CurrentUserDtoX.toDomain()` (the mapping under test).
- `AuthApiAdapter` (the slice's data adapter; calls `toDomain()`).
- `AuthCubit` (the system under test; surfaces `currentUser`).
- `TokenHolder` (real in-memory token store).
- `AuthState` (real sealed state).

## Mocked (system boundaries only)

- **`AuthApiClient`** (retrofit boundary over Dio): `getCurrentUser()` returns
  `CurrentUserDto.fromJson(meJson)`, where `meJson` is a `GET /user/me/`-shaped
  map including `"id": 42`, `"username": "ada"`, `"email": "ada@example.com"`,
  `"name": "Ada Lovelace"`, `"is_superuser": false`, `"is_moderator": false`.
- **`TokenStoragePort`**: `read()` returns a stored
  `AuthSession(accessToken: 'tok', username: 'ada')` so `bootstrap()` proceeds
  to call `/me`.
- **`AppLogger`**: stubbed; no error expected on the happy path.

## Test scenarios

### Scenario 1: id carried from `/user/me/` into the authenticated state

**Setup:**
- `TokenStoragePort.read()` → `AuthSession(accessToken: 'tok', username: 'ada')`.
- `AuthApiClient.getCurrentUser()` → `CurrentUserDto.fromJson(meJson)` with
  `"id": 42` and the handle `"username": "ada"`.

**Act:**
- `await authCubit.bootstrap()`

**Expect:**
- States emitted by the Cubit: `[AuthAuthenticated]` (one state).
- The emitted `AuthAuthenticated.currentUser` is non-null with:
  - `currentUser.id == 42` (the server's id, no longer dropped).
  - `currentUser.username == 'ada'` (the handle, carried through unchanged).
  - `currentUser.email == 'ada@example.com'`, `currentUser.name == 'Ada Lovelace'`.
- Mocks verified: `AuthApiClient.getCurrentUser()` called once; `AppLogger.error`
  never called.

### Scenario 2: `id` is part of `CurrentUser` identity

**Setup:**
- Same as Scenario 1; run `bootstrap()` to obtain the authenticated
  `currentUser` (id 42).

**Act:**
- Compare the authenticated `currentUser` against two hand-built values that
  share every field except as noted.

**Expect:**
- `currentUser != CurrentUser(id: 99, …same other fields…)` — values differing
  only by `id` are unequal, and their `hashCode`s differ.
- `currentUser == CurrentUser(id: 42, …same other fields…)` — values identical
  including `id` are equal, with equal `hashCode`.

## Out of scope for this test

- Widget rendering and route navigation (this slice has no UI; nothing to render).
- Login-path and `/me`-failure state transitions (covered by the existing
  `auth_cubit_test.dart` and adapter/entity unit tests written after green).
- `AuthCubit.isMe(...)` behavior (slice 0050).
- The mechanical re-green of existing `CurrentUser(...)` test constructions —
  proven by the full suite staying green, not by this single test.
