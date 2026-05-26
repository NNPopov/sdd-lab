# 0048 · current_user_id_field — Validation Checklist

> This slice is fully additive and has **no UI**. The manual scenarios are
> therefore runtime/regression observations (does anything visibly change? is
> `id` actually carried?), not screen interactions.

## Manual testing

| # | Step | Expected result |
|---|---|---|
| M1 | Launch the app and log in with valid credentials. | App reaches the authenticated home exactly as before — no new error, no behavior change. (F3) |
| M2 | While logged in, view a screen that shows your `@username` handle. | The handle renders unchanged; login and display behave exactly as before the change. (F7, N8) |
| M3 | Kill and relaunch the app with a stored session (bootstrap path through `GET /user/me/`). | App restores the authenticated state without error — mapping `id` does not break `/me` handling. (F2, F3) |
| M4 | After login, inspect the runtime auth state (debugger watch or a temporary `debugPrint` of `currentUser.id`). | `currentUser.id` equals the numeric `id` the backend returns for that account. (F1, F2) |
| M5 | Log in as user A, log out, log in as user B (different account). | `currentUser.id` reflects B's id, not A's — the two authenticated states are distinct. (F4, F5) |

## Code review

- [ ] `CurrentUser` declares `final int id` as a `required` constructor parameter with no default — a current user without an `id` is unrepresentable (N1, F1).
- [ ] `id` appears in **both** `CurrentUser.operator ==` and `CurrentUser.hashCode` (N2, F4–F6).
- [ ] `CurrentUser` is still a hand-written `@immutable final class` — not converted to `freezed` (N3).
- [ ] `current_user.dart` imports only `package:meta` / pure Dart — nothing from `package:flutter/*` or `package:dio/*` (N4).
- [ ] `CurrentUserDtoX.toDomain()` adds `id: id` and changes nothing else; the DTO factory, JSON keys, and `*.g.dart`/`*.freezed.dart` are untouched (F7, N5).
- [ ] No `build_runner` output files changed in the diff — the change is not codegen-affecting (N5).
- [ ] `auth_session.dart`, the login flow in `auth_cubit.dart`, and the token response DTO are unchanged (N6).
- [ ] No route path segment, `@PathParam`, domain port, or adapter signature is changed (N7).
- [ ] The `username` handle on `CurrentUser` is unchanged (N8).
- [ ] The only production files in the diff are `core/auth/domain/entities/current_user.dart` and `core/auth/data/dto/current_user_dto.dart` — no feature-slice production code (N9).
- [ ] Every `CurrentUser(...)` construction in `test/` now passes an `id`; running the suite shows zero new failures versus the `dev` baseline (N10).
- [ ] `dart run build_runner build --delete-conflicting-outputs` — no errors
- [ ] `dart run slang` — no errors
- [ ] `dart analyze` — no warnings
- [ ] All tests green
