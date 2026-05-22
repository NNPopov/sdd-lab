# PRD — 0032 extract_user_lookup

## Problem Statement

The `get_user_by_username` database query is duplicated verbatim across four post slices
(`create_post`, `update_post`, `erase_post`, `erase_db_post`). Each slice re-declares the
same SQL, the same filter (`is_deleted = False`), and the same mapping logic in its own
adapter. This violates DRY at the infrastructure level, makes the filter contract invisible
(callers cannot tell from the port that "active only" is enforced), and means any future
change to this query — a new column, a changed filter — must be applied in four places.

Additionally, each per-slice port (`CreatePostPort`, `UpdatePostPort`, etc.) carries
`get_user_by_username` as a declared method, even though user resolution is not logically
part of the post-operation contract. This pollutes the per-slice port interfaces with a
cross-cutting concern.

## Solution

Extract user resolution for the posts feature into a single shared port and adapter living
in `posts/_shared/`. Introduce a shared domain entity `UserIdentity` (replacing the
current `PostAuthor`) that represents the minimum user information needed by post
operations: numeric ID and username. Each post use case receives a `UserLookupPort` as a
second injected dependency, calls `get_active_user_by_username`, and the per-slice ports
are cleaned of the method.

The `posts` module remains fully self-contained — no new STABLE-layer files are created,
and the single STABLE change is registering one shared provider in the DI container.

## User Stories

1. As a developer working on the posts feature, I want user resolution to live in one
   place, so that I only need to update the SQL query once if the lookup logic changes.
2. As a developer reading a post slice's port, I want the port to declare only the
   operations unique to that slice, so that I understand the slice's real responsibilities
   at a glance.
3. As a developer writing a new post slice that needs to resolve a username, I want a
   ready-made shared port and adapter, so that I do not need to write the same query again.
4. As a developer, I want the "active users only" filter to be expressed in the method name
   (`get_active_user_by_username`), so that the contract is visible without reading the SQL.
5. As a developer planning to extract the posts module into a separate deployable unit, I
   want all user-lookup logic to live inside `posts/_shared/`, so that posts carries no
   dependency on STABLE shared infrastructure outside the feature boundary.
6. As a developer writing tests for a post use case, I want to mock only one
   `UserLookupPort` rather than re-declaring the same mock method per slice, so that test
   setup is consistent and compact.
7. As a developer doing a code review, I want each post adapter to contain only the
   post-specific SQL, so that adapters are easy to audit.
8. As a developer planning phase 2 (extending user lookup to the users feature), I want the
   port interface and entity to be clear and stable inside posts, so that promotion to a
   higher layer is a mechanical move with no semantic change.

## Implementation Decisions

- A new `UserIdentity` entity with fields `id: int` and `username: str` is introduced in
  `posts/_shared/`. It replaces `PostAuthor` throughout all four post slices. `PostAuthor`
  is deleted.
- A new `UserLookupPort` protocol is introduced in `posts/_shared/`. It declares a single
  method: `get_active_user_by_username(username: str) -> UserIdentity | None`. The name
  encodes the `is_deleted = False` filter as part of the contract.
- A new `UserLookupAdapter` is introduced in `posts/_shared/`. It implements
  `UserLookupPort` with a single async SQLAlchemy query filtering on `username` and
  `is_deleted = False`, returning `UserIdentity` or `None`.
- The four per-slice ports (`CreatePostPort`, `UpdatePostPort`, `ErasePostPort`,
  `EraseDbPostPort`) have `get_user_by_username` removed. Each port now declares only
  operations specific to its slice.
- The four per-slice adapters have `get_user_by_username` removed. Each adapter now
  implements only the remaining per-slice methods.
- The four use-case constructors gain a second parameter `user_lookup: UserLookupPort`.
  Inside `__call__`, the call `self._port.get_user_by_username(...)` is replaced by
  `self._user_lookup.get_active_user_by_username(...)`.
- The DI container registers one shared `UserLookupAdapter` provider (using
  `providers.Factory` with `session_factory`). Each of the four use-case providers receives
  this shared provider as `user_lookup`.
- This slice is a pure refactor: no HTTP endpoints change, no database schema changes, no
  migration is needed.
- Phase 2 (extending to user slices or promoting to STABLE layer) is explicitly out of
  scope. The design does not pre-empt it but leaves the door open: moving the port and
  adapter to `ports/` and `adapters/db/` in the future requires no changes to `UserIdentity`
  or to the use-case call sites.

## Testing Decisions

- A good test validates external behavior, not internal wiring. It does not assert which
  internal method was called on the adapter — it asserts the use-case output or the
  exception raised.
- **Use-case unit tests** (one per slice, mocked `UserLookupPort` and mocked per-slice
  port): confirm that `NotFoundDomainError` is raised when `get_active_user_by_username`
  returns `None`, and that the happy path passes `UserIdentity.id` correctly to the
  per-slice port. Prior art: existing use-case unit tests in `tests/features/posts/`.
- **Adapter unit test** for `UserLookupAdapter`: confirm that a soft-deleted user returns
  `None`, an active user returns the correct `UserIdentity`, and a non-existent username
  returns `None`. Uses a mocked async session. Prior art: existing adapter unit tests in
  `tests/features/posts/`.
- **Existing outside-in tests** for the four post slices must remain green throughout —
  this is the primary acceptance gate for the refactor. No new outside-in test is written
  for this slice because no user-visible behavior changes.
- The `UserLookupPort` protocol itself does not require a dedicated test; its correctness
  is validated structurally by the adapter inheriting it and by `isinstance()` checks
  available via `@runtime_checkable`.

## Out of Scope

- Applying the same extraction to user-feature slices (`delete_user`, `delete_db_user`,
  `revoke_moderator`, etc.). This is phase 2 and will be a separate slice.
- Promoting `UserIdentity`, `UserLookupPort`, or `UserLookupAdapter` to the STABLE layer
  (`domain/shared/`, `ports/`, `adapters/db/`). That promotion happens in phase 2 when a
  second feature boundary needs the same abstraction.
- Any change to HTTP endpoints, request/response schemas, or OpenAPI contracts.
- Any database migration.
- Role or permission checking beyond what already exists in `posts/_shared/policies.py`.

## Further Notes

- `PostAuthor` is currently used in `posts/_shared/entities.py` and imported by all four
  post adapters. After this slice, it is fully deleted; all references are replaced by
  `UserIdentity`.
- `UserLookupPort` must carry `@runtime_checkable` per the project hard rule on ports.
- The existing `get_user_by_username` slice in `features/users/` (slice 0004) is an
  unrelated HTTP endpoint for external consumers and is not touched.
- The name `get_active_user_by_username` intentionally differs from the existing per-slice
  method name `get_user_by_username` to make the semantic change visible at all call sites
  during the refactor.
