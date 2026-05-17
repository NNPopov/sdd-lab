---
name: slice-decomposition
description: This skill should be used when the user is splitting a new feature into slices, when a planned slice feels too large, or when the user asks "should this be one slice or two?". It helps decide the right grain of decomposition — each slice should be one use-case with one port, one adapter, one HTTP entry point.
disable-model-invocation: false
---

# slice-decomposition

Reference for how to split a feature into slices. The unit of decomposition is
the **use-case**, not the resource. A REST `POST /users` and a `GET /users` are
two slices.

## When to trigger

- User is starting a new feature and asks "how do I structure this?"
- User has a `plan.md` that touches multiple operations.
- User asks "should `create` and `update` be the same slice?"
- User asks "how do I name this slice?"

## Process

### 1. Load context

Read these:

- `CLAUDE.md`
- `agent_docs/architecture.md`
- The relevant existing feature folder under `src/app/features/` if any (for
  reference patterns).

### 2. Apply the heuristics

A slice corresponds to exactly **one use-case**. To decide whether two
operations are one slice or two:

**Two slices when any of these holds:**

- The operations have different **ports**: one writes, one reads.
- The operations have different **authorization rules**: anyone can `list`;
  only admin can `delete`.
- The operations have different **cache policies**: `list` is cached;
  `create` invalidates the cache.
- The operations model different **failure modes** worth distinguishing in
  the domain.
- The operations are exposed at **different HTTP paths or methods**.

**One slice when all of these hold:**

- Both operations call the exact same port methods with the same arguments.
- Both operations have the same authorization rule.
- One is a strict subset of the other (e.g. dry-run mode of the same logic).
- The two share no useful distinction at the domain layer.

When in doubt, **two slices**. Merging later is cheap; splitting an overgrown
slice is expensive.

### 3. Name the slice

Slices are named `<verb>_<noun>`:

- `create_user`, `list_users`, `get_user`, `update_user`, `delete_user`
- `create_post`, `list_user_posts`, `get_post`, `update_post`, `delete_post`
- `login`, `logout`, `refresh_token`

Avoid HTTP verbs in slice names: not `post_user`, not `patch_user`. The verb is
the business operation.

For batch operations: `bulk_create_users`, `bulk_delete_posts`. The `bulk_`
prefix marks the operation as batched.

For read operations with significant differences in shape:
- `list_users` — paginated, with filters
- `get_user_by_id` — single record
- `search_users` — query-based, possibly across many fields

Three slices, not one.

### 4. Sanity-check the result

For each proposed slice, confirm:

- It has one operation that is meaningful to a human user.
- It has one port with at most three methods (typically one).
- It can be tested by one outside-in scenario.
- Its name reads as `<verb>_<noun>`.

If a proposed slice has more than three port methods, it is likely two slices
that should be split. If its name has more than two words and is not a `bulk_`
or `search_` case, it is likely two slices.

### 5. Document the decisions

In the feature's first PRD (or in an ADR), record:

- The list of slices that compose the feature.
- The reason for any non-obvious split.
- Which slices are in scope for the current iteration and which are deferred.

## Worked example: users feature

A new "users" feature with full CRUD plus auth. The decomposition:

| Slice | Verb | Noun | Port | Notes |
|---|---|---|---|---|
| `create_user` | create | user | `CreateUserPort` | Public, rate-limited |
| `list_users` | list | users | `ListUsersPort` | Admin-only |
| `get_user` | get | user | `GetUserPort` | Authenticated |
| `update_user` | update | user | `UpdateUserPort` | Self or admin |
| `delete_user` | delete | user | `DeleteUserPort` | Self or admin |
| `login` | login | (no noun, auth verb) | `LoginPort` | Public, rate-limited |
| `logout` | logout | (no noun) | `LogoutPort` | Authenticated |
| `refresh_token` | refresh_token | (no noun) | `RefreshTokenPort` | Public, rate-limited |

Eight slices for one feature. Each has its own folder with the full hexagonal
stack. The `_shared/` folder holds the `User` domain entity and
`get_current_user` / `get_current_superuser` dependencies.

## Anti-patterns

- ❌ One slice `user_crud` containing all five operations. Six ports, three
  authorization rules, three cache policies — impossible to maintain.
- ❌ Splitting `create_user` further into `validate_user_input` and
  `persist_user`. That is internal use-case structure, not a slice boundary.
- ❌ Slice `user_management` covering "list, get, update, delete" because
  they "feel admin-y." Each has different concerns; split.
- ❌ Combining `login` and `refresh_token` because both deal with tokens.
  Different operations, different ports.

## Common mistakes

- ❌ Naming a slice after the URL: `post_users`, `delete_users_id`. The slice
  is named after the operation, not the route.
- ❌ Creating a slice without a port. Even a trivial slice has a port; that
  is the boundary the outside-in test exercises.
- ❌ Sharing a port across two slices "because the signature is the same."
  If they are two operations, give them two ports even when the shape matches.
  Coupling through a shared port turns a refactor of one into a refactor of
  both.
- ❌ Leaving a slice in `_shared/`. `_shared/` is for entities and
  dependencies, not for slices.
