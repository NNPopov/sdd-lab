Implement slice 0045_delete_db_user_route_to_user_id. All specs and the test are already ready.

This is an in-place migration of the existing delete_db_user slice (slice 0008): the route changes from DELETE /db_user/{username} to DELETE /db_user/{user_id}. The slice source lives in src/app/features/users/delete_db_user/ and its tests live in tests/features/users/0008_delete_db_user/.

Sources (read in this order):
- specs/features/users/0045_delete_db_user_route_to_user_id/plan.md
- specs/features/users/0045_delete_db_user_route_to_user_id/requirements.md
- specs/features/users/0045_delete_db_user_route_to_user_id/tests.md
- specs/features/users/0045_delete_db_user_route_to_user_id/validation.md

Acceptance gate:
- tests/features/users/0008_delete_db_user/delete_db_user_outside_in_test.py
  must turn GREEN.
- Do not touch the test file or conftest.py. If the test fails due to a bug
  in the implementation — fix the implementation, not the test.
- If the test fails due to a defect in the test itself — stop and ask,
  do not silently fix it.

Implementation summary (from plan.md):
- domain/commands.py: DeleteDbUserCommand.target_username: str → target_user_id: int
- domain/entities.py: DbDeleteUserTarget.username: str → id: int
- domain/ports/delete_db_user_port.py: get_by_username → get_by_id(user_id: int); db_delete param str → int
- domain/use_case.py: use get_by_id / db_delete with the integer ID; NotFoundDomainError branch unchanged
- data/adapter.py: get_by_id queries User.id; db_delete deletes by User.id; keep the IntegrityError → DuplicateValueDomainError catch
- presentation/router.py: route /db_user/{user_id}, int path param, command target_user_id=user_id; keep get_current_superuser
- No STABLE files change (container.py and router.py already wire this slice).

Once the outside-in test is green — update the missing unit tests per the plan
(see plan.md section "Tests planned" and agent_docs/testing.md): the use-case
unit test, adapter unit test, and endpoint integration test under
tests/features/users/0008_delete_db_user/.

Quality gates before completion:
- ruff format src/app tests
- ruff check src/app tests
- mypy src/app
- pytest
- Architecture contracts: find and run the import-linter using .importlinter config

All must pass with no new warnings.
