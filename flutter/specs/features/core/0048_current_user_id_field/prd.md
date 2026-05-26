# PRD — 0048 current_user_id_field

**Feature:** core/auth
**Status:** 📋 needs-triage
**Part of:** `{username}` → `{user_id}` API migration (foundation slice)

## Problem Statement

As a logged-in user, the app knows my `username` but not my numeric `id`. The backend
has moved every user-targeting URL from `/user/{username}` to `/user/{user_id}`, so the
client now needs *my* integer id to act on my own account (view my profile, edit me,
decide "is this me?"). The id is already returned by `GET /user/me/` and deserialized
into the DTO — but it is silently dropped when the DTO is converted to the domain
`CurrentUser`, so it is unavailable anywhere in the app.

## Solution

Carry the user's numeric `id` through to the domain. `CurrentUser` gains a required
`id` field, and the DTO→domain mapping stops dropping the `id` it already receives. This
is the additive foundation for the rest of the migration: later slices use
`CurrentUser.id` for `isMe`, for ownership checks, and for navigating to "my" routes by
id. This slice adds the field only — it changes no behavior and no UI.

Per `CONTEXT.md`, `id` is a **path-identity** value (it identifies *which* user a request
targets). The existing `username` on `CurrentUser` is a **handle** and is left untouched.

## User Stories

1. As a logged-in user, I want my numeric id available in the app's auth state, so that
   the app can address my own account on the new id-based API routes.
2. As a logged-in user, I want my id populated automatically from `GET /user/me/`, so
   that no extra request is needed to learn it.
3. As a developer, I want `CurrentUser` to expose `id` as a required field, so that no
   code path can accidentally operate on a current user without an id.
4. As a developer, I want `id` included in `CurrentUser` equality and hashCode, so that
   two current-user values that differ only by id are correctly treated as different.
5. As a developer, I want the DTO→domain mapping to map the already-received `id`, so
   that the value the server sends is no longer discarded.
6. As a developer, I want my existing `username` handle on `CurrentUser` untouched, so
   that login, `@username` display, and self-rename keep working.
7. As a maintainer, I want every existing `CurrentUser(...)` construction updated to
   supply an `id`, so that the test suite compiles and stays green after the field
   becomes required.

## Implementation Decisions

- **Module: `CurrentUser` entity (core/auth domain).** Add `final int id` as a required
  constructor parameter. Include `id` in both `operator ==` and `hashCode`. No other
  fields change; `username` (handle) stays.
- **Module: `CurrentUser` DTO→domain mapping (core/auth data).** The DTO already
  deserializes `id: int` from the API; the mapping currently omits it. Map `id` into the
  domain entity. No DTO shape change, so no code generation is required.
- **`AuthSession` is unchanged.** The login response returns only the access token; `id`
  flows in via `CurrentUser` from `GET /user/me/`.
- **Required, not optional.** `id` is mandatory because every authenticated user has one;
  an optional/defaulted id would model an impossible state.
- **Downstream construction fallout is in scope.** Making `id` required breaks every
  existing `CurrentUser(...)` construction. In production code there is exactly one such
  site — the DTO mapping being edited here. In tests there are ~33 sites across many
  slices; all are updated mechanically to pass an `id`. This is part of this slice's work,
  not a separate task.
- **No behavior change.** This slice introduces the field and its mapping only. It does
  not touch `isMe`, navigation, route path segments, or any adapter/port signature.

## Testing Decisions

A good test here asserts externally observable behavior of the two modules, not their
internals: that the entity treats `id` as part of identity, and that the mapping carries
the server's `id` through.

- **`CurrentUser` entity (unit):** two `CurrentUser` values identical except for `id` are
  unequal (and have different hashCodes); identical values including `id` are equal.
- **DTO→domain mapping (unit):** `toDomain()` on a DTO carrying a known `id` produces a
  `CurrentUser` whose `id` matches, while the handle (`username`) and other fields are
  unaffected.
- **Downstream re-green:** update the ~33 existing `CurrentUser(...)` constructions to
  include `id`; the existing suites must stay green (this is the slice's acceptance proof
  that the change is non-breaking in behavior).
- **Layers that do not apply:** there is no new use-case, cubit transition, or screen
  state in this slice, so the use-case/bloc/widget layers of the default coverage have no
  new behavior to cover here. They are exercised by later migration slices (0050+), not
  waived in general.
- **Prior art:** `test/features/tiers/0047_delete_tier_id_contract/` for the shape of an
  id-contract migration test; existing `test/core/auth/application/auth_cubit_test.dart`
  for constructing `CurrentUser` and exercising `GET /me`.

## Out of Scope

- `AuthCubit.isMe(String)` → `isMe(int)` — slice 0050.
- `app_shell` "my profile / my posts" navigation by id — slice 0050.
- Any route path-segment, `@PathParam`, port, or adapter signature change.
- All Users and Posts route migrations.
- Any change to the `username` handle (display, login, self-rename) or to `AuthSession`.

## Further Notes

- This is the first slice of the `{username}` → `{user_id}` migration and unblocks the
  rest; it is deliberately the cheapest, fully-additive piece.
- The ~33-site test-construction fallout is useful signal for the migration's
  reassessment gate: it measures the downstream cost of a foundational entity change
  before committing to slice-by-slice vs. one batched refactor for the remaining routes.
- See `docs/adr/0001-merge-user-details-and-edit-user-route-migration.md` for why slices
  `user_details` and `edit_user` are later migrated together.
