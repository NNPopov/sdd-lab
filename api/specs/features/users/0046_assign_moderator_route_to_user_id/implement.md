Implement slice 0046_assign_moderator_route_to_user_id. All specs and the test are already ready.

This is an in-place migration of the existing slice 0015 (assign_moderator):
PATCH /user/{username}/assign-moderator becomes PATCH /user/{user_id}/assign-moderator.
The implementation files live under src/app/features/users/assign_moderator/.

Sources (read in this order):
- specs/features/users/0046_assign_moderator_route_to_user_id/plan.md
- specs/features/users/0046_assign_moderator_route_to_user_id/requirements.md
- specs/features/users/0046_assign_moderator_route_to_user_id/tests.md
- specs/features/users/0046_assign_moderator_route_to_user_id/validation.md

Acceptance gate:
- tests/features/users/0015_assign_moderator/assign_moderator_outside_in_test.py
  must turn GREEN.
- Do not touch the test file or conftest.py. If the test fails due to a bug
  in the implementation — fix the implementation, not the test.
- If the test fails due to a defect in the test itself — stop and ask,
  do not silently fix it.

Once the outside-in test is green — update the other three test levels under
tests/features/users/0015_assign_moderator/ (domain/test_use_case.py,
data/test_adapter.py, presentation/test_router.py) to the integer-id contract
per plan.md section "Tests planned" and agent_docs/testing.md.

Quality gates before completion:
- ruff format src/app tests
- ruff check src/app tests
- mypy src/app
- pytest
- Architecture contracts: find and run the import-linter using .importlinter config

All must pass with no new warnings.
