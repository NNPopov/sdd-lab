# Flutter Client — Domain Language

Glossary for the Flutter cross-platform client. Captures terms whose meaning is
non-obvious or has been a source of confusion during design sessions.

## Language

### User identity

**user_id**:
The integer that identifies *which* user a request targets. It is the key in
every API URL path (`/user/{user_id}`, `/user/{user_id}/post/{id}`) and the
lookup parameter passed into ports and adapters.
_Avoid_: "username in the path", "user key as a string".

**handle**:
The `username` string as a *property* of a user — what you log in with, what is
shown as `@username`, and what the user can edit about themselves. It is stored
and displayed; it never identifies the target of a request in a URL path.
_Avoid_: renaming it to `userId`, conflating it with **user_id**.

**author identity** / `created_by_user_id`:
The **user_id** of the user who created a post. It is the path-identity for every
post-scoped URL (`/{user_id}/posts`, `/{user_id}/post/{id}`) — i.e. the *author*, who
is usually **not** the current viewer. A post also carries the author's `username`,
which is the author's **handle** (shown as `@username`); it is for display only and
travels alongside the id, never as the URL key.
_Avoid_: putting the author's handle in a post URL; treating `created_by_user_id` as
the viewer's own id.

## Flagged ambiguities

**"username"** — overloaded. It means **user_id** (identity) in some places and
**handle** (a property) in others. The governing rule for the
`{username}` → `{user_id}` migration:

> Migrate `username` → `user_id: int` **only** where it identifies the target of
> a request: URL path segments, port/adapter lookup parameters, `AuthCubit.isMe`,
> and ownership/permission comparisons (e.g. `currentUser.username != data.username`).
> **Never** touch `username` where it is a stored or displayed handle:
> `User.username`, `CurrentUser.username`, the PATCH-body `username` field
> (`UserUpdate.username`), the create-user form, login, and `@username` labels.

Every edit must first classify the occurrence as identity or handle. A blind
`username → userId` find-and-replace corrupts the handle and is forbidden.

## Example dialogue

> **Dev:** The edit-user screen has two usernames in it — do they both become `user_id`?
> **Expert:** No. The one the adapter passes to `getUser(...)` to fetch *that*
> user is identity — that becomes `user_id`. The one in the PATCH body, where the
> user types a new name for themselves, is the handle — it stays a string.
> **Dev:** So `isMe`?
> **Expert:** Identity. You're asking "is this the same user?", so compare ids.
