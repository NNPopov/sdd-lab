# PRD — Rename `get_user_by_username` Slice to `get_user_by_id` (slice 0041)

**Slice:** `0041_get_user_by_id`
**Resource:** users
**Depends on:** slice 0004 (`get_user_by_username`) must be complete.
**Part of:** `{username}` → `{user_id}` migration (slices 0041–0050, 0042).

---

## Problem Statement

`GET /user/{username}` identifies a user by their `username` string — a mutable
attribute that the user can change at any time. Any bookmark, cached URL, or
client-side reference to this endpoint silently breaks after a username rename.
The endpoint also forces the adapter to perform a `WHERE User.username = ?`
lookup instead of a primary-key lookup (`WHERE User.id = ?`), which is less
direct even though `username` is indexed.

## Solution

Rename the entire `get_user_by_username` slice to `get_user_by_id`. The route
becomes `GET /user/{user_id}` where `user_id` is the integer autoincrement
primary key of `User`. All artefacts inside the slice — folder name, class
names, port interface, adapter, use case, DI provider key, and router import
alias — are renamed consistently. The response body is unchanged.

## User Stories

1. As an API client, I want to retrieve a user profile by their integer ID
   (`GET /user/{user_id}`), so that the URL remains stable regardless of future
   username changes.
2. As an API client, I want to receive HTTP 404 when I call `GET /user/{user_id}`
   with an ID that does not exist, so that I get clear feedback that the user is
   absent.
3. As an API client, I want to receive HTTP 422 when I pass a non-integer value
   for `user_id`, so that type errors surface immediately via FastAPI's built-in
   coercion.
4. As an API client, I want the response body (id, name, username, email,
   profile_image_url, tier_id, is_moderator) to remain identical to the current
   `GET /user/{username}` response, so that only the URL changes and no response
   parser updates are needed.
5. As a developer, I want the adapter to use a primary-key lookup
   (`WHERE User.id = ?`) instead of a username lookup, so that the query is
   direct and independent of a mutable column.
6. As an API client, I want the old `GET /user/{username}` route to be gone (no
   redirect), so that the breaking change is explicit and forces client updates.

## Implementation Decisions

### Folder rename

The slice folder `get_user_by_username/` is renamed to `get_user_by_id/`. All
files inside it are also renamed (e.g. `get_user_by_username_port.py` →
`get_user_by_id_port.py`).

### Domain query

`GetUserByUsernameQuery` is renamed to `GetUserByIdQuery`. The field
`username: str` becomes `user_id: int`.

### Port

`GetUserByUsernamePort` → `GetUserByIdPort`. The method signature changes from
`get(query: GetUserByUsernameQuery) → FoundUser | None` to
`get(query: GetUserByIdQuery) → FoundUser | None`.

### Use case

`GetUserByUsernameUseCase` → `GetUserByIdUseCase`. Internal reference to the
port type and query type updated. Logic is unchanged — the use case raises
`NotFoundDomainError` when the port returns `None`.

### Adapter

`GetUserByUsernameAdapter(GetUserByUsernamePort)` →
`GetUserByIdAdapter(GetUserByIdPort)`. The SQLAlchemy `WHERE` clause changes
from `User.username == query.username` to `User.id == query.user_id`. The
`User.is_deleted == False` filter is retained.

### Presentation router

Route path changes from `/user/{username}` to `/user/{user_id}`. The path
parameter type changes from `str` to `int`. The query construction passes
`user_id=user_id` to `GetUserByIdQuery`.

### DI container

The provider key changes from `get_user_by_username_use_case` to
`get_user_by_id_use_case`. The binding wires `GetUserByIdUseCase` with
`GetUserByIdAdapter`.

### users/router.py import alias

The import changes from `get_user_by_username_router` to `get_user_by_id_router`.

### API contract

| Concern | Value |
|---|---|
| Method | `GET` |
| Old path | `/user/{username}` |
| New path | `/user/{user_id}` |
| Path param | `user_id: int` |
| Auth | None required |
| Response body | unchanged (`id`, `name`, `username`, `email`, `profile_image_url`, `tier_id`, `is_moderator`) |

**Error responses:**

| Status | Condition |
|---|---|
| 404 | `user_id` not found |
| 422 | Non-integer path value |

## Testing Decisions

Good tests verify observable behaviour through the public interface. They do not
assert internal query structure.

### Use-case unit test

Mock `GetUserByIdPort`. Cases:
- **Happy path** — mock port returns a `FoundUser`; assert use case returns it.
- **Not found** — mock port returns `None`; assert `NotFoundDomainError` is raised.

Prior art: `tests/features/users/0004_get_user_by_username/` use-case unit test.

### Adapter unit test

Real async session. Cases:
- **Found** — create a user row; call adapter with their `id`; assert returned
  `FoundUser` fields match.
- **Not found** — call adapter with a non-existent `id`; assert `None` returned.
- **Soft-deleted** — create a user with `is_deleted=True`; assert `None` returned.

Prior art: `tests/features/users/0004_get_user_by_username/` adapter unit test.

### Endpoint integration test

`httpx.AsyncClient` against the running app.
- **200** — create a user; call `GET /user/{id}`; assert response matches.
- **404** — call with a non-existent `id`; assert HTTP 404.
- **422** — call `GET /user/not-an-int`; assert HTTP 422.

### Outside-in test

1. Create a user via `POST /users/`; capture `id`.
2. Call `GET /user/{id}` — assert HTTP 200 and all fields correct.
3. Call `GET /user/{username}` (old route, string) — assert HTTP 422.

**Opt-outs:** none.

## Out of Scope

- All other users routes — covered in slices 0043–0050.
- `list_posts` route — covered in slice 0042.
- Username-based lookup for internal post author resolution (`UserLookupPort`).

## Further Notes

- The existing outside-in test for slice 0004 (`get_user_by_username`) must have
  its URL updated from `/user/{username}` to `/user/{user_id}` once this slice lands.
- `FoundUser` entity fields are unchanged; `id` was already present in the entity
  and response schema before this migration.
