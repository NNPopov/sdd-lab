# PRD — Remove the Username-Based User Lookup (cleanup slice 0059)

**Slice:** `0059_remove_username_user_lookup`
**Resource:** posts
**Depends on:** slices **0057** (`migrate_erase_post_route_username_to_user_id`)
and **0058** (`migrate_erase_db_post_route_username_to_user_id`) must be complete
— they were the last two callers of `get_active_user_by_username`. This is the
**final cleanup slice** of the `{username}` → `{user_id}` post-route migration
initiative (after 0042 / 0054 / 0055 / 0056 / 0057 / 0058).

---

## Problem Statement

The post-route migration is functionally complete: every Posts API route now
identifies the author by integer `user_id`, and every post write use-case
(`create_post`, `update_post`, `erase_post`, `erase_db_post`) resolves the author
through the shared `get_active_user_by_id`. The username-based lookup
`get_active_user_by_username` on the shared `UserLookupPort` / `UserLookupAdapter`
was retained throughout the migration purely so that not-yet-migrated slices
stayed green. It now has **zero callers** in the source tree — it is dead code
that still ships in the port contract, the adapter implementation, and the shared
adapter test suite.

Leaving it in place is misleading: it advertises a username-based resolution
path that the codebase no longer uses, and its tests imply a supported behaviour
that is no longer exercised by any feature.

## Solution

Remove `get_active_user_by_username` from the shared `UserLookupPort` Protocol
and from the `UserLookupAdapter` implementation, leaving `get_active_user_by_id`
as the single user-resolution method. Update the shared adapter test suite to
drop the username-specific cases while preserving the by-id coverage and the
infrastructure-exception-propagation guarantee.

This slice changes no HTTP route, no request/response schema, no domain
behaviour, and no database schema. It is a pure dead-code removal whose
acceptance gate is that the full test suite — including the four post write
slices' outside-in tests — remains green.

## User Stories

1. As a developer reading the shared post helpers, I want the user-lookup port to
   expose only `get_active_user_by_id`, so that the contract reflects how the
   codebase actually resolves users and offers no misleading username path.
2. As a developer maintaining the adapter, I want the username-based query method
   removed, so that there is no unused SQL query to keep in sync with the schema.
3. As a developer running the test suite, I want the shared adapter tests to
   cover only the supported by-id lookup (plus infrastructure-error
   propagation), so that the tests document real behaviour and do not pin a
   removed method.
4. As a developer, I want the infrastructure-exception-propagation guarantee
   (an `OperationalError` from the session is not swallowed) to remain verified
   after the username method is gone, so that the adapter's error-handling
   contract is still enforced.
5. As a developer, I want confirmation that no `ForbiddenDomainError` message or
   other user-facing string in the posts feature still references "username", so
   that the migration leaves no stale wording behind.
6. As a developer, I want every post write use-case
   (`create_post`, `update_post`, `erase_post`, `erase_db_post`) to keep passing
   its outside-in test after the removal, so that I have proof the method was
   truly unused.
7. As a developer, I want the import-linter / architecture checks and the smoke
   test to stay green, so that removing a shared symbol has not broken any wiring.

## Implementation Decisions

### Modified shared module: user-lookup port (`UserLookupPort`)

Remove the `get_active_user_by_username(username: str) -> UserIdentity | None`
method from the Protocol. `get_active_user_by_id(user_id: int) -> UserIdentity |
None` remains as the sole method. The Protocol keeps its `@runtime_checkable`
decorator.

### Modified shared module: user-lookup adapter (`UserLookupAdapter`)

Remove the `get_active_user_by_username` implementation (and its now-unused
`User.username`-based `select`). The class continues to inherit the port
explicitly and keeps `get_active_user_by_id` unchanged.

### Modified test: shared adapter unit tests

In the `extract_user_lookup` (0032) adapter test module:

- **Remove** the three `get_active_user_by_username` behaviour tests
  (active-user-found, unknown-username, soft-deleted-user).
- **Re-point** the infrastructure-exception-propagation test (the
  `OperationalError` propagation case) from `get_active_user_by_username` to
  `get_active_user_by_id`, so that the N3 propagation guarantee remains covered
  by a still-existing method rather than being lost with the removed one.
- **Keep** the three `get_active_user_by_id` behaviour tests unchanged.

### Verification of residual wording

Confirm by search that no `ForbiddenDomainError(...)` message (or other
user-facing string) in the posts feature mentions "username". This is expected to
already be clean — `create_post` (0055) and `update_post` (0056) removed their
username-mentioning messages, and `erase_post` / `erase_db_post` never had one.
The slice records this as a checked invariant, not a code change.

### What is explicitly NOT removed

- **`UserIdentity.username`** is retained. Although no write-path use-case
  currently reads it (callers use `UserIdentity.id`), the field is still
  populated by `get_active_user_by_id` and asserted by its adapter test, and it
  is a harmless DTO field outside this initiative's stated cleanup scope.
  Removing it is a possible future refactor, not part of this slice.
- **`User.username` selects for display** in read adapters
  (`get_post`, `list_posts`, `list_all_posts`, `list_pending_posts`,
  `get_moderation_log`) are unchanged — the response bodies still surface the
  author's handle, which is frozen by the initiative.

### No route, schema, DI, or database change

No HTTP route, request/response schema, DI container wiring, or database schema
changes. No Alembic migration. The DI container already constructs a single
`UserLookupAdapter` and injects it as `UserLookupPort` into the write
use-cases; removing one method does not change that wiring.

## Testing Decisions

Good tests verify observable behaviour, not implementation details. For a pure
removal slice the most meaningful signal is that the existing behavioural tests
of the consumers stay green; the only new test work is pruning and re-pointing
the shared adapter tests.

### Shared adapter unit test

As described above: drop the three username behaviour cases, re-point the
infrastructure-error-propagation case to `get_active_user_by_id`, keep the three
by-id cases. After the change, every test in the module exercises a method that
still exists.

Prior art: the same module as it stands today
(`tests/features/posts/0032_extract_user_lookup/`).

### Consumer regression (acceptance gate)

No new outside-in test is written — this slice has no new HTTP entry point. The
acceptance gate is that the **existing** outside-in tests for `create_post`,
`update_post`, `erase_post`, and `erase_db_post` remain green, proving the
removed method was genuinely unused. This mirrors how slice 0032
(`extract_user_lookup`) opted out of its own outside-in test as a pure refactor.

### Full-suite + smoke + arch gate

Because a shared symbol is removed, run the full `pytest` suite (including
`tests/smoke/test_app_starts.py`) and the import-linter architecture gate. Green
across all three is required. Baseline the suite before and after and prove zero
net-new failures.

**Opt-outs:** no new use-case unit test, no new endpoint integration test, and
no new outside-in test — this slice adds no behaviour and no entry point. Only
the existing shared adapter test is modified.

## Out of Scope

- Removing or renaming `UserIdentity.username` — retained (see Implementation
  Decisions).
- Any `User.username` display selects in read adapters or the `username` field in
  response bodies — frozen by the initiative.
- The `check_post_owner` policy — already converted to id-based in slice 0055;
  unchanged here.
- Any route, schema, or behaviour change — this is a dead-code removal only.
- The Flutter client — unaffected by an internal helper removal.

## Further Notes

- **Dependency / sequencing.** This slice must run **after** 0057 and 0058. At
  the time of writing, the live source already shows `erase_post` and
  `erase_db_post` resolving the author via `get_active_user_by_id`, so
  `get_active_user_by_username` already has zero `src` callers and this slice is
  unblocked.
- **This closes the initiative.** After this slice, the post feature exposes a
  single id-based user-resolution method, a single id-based ownership policy
  (`check_post_owner`), and no `{username}` post routes. The
  `{username}` → `{user_id}` migration is complete.
- **Why a dedicated slice rather than folding the removal into 0058.** Keeping
  the removal separate preserves the migration's green-tree discipline: each
  route slice stayed green by leaving the username method in place, and the
  method is deleted only once the final caller is gone. Isolating the deletion
  also makes the diff trivially reviewable and easy to revert if any overlooked
  caller surfaces.
