# PRD — Expose Moderator Flag (slice 0014)

**Parent PRD:** `specs/features/moderation/0012_moderation/prd.md`
**Depends on:** slice 0013 (`moderation_db_foundation`) — `User.is_moderator` column must exist.
**Slice:** `0014_expose_moderator_flag`
**Resource:** users
**Endpoints modified:** `GET /users/user/{username}`, `GET /users/me`

---

## Problem Statement

Slice 0013 added the `is_moderator` boolean column to the `User` table, but the
field is not surfaced through any API response. Frontends have no way to
determine whether the currently authenticated user holds moderator rights, nor
can profile pages render a moderator badge for any user. All downstream slices
that enforce or communicate moderator status on the client side are blocked until
this field appears in user response payloads.

## Solution

Add `is_moderator: bool` to the response bodies of the two user-identity
endpoints:

- `GET /users/user/{username}` — so that a profile page can display a moderator
  badge for any user.
- `GET /users/me` — so that the frontend knows whether the current session user
  has moderator rights and can enable or disable moderation UI accordingly.

The `list_users` endpoint (`GET /users`) intentionally does not expose
`is_moderator` — it serves a different purpose (user discovery) and the parent
PRD explicitly excludes it from this slice.

No new endpoints are introduced. No business logic changes. The slice is a
targeted schema and mapping addition to two existing slices.

## User Stories

1. As a frontend developer, I want the `GET /users/user/{username}` response to
   include an `is_moderator` flag, so that the profile page can display a
   moderator badge next to the user's name.
2. As an authenticated user, I want the `GET /users/me` response to include an
   `is_moderator` flag, so that the client application knows whether to render
   moderation-specific UI controls for my session.
3. As a non-moderator user, I want `is_moderator` to be `false` in both
   responses, so that the flag value is always present and never absent.
4. As a moderator user, I want `is_moderator` to be `true` in both responses,
   so that any frontend reading the field gets accurate data.
5. As a frontend developer, I want the `GET /users` (list users) response to
   omit the `is_moderator` flag, so that the field is scoped to identity-focused
   endpoints only and the list response stays compact.
6. As an API consumer, I want the `is_moderator` field to always be a boolean
   (never `null`), so that I can branch on it without null-checking.
7. As an unauthenticated user, I want `GET /users/user/{username}` to still
   return `is_moderator` without requiring me to log in, so that public profiles
   show the badge if applicable.

## Implementation Decisions

### Modules to modify

**`get_user_by_username` slice** (three touch-points, no new files):

- `FoundUser` domain entity — add `is_moderator: bool` field. This entity is
  the contract between the use-case and the adapter; it must carry the flag so
  the router can map it to the response schema.
- `GetUserByUsernameAdapter.get()` — map `row.is_moderator` from the ORM
  `User` row to the `FoundUser` entity. The adapter already fetches the full
  `User` row; no query changes are needed.
- `GetUserByUsernameResponse` presentation schema — add `is_moderator: bool`.
  The router must also pass the field when constructing this response object.

**`users/schemas.py`** (one touch-point):

- `UserMeRead` — add `is_moderator: bool`. `UserMeRead` inherits from `UserRead`
  and adds fields specific to the authenticated user's own view; `is_moderator`
  belongs here alongside the existing `is_superuser`.
- `UserRead` and all other schemas in this file remain unchanged. The parent
  PRD explicitly states that `list_users` must not expose `is_moderator`, and
  `UserRead` is the base for that response.

**No changes needed** to:

- `GetUserByUsernameUseCase` — the use-case only forwards the entity; no logic
  is added.
- `GetUserByUsernamePort` — the port return type is `FoundUser | None`; adding
  a field to `FoundUser` satisfies the contract without changing the protocol
  signature.
- `user_get_me.py` use-case — it returns `current_user` (the raw dict from
  `crud_users.get()`). Since `User.is_moderator` now exists in the ORM model,
  the dict already carries the value; FastAPI serializes it through `UserMeRead`
  automatically.
- `get_current_user` dependency — no changes; it returns the full user dict
  from `crud_users.get()`, which inherits the new column.

### No new files

This slice requires no new Python files, no new Alembic migration, and no
changes to the DI container or router registration. All modifications are within
existing files.

### `is_moderator` is always `bool`, never `None`

The ORM column has `default=False` and the DB column is non-nullable. No
nullable handling is needed in schemas or entities.

### `moderator_granted_by_user_id` is not exposed

The audit FK `moderator_granted_by_user_id` is internal infrastructure. It is
not included in any response schema in this or any future slice unless a
dedicated audit endpoint is introduced.

## Testing Decisions

Good tests verify observable behaviour through the public interface — what the
endpoint returns — not internal call sequences or field assignments.

### Use-case unit test (opted out)

The use-case logic is unchanged; it calls `self._port.get(query)` and raises
`NotFoundDomainError` if the result is `None`. No new branch is introduced.
The unit test for `GetUserByUsernameUseCase` already covers this logic and does
not need to change. A new test would duplicate the existing one without adding
coverage of new behaviour. This opt-out is valid per `agent_docs/testing.md`.

### Adapter unit test

Verify that `GetUserByUsernameAdapter.get()` correctly maps `row.is_moderator`
to `FoundUser.is_moderator`. Two cases:

- User with `is_moderator=False` (default): assert `FoundUser.is_moderator is False`.
- User with `is_moderator=True`: assert `FoundUser.is_moderator is True`.

Uses a real async session against the test Postgres database, following the
pattern in `tests/features/users/0001_create_user/`.

### Endpoint integration tests

`httpx.AsyncClient` against the running app with test Postgres.

**`GET /users/user/{username}`:**
- Happy path: create a non-moderator user, assert `is_moderator: false` in
  response body.
- Moderator path: create a user and set `is_moderator=True` in the DB, assert
  `is_moderator: true` in response body.
- Existing 404 path: unaffected, no change needed.

**`GET /users/me`:**
- Happy path: authenticate as a non-moderator user, assert `is_moderator: false`
  in response body.
- Moderator path: authenticate as a moderator user, assert `is_moderator: true`
  in response body.

Prior art: `tests/features/users/0004_get_user_by_username/`.

### Outside-in test (acceptance gate)

One end-to-end test covering the primary happy path:

1. Create a user (non-moderator).
2. Authenticate as that user.
3. Call `GET /users/user/{username}` — assert `is_moderator: false`.
4. Call `GET /users/me` — assert `is_moderator: false`.
5. Directly set `is_moderator=True` on the user row in the test DB (mimicking
   what slice 0015 will do).
6. Call `GET /users/user/{username}` again — assert `is_moderator: true`.
7. Call `GET /users/me` again — assert `is_moderator: true`.

The slice is not done until this test is green.

## Out of Scope

- Assigning or revoking the moderator role — that is slices 0015 and 0016.
- Exposing `is_moderator` on the `list_users` (`GET /users`) endpoint — parent
  PRD explicitly excludes it.
- Exposing `moderator_granted_by_user_id` in any response.
- A `get_current_moderator` auth dependency — that is introduced in the slices
  that need it (0017, 0019).
- Any changes to `UserRead` base class or `list_users` schemas.
- Caching changes — `get_user_by_username` is not currently cached; no
  invalidation logic is needed.

## Further Notes

- The outside-in test for slice 0004 (`get_user_by_username`) must remain green
  throughout. Adding `is_moderator` to the response is additive; if that test
  has a strict schema assertion, it may need to be updated to expect the new
  field.
- This slice is intentionally minimal. Its only purpose is to surface a DB
  column that already exists. All enforcement logic (who can be a moderator,
  what moderators can do) belongs to later slices.
- `UserMeRead` and `GetUserByUsernameResponse` are intentionally kept as separate
  schemas; do not merge them. `UserMeRead` is the serialization target for the
  `get_me` endpoint (which returns the raw user dict), while
  `GetUserByUsernameResponse` is constructed explicitly from a `FoundUser`
  entity in the `get_user_by_username` router.
