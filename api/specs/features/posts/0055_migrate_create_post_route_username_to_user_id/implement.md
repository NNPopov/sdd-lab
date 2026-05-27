Implement slice migrate_create_post_route_username_to_user_id. All specs and the test are already ready.

Sources (read in this order):
- specs/features/posts/0055_migrate_create_post_route_username_to_user_id/plan.md
- specs/features/posts/0055_migrate_create_post_route_username_to_user_id/requirements.md
- specs/features/posts/0055_migrate_create_post_route_username_to_user_id/tests.md
- specs/features/posts/0055_migrate_create_post_route_username_to_user_id/validation.md

Acceptance gate:
- tests/features/posts/0055_migrate_create_post_route_username_to_user_id/migrate_create_post_route_username_to_user_id_outside_in_test.py
  must turn GREEN.
- Do not touch the test file or conftest.py. If the test fails due to a bug
  in the implementation — fix the implementation, not the test.
- If the test fails due to a defect in the test itself — stop and ask,
  do not silently fix it.

This is an in-place migration of the existing create_post slice (no new files),
plus a contained shared-module and erase_post change:
- create_post command: target_username->target_user_id:int, requester_username->requester_user_id:int.
- create_post use-case: resolve author via get_active_user_by_id (404 "User not found"),
  then check_post_owner(requester_user_id, author.id) (bare 403), then build the internal
  command with created_by_user_id=author.id. Drop the ForbiddenDomainError import and the
  inline "You can only post under your own username" message.
- create_post router: path /{user_id}/post with user_id:int; build the command with
  target_user_id=user_id and requester_user_id=current_user["id"].
- posts/_shared/user_lookup_port.py + user_lookup_adapter.py: ADD get_active_user_by_id
  (filter User.id == user_id AND is_deleted == False); KEEP get_active_user_by_username.
- posts/_shared/policies.py: convert check_post_owner to (requester_user_id: int,
  owner_user_id: int) comparing ints, still raising a bare ForbiddenDomainError().
- CreatePostInternalCommand, CreatePostAdapter, CreatePostRequest/Response are UNCHANGED.
- No DB migration, no DI/wiring change, no .importlinter change.

Because check_post_owner is shared, erase_post must be kept green in the same slice
(route, cache keys, and target lookup stay as they are):
- erase_post command: requester_username:str -> requester_user_id:int.
- erase_post router: pass requester_user_id=current_user["id"].
- erase_post use-case: check_post_owner(command.requester_user_id, user.id).

This slice can break OTHER slices' tests that share the create_post route or the
shared policy (notably tests/features/posts/0011_create_post/ and the erase_post
use-case unit test). Baseline the full suite before and after, update the old 0011
test URLs to the integer route and id-based command, update the erase_post use-case
unit test to the id-based ownership check, and prove zero net-new failures
(user memory project_route_migration_downstream_tests).

Once the outside-in test is green — write the missing unit tests per the
plan (see plan.md section "Tests planned" and agent_docs/testing.md): the
create_post use-case unit test (happy/owner, user-not-found, not-owner) and the
shared get_active_user_by_id adapter test added under
tests/features/posts/0032_extract_user_lookup/.

Quality gates before completion:
- ruff format src/app tests
- ruff check src/app tests
- mypy src/app
- pytest
- Architecture contracts: find and run the import-linter using .importlinter config

All must pass with no new warnings.
