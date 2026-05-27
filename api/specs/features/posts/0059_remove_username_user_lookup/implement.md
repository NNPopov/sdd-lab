Implement slice remove_username_user_lookup. All specs and the test are already ready.

This is a PURE DEAD-CODE REMOVAL slice: remove `get_active_user_by_username` from the
shared `UserLookupPort` Protocol and the `UserLookupAdapter` implementation, leaving
`get_active_user_by_id` as the single user-resolution method. No route, schema, DI,
or database change. `get_active_user_by_username` already has zero `src` callers.

Sources (read in this order):
- specs/features/posts/0059_remove_username_user_lookup/plan.md
- specs/features/posts/0059_remove_username_user_lookup/requirements.md
- specs/features/posts/0059_remove_username_user_lookup/tests.md
- specs/features/posts/0059_remove_username_user_lookup/validation.md

Acceptance gate:
- tests/features/posts/0059_remove_username_user_lookup/remove_username_user_lookup_outside_in_test.py
  must turn GREEN (it is a structural removal guard: the username method must be gone
  from both UserLookupPort and UserLookupAdapter while get_active_user_by_id remains).
- The eight EXISTING post write outside-in tests must stay GREEN, proving the removed
  method was genuinely unused:
    pytest tests/features/posts/ -k "outside_in" -v
- Do not touch the outside-in test file. If it fails due to a bug in the
  implementation — fix the implementation, not the test. If it fails due to a defect
  in the test itself — stop and ask, do not silently fix it.

Implementation steps (see plan.md section 5 for detail):
1. src/app/features/posts/_shared/user_lookup_port.py — delete the
   get_active_user_by_username method from the Protocol; keep @runtime_checkable and
   get_active_user_by_id.
2. src/app/features/posts/_shared/user_lookup_adapter.py — delete the
   get_active_user_by_username method; keep get_active_user_by_id and the explicit
   `class UserLookupAdapter(UserLookupPort):` inheritance. Verify no import is left
   unused (select, User, UserIdentity, UserLookupPort all stay).
3. Prune tests/features/posts/0032_extract_user_lookup/data/test_user_lookup_adapter.py:
   remove the three get_active_user_by_username behaviour tests; re-point the
   OperationalError propagation test to get_active_user_by_id (keep the mocked
   side_effect and pytest.raises assertion); keep the three get_active_user_by_id
   behaviour tests; update the module docstring header.
4. Verify the residual-wording invariant: no ForbiddenDomainError message (or other
   user-facing string) under src/app/features/posts/ mentions "username".
5. Do NOT modify bootstrap/container.py (STABLE) — no wiring change is needed.
   Do NOT touch UserIdentity.username or any read-adapter username display select.

After the acceptance gate is green, confirm there are no other unit tests to write —
this slice opts out of new use-case, adapter, integration, and outside-in tests
(no new behaviour, no new entry point); the only test change is the prune in step 3.

Quality gates before completion (run from api/):
- ruff format src/app tests
- ruff check src/app tests
- mypy src/app
- pytest
- Architecture contracts: find and run the import-linter using .importlinter config
  (lint-imports, run from api/src with UTF-8).

All must pass with no new warnings. Baseline the suite before and after and prove
zero net-new failures.
