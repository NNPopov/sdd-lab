Implement slice 0047_revoke_moderator_route_to_user_id. All specs and the test are already ready.

Sources (read in this order):
- specs/features/users/0047_revoke_moderator_route_to_user_id/plan.md
- specs/features/users/0047_revoke_moderator_route_to_user_id/requirements.md
- specs/features/users/0047_revoke_moderator_route_to_user_id/tests.md
- specs/features/users/0047_revoke_moderator_route_to_user_id/validation.md

Acceptance gate:
- tests/features/users/0016_revoke_moderator/revoke_moderator_outside_in_test.py
  must turn GREEN.
- Do not touch the test file or conftest.py. If the test fails due to a bug
  in the implementation — fix the implementation, not the test.
- If the test fails due to a defect in the test itself — stop and ask,
  do not silently fix it.

Once the outside-in test is green — update the other three test levels per the
plan (see plan.md section "Tests planned" and agent_docs/testing.md): the
use-case unit test, the adapter unit test, and the endpoint integration test
under tests/features/users/0016_revoke_moderator/.

Quality gates before completion:
- ruff format src/app tests
- ruff check src/app tests
- mypy src/app
- pytest
- Architecture contracts: find and run the import-linter using .importlinter config

All must pass with no new warnings.
