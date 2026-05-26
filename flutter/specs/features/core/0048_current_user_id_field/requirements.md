# 0048 · current_user_id_field — Requirements

## Functional Requirements

| ID | Requirement |
|---|---|
| F1 | The `CurrentUser` domain entity exposes the user's numeric `id` as a required field. |
| F2 | After `GET /user/me/`, the resulting `CurrentUser.id` equals the `id` the server returned. |
| F3 | The `id` is populated automatically from `GET /user/me/`, requiring no additional request. |
| F4 | Two `CurrentUser` values identical except for `id` are not equal. |
| F5 | Two `CurrentUser` values identical except for `id` have different hash codes. |
| F6 | Two `CurrentUser` values identical including `id` are equal and have the same hash code. |
| F7 | Converting a `CurrentUserDto` to domain carries the `username` handle and all other fields through unchanged, alongside the newly mapped `id`. |

## Non-functional Requirements

| ID | Requirement |
|---|---|
| N1 | `id` is a non-nullable `int` with no default value, so a current user without an `id` is unrepresentable. |
| N2 | `id` is included in both `CurrentUser.operator ==` and `CurrentUser.hashCode`. |
| N3 | `CurrentUser` remains a hand-written immutable `final class` annotated `@immutable`; it is not converted to `freezed`. |
| N4 | `CurrentUser` (in `domain/`) imports nothing from `package:flutter/*`, `package:dio/*`, or any package outside `dartz`/`freezed`/`meta`/pure Dart. |
| N5 | The `CurrentUserDto` shape, its JSON keys, and its generated code are unchanged; no `build_runner` run is required or performed. |
| N6 | `AuthSession`, the login flow, and the token response are unchanged. |
| N7 | No route path segment, `@PathParam`, domain port, or adapter signature is changed by this slice. |
| N8 | The `username` handle on `CurrentUser` is left untouched (login, `@username` display, and self-rename continue to work). |
| N9 | The only production files changed are `core/auth` entity `current_user.dart` and DTO mapping `current_user_dto.dart`; no feature-slice production code changes. |
| N10 | Every existing `CurrentUser(...)` construction across the test suite is updated to supply an `id`, and the suite shows zero new failures relative to the `dev` baseline. |
| N11 | `dart format .` produces no diff and `dart analyze` produces no warnings after the change. |

## Out of scope

- No change to `AuthCubit.isMe(String)` (becomes `isMe(int)` in slice 0050).
- No `app_shell` "my profile / my posts" navigation by id (slice 0050).
- No route path-segment, `@PathParam`, port, or adapter signature change.
- No Users or Posts route migration.
- No change to the `username` handle (display, login, self-rename) or to `AuthSession`.
