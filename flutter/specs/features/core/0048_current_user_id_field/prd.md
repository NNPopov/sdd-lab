# PRD — 0048 · core/auth · current_user_id_field

> **Status:** 📋 Planned
> **Feature:** core/auth
> **Slice:** current_user_id_field
> **Part of:** `{username}` → `{user_id}` breaking-API migration (foundation slice; slices 0049–0061 depend on this one)

## Problem Statement

The backend has shipped a breaking change: every API route that used a `{username}`
string in the URL now requires the integer `user_id`. Old username-based URLs return
422/404 with no redirect.

On the client, the only stable, server-issued identifier for the logged-in user is the
integer `id` returned by `GET /user/me/`. Today that `id` never reaches the domain: the
`CurrentUserDto` deserializes it from JSON but `toDomain()` drops it, so `CurrentUser`
has no `id`. As a result, anywhere the app needs to answer "is this entity mine?" or
"what is my user_id for this request?", it can only fall back to the `username` string —
which is precisely the value the backend is removing.

Until the logged-in user carries a numeric `id` end-to-end, none of the per-route
migration slices (users and posts) can correctly issue `user_id`-based requests for the
current user or correctly hide owner-only UI.

## Solution

Carry the user's numeric `id` all the way into the domain and make identity comparisons
numeric:

- `CurrentUser` gains a required `int id`.
- `CurrentUserDto.toDomain()` maps the `id` it already receives from the API.
- `AuthCubit.isMe(...)` compares by numeric `id` instead of by `username`.

After this slice, every downstream slice can ask `AuthCubit` for the current user's
numeric `id` and compare ownership numerically, unblocking the route migrations.

## User Stories

1. As a logged-in user, I want the app to know my numeric account id after I sign in, so that screens can request my data using the new `user_id` API contract.
2. As a logged-in user, I want the app to correctly recognize content and screens that belong to me, so that owner-only actions (edit/delete) appear only on my own resources.
3. As a developer building a route-migration slice, I want `CurrentUser.id` available from `AuthCubit`, so that I can pass `userId` to ports without reading the soon-to-be-removed `username`.
4. As a developer, I want `isMe` to take an `int userId`, so that callers pass the same identifier the backend now expects and ownership checks cannot silently diverge from the API contract.
5. As a developer, I want `CurrentUser` equality to account for `id`, so that two users that differ only by id are not treated as equal in state comparisons and widget rebuilds.
6. As a maintainer, I want the `id` the API already returns to stop being dropped at the DTO boundary, so that we remove a latent data-loss bug rather than working around it.
7. As a user whose `/user/me/` succeeds, I want my session to reflect my full identity including id, so that subsequent authenticated requests are correctly attributed to me.

## Implementation Decisions

- **Modules modified**
  - `CurrentUser` entity (domain): add a required `int id`; include `id` in `==` and `hashCode`.
  - `CurrentUserDto → CurrentUser` mapping (`toDomain()`): map the existing `id` field. The DTO field already exists and is deserialized; only the mapping is missing.
  - `AuthCubit` (application): change the public identity check from `isMe(String username)` to `isMe(int userId)`, comparing `currentUser?.id == userId`.
- **AuthSession is unchanged.** The login response returns only `accessToken`; user identity (including `id`) flows exclusively via `CurrentUser` populated by `GET /user/me/`. No change to the `AuthSession` entity.
- **`id` is required, not nullable.** `GET /user/me/` always returns it for an authenticated user; a missing id is a contract violation, not a normal state.
- **No API contract change in this slice.** This slice only stops discarding a field already present in the `/user/me/` response and changes an in-app comparison. The route path migrations live in the downstream slices.
- **Call-site updates to `isMe`** are limited to retargeting existing callers from a username string to the numeric id now available on `CurrentUser`/`User`. Widespread `:username`→`:user_id` route work is explicitly deferred to slice 0061.

## Testing Decisions

- **What makes a good test here:** assert externally observable behavior — that a deserialized `/user/me/` payload yields a `CurrentUser` whose `id` equals the JSON `id`, and that `isMe` returns true/false purely as a function of the numeric id — not the internal shape of the entity.
- **Modules to test (default four-layer policy, adapted to a core slice):**
  - **DTO mapping** — given a representative `/user/me/` JSON, `toDomain()` produces a `CurrentUser` with the expected `id` (and all previously-mapped fields preserved). Prior art: existing DTO `toDomain` tests under `test/core/auth/`.
  - **AuthCubit.isMe** — `bloc_test`/unit coverage: returns `true` when the authenticated user's `id` matches the argument, `false` when it differs, and `false` when there is no authenticated user. Prior art: existing `AuthCubit` tests.
  - **Entity equality** — two `CurrentUser` values differing only by `id` are not equal; identical values are equal and share a hash code.
- No adapter/network failure-code matrix applies — this slice adds no new network call.

## Out of Scope

- Any URL/route path change (`:username` → `:user_id`) and route-page `@PathParam` retyping — slice 0061 (core/routing).
- Port/adapter/API-client signature changes for users and posts features — slices 0049–0060.
- `GET /user/{username}/rate_limits` — not implemented in Flutter; skipped entirely per handoff.
- Any change to `AuthSession` or the login flow.
- `build_runner` regeneration concerns (no codegen-affecting public route signatures change here beyond freezed for the DTO, which is already generated).

## Further Notes

- Source of decisions: `handoff_username_to_userid_migration.md` (decisions 1, 2, 5).
- This is the **foundation** of a 14-slice migration (0048–0061). It must land first; the
  remaining slices assume `CurrentUser.id` and the numeric `isMe` already exist.
- The `User` entity (`lib/features/users/_shared/domain/entities/user.dart`) already has
  `id: int`, so self-vs-other comparisons only need the `CurrentUser` side, which this
  slice supplies.
