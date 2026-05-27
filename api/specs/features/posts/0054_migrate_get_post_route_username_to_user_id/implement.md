Implement slice migrate_get_post_route_username_to_user_id. All specs and the test are already ready.

Sources (read in this order):
- specs/features/posts/0054_migrate_get_post_route_username_to_user_id/plan.md
- specs/features/posts/0054_migrate_get_post_route_username_to_user_id/requirements.md
- specs/features/posts/0054_migrate_get_post_route_username_to_user_id/tests.md
- specs/features/posts/0054_migrate_get_post_route_username_to_user_id/validation.md

Acceptance gate:
- tests/features/posts/0054_migrate_get_post_route_username_to_user_id/migrate_get_post_route_username_to_user_id_outside_in_test.py
  must turn GREEN.
- Do not touch the test file or conftest.py. If the test fails due to a bug
  in the implementation — fix the implementation, not the test.
- If the test fails due to a defect in the test itself — stop and ask,
  do not silently fix it.

This is an in-place migration of the existing get_post slice (no new files):
rename GetPostQuery fields (username->user_id, requester_username->requester_user_id),
switch the use-case author check to requester_user_id == user_id, switch the
adapter filter to Post.created_by_user_id == query.user_id (retain the User JOIN
for the display username), and repoint the router path to /{user_id}/post/{id}
with the cache key_prefix "{user_id}_post_cache". No DB migration, no wiring change.

This slice can break OTHER slices' tests that share the get_post route or fixtures
(notably tests/features/posts/0026_get_post/). Baseline the full suite before and
after, update the old 0026 test URLs to the integer route, and prove zero net-new
failures.

Once the outside-in test is green — write the missing unit tests per the
plan (see plan.md section "Tests planned" and agent_docs/testing.md).

Quality gates before completion:
- ruff format src/app tests
- ruff check src/app tests
- mypy src/app
- pytest
- Architecture contracts: find and run the import-linter using .importlinter config

All must pass with no new warnings.
