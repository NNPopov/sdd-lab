Implement slice 0056_migrate_update_post_route_username_to_user_id. All specs and the test are already ready.

Sources (read in this order):
- specs/features/posts/0056_migrate_update_post_route_username_to_user_id/plan.md
- specs/features/posts/0056_migrate_update_post_route_username_to_user_id/requirements.md
- specs/features/posts/0056_migrate_update_post_route_username_to_user_id/tests.md
- specs/features/posts/0056_migrate_update_post_route_username_to_user_id/validation.md

Acceptance gate:
- tests/features/posts/0056_migrate_update_post_route_username_to_user_id/migrate_update_post_route_username_to_user_id_outside_in_test.py
  must turn GREEN.
- Do not touch the test file or conftest.py. If the test fails due to a bug
  in the implementation — fix the implementation, not the test.
- If the test fails due to a defect in the test itself — stop and ask,
  do not silently fix it.

Once the outside-in test is green — write the missing unit tests per the
plan (see plan.md section "Tests planned" and agent_docs/testing.md). For this
slice that means the use-case unit test (happy path, user not found, not owner,
post not found) and the endpoint integration test (200 owner, 403 non-owner,
404 unknown user, 404 unknown post, 401 unauthenticated, 422 non-integer, old
route gone, cache invalidation). The adapter unit test is opted out (the adapter
is unchanged). Also update the existing tests/features/posts/0028_update_post/
tests, which hit the old /{username}/post/{id} route and build UpdatePostCommand
with username fields, to the integer route and id fields; baseline the full
suite before and after and prove zero net-new failures.

Quality gates before completion:
- ruff format src/app tests
- ruff check src/app tests
- mypy src/app
- pytest
- Architecture contracts: find and run the import-linter using .importlinter config

All must pass with no new warnings.
