Implement slice get_tier_by_id. All specs and the test are already ready.

Sources (read in this order):
- specs/features/tiers/0038_get_tier_by_id/plan.md
- specs/features/tiers/0038_get_tier_by_id/requirements.md
- specs/features/tiers/0038_get_tier_by_id/tests.md
- specs/features/tiers/0038_get_tier_by_id/validation.md

Acceptance gate:
- tests/features/tiers/0038_get_tier_by_id/get_tier_by_id_outside_in_test.py
  must turn GREEN.
- Do not touch the test file or conftest.py. If the test fails due to a bug
  in the implementation — fix the implementation, not the test.
- If the test fails due to a defect in the test itself — stop and ask,
  do not silently fix it.

Once the outside-in test is green — write the missing unit tests per the
plan (see plan.md section "Tests planned" and agent_docs/testing.md).

Quality gates before completion:
- ruff format src/app tests
- ruff check src/app tests
- mypy src/app
- pytest
- Architecture contracts: find and run the import-linter using .importlinter config

All must pass with no new warnings.
