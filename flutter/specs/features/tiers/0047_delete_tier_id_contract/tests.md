# 0047 · delete_tier_id_contract — Outside-in test spec

## Goal

Prove that `DeleteTierCubit.confirmAndDelete(int tierId)` sends `DELETE /tier/{id}`
with an integer id and transitions the cubit through the correct state sequence for
both a successful deletion and a 404 (not-found) response.

## Entry point

`cubit.confirmAndDelete(1)`

The integer `1` is the tier id passed directly to the cubit. The test bypasses the
confirmation dialog (a widget concern) and calls the deletion method directly.

## Wired real (production code in the test)

- `DeleteTierAdapter` (implements `DeleteTierPort` via injectable binding)
- `DeleteTierUseCase` (receives the adapter-bound port)
- `DeleteTierCubit` (the system under test; receives the use-case and a mocked `AuthCubit`)

`TiersApiClient` is constructed with the mocked Dio instance, so it participates as
real retrofit-generated code — only the underlying HTTP transport is mocked.

## Mocked (system boundaries only)

- **Dio**: configured via `HttpClientAdapter` (or `DioAdapter` from the
  `dio_test`/`http_mock_adapter` helper) to intercept requests at the transport level.
- **AuthCubit**: `currentUser` returns a `CurrentUser` fixture with `isSuperuser: true`
  for the happy-path scenario and `isSuperuser: false` for the permission-denied scenario.

---

## Test scenarios

### Scenario 1: successful deletion returns success state

**Setup:**
- `AuthCubit.currentUser` returns `CurrentUser(username: 'admin', isSuperuser: true,
  isModerator: false, name: 'Admin', email: 'admin@example.com')`.
- Dio mock intercepts `DELETE /tier/1` and responds with HTTP 204 (no body).

**Act:**
- `cubit.confirmAndDelete(1)`

**Expect:**
- States emitted by the cubit: `[DeleteTierDeleting(), DeleteTierSuccess()]`
- Mocks verified: Dio received exactly one `DELETE` request; the URL path ends with
  `/tier/1` (integer, not a string name like `/tier/Free`).

---

### Scenario 2: 404 response transitions cubit to notFound state

**Setup:**
- `AuthCubit.currentUser` returns `CurrentUser(username: 'admin', isSuperuser: true,
  isModerator: false, name: 'Admin', email: 'admin@example.com')`.
- Dio mock intercepts `DELETE /tier/1` and responds with HTTP 404.

**Act:**
- `cubit.confirmAndDelete(1)`

**Expect:**
- States emitted by the cubit: `[DeleteTierDeleting(), DeleteTierNotFound()]`
- Mocks verified: Dio received exactly one `DELETE` request to `/tier/1`.

---

## Out of scope for this test

- Widget rendering, confirmation dialog behaviour, and snackbar display (covered by
  widget tests written after the outside-in test is green).
- Route navigation on success/notFound (covered by widget tests).
- The `requestConfirmation()` and `cancel()` cubit methods (covered by cubit unit
  tests; they do not involve the network).
- 401, 403, and unexpected-exception paths (covered by adapter unit tests).
- The permission-guard short-circuit when `isSuperuser` is false (covered by the
  use-case unit test in `delete_tier_usecase_test.dart`).
