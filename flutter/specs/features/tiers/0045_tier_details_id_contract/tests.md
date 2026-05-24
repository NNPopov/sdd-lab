# 0045 · tier_details_id_contract — Outside-in test spec

## Goal

Prove that `TierDetailsCubit.load(int id)` wires through the real adapter and
use-case, hits the network with `GET /tier/{id}` using the numeric id, and
emits the correct state sequence for both a successful response and a 404.

## Entry point

`cubit.load(3)`

## Wired real (production code in the test)

- `GetTierAdapter` — implements `GetTierPort`, makes the HTTP call via `TiersApiClient`
- `GetTierPort` — bound to `GetTierAdapter` (wired manually in test setup, not via DI)
- `GetTierUsecase` — receives `GetTierPort` and `PermissionCubit`, enforces permission guard
- `TierDetailsCubit` — system under test, receives `GetTierUsecase`

## Mocked (system boundaries only)

- **Dio**: returns a configurable response for `GET /tier/3`.
- **PermissionCubit**: `has(Permission.manageTiers)` returns `true` for the happy path
  and `true` for the not-found path (permission is granted; the 404 comes from the
  network, not from the permission guard).

## Test scenarios

### Scenario 1: load by id — server returns tier detail

**Setup:**
- `PermissionCubit.has(Permission.manageTiers)` returns `true`.
- Dio returns status 200 for `GET /tier/3` with body:
  `{"id": 3, "name": "Free", "created_at": "2026-04-25T00:00:00.000Z"}`.

**Act:**
- `cubit.load(3)`

**Expect:**
- States emitted: `[TierDetailsLoading, TierDetailsLoaded(tier: TierDetail(id: 3, name: 'Free', createdAt: DateTime(2026, 4, 25)))]`
- Mocks verified: Dio called exactly once with `GET /tier/3`.

---

### Scenario 2: load by id — server returns 404

**Setup:**
- `PermissionCubit.has(Permission.manageTiers)` returns `true`.
- Dio returns status 404 for `GET /tier/3`.

**Act:**
- `cubit.load(3)`

**Expect:**
- States emitted: `[TierDetailsLoading, TierDetailsError(failure: NotFoundFailure)]`
- Mocks verified: Dio called exactly once with `GET /tier/3`.

---

## Out of scope for this test

- Widget rendering and AppBar title switching (covered by widget tests separately).
- Route navigation and URL structure (covered by widget/integration tests).
- Permission-denied short-circuit (covered by the use-case unit test).
- Retry flow (covered by the cubit unit test; it delegates to `load`).
- 401, 403, and unexpected-exception failure paths (covered by the adapter unit test).
