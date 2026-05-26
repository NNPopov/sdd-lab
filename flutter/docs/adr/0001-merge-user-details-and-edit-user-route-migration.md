---
status: accepted
---

# Migrate `user_details` and `edit_user` as a single route-migration slice

During the `{username}` → `{user_id}` API migration, every affected route is migrated as
its own slice — **except** `user_details` and `edit_user`, which are migrated together in one
slice (`0050_user_details_edit_user_route_to_user_id`), one commit, one outside-in test. They
are coupled by the shared `UsersApiClient.getUser(...)` method (`user_details` reads it via
`get_user_adapter`, `edit_user` via `get_user_for_edit_adapter`). Changing that one method's
signature from `String username` to `int userId` breaks both adapters at once, so neither can
reach a green acceptance gate independently — the per-slice green checkpoint only exists for
the pair.

## Considered options

- **Two separate slices (rejected).** Matches the project's usual 1:1 spec-per-code-slice
  convention, but finishing the first slice would leave the second red until the second
  lands — violating the per-slice green gate that `/run-spec-workflow` assumes (cf. the
  "route-migration breaks downstream tests" experience).
- **One combined slice (accepted).** Honest about the coupling; a single green checkpoint
  covers both.

## Consequences

- This is a **pure refactor merge of the work unit only** — `UserDetailsCubit` and
  `EditUserCubit`, their ports, adapters, screens, and routes stay fully separate. No logic
  is merged and no behavior changes.
- The two slices' code folders remain independent; only the spec doc and the commit are shared.
- Splitting them apart later would require re-coupling them at the `getUser` signature again,
  so the grouping is awkward (not impossible) to reverse.
