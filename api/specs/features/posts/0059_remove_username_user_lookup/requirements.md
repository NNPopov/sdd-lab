# 0059 · remove_username_user_lookup — Requirements

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md

## Functional requirements

### Shared port

- **F1.** `posts/_shared/user_lookup_port.py` defines `UserLookupPort` as a
  `@runtime_checkable` `Protocol` with exactly one method:
  `async def get_active_user_by_id(self, user_id: int) -> UserIdentity | None`.
- **F2.** The `get_active_user_by_username` method is fully removed from
  `UserLookupPort`; no declaration of it remains in the Protocol.
- **F3.** `UserLookupPort` retains the `@runtime_checkable` decorator so that
  `isinstance(adapter, UserLookupPort)` returns `True` at runtime.

### Shared adapter

- **F4.** The `get_active_user_by_username` method is fully removed from
  `UserLookupAdapter`; no implementation of it remains in the class.
- **F5.** `UserLookupAdapter.get_active_user_by_id` is unchanged — it queries
  `User.id == user_id` AND `User.is_deleted.is_(False)`, returns a `UserIdentity`
  (validated via `UserIdentity.model_validate(user)`) when an active user is found,
  and returns `None` otherwise.
- **F6.** `UserLookupAdapter` continues to inherit its port explicitly
  (`class UserLookupAdapter(UserLookupPort):`) and remains a structurally complete
  implementation of the now-one-method Protocol.
- **F7.** The module's imports (`select`, `User`, `UserIdentity`, `UserLookupPort`)
  remain present and used by `get_active_user_by_id`; removing the username method
  introduces no unused import.

### Dead-code removal verification

- **F8.** After the change, `get_active_user_by_username` has zero references anywhere
  under `src/app/` (no port declaration, no adapter method, no caller).

### Shared adapter test prune

- **F9.** The three `get_active_user_by_username` behaviour tests
  (active-user-found, unknown-username, soft-deleted-user) are removed from
  `tests/features/posts/0032_extract_user_lookup/data/test_user_lookup_adapter.py`.
- **F10.** The infrastructure-exception-propagation test is re-pointed from
  `get_active_user_by_username` to `get_active_user_by_id`: it mocks
  `AsyncSession.execute` with `side_effect = OperationalError(...)` and asserts
  `pytest.raises(OperationalError)` when calling `get_active_user_by_id`.
- **F11.** The three `get_active_user_by_id` behaviour tests (active-user-found,
  unknown-id, soft-deleted-user) remain unchanged.
- **F12.** After the prune, the module contains no reference to
  `get_active_user_by_username`; every remaining test exercises a method that still
  exists on `UserLookupAdapter`.

### Residual wording invariant

- **F13.** No `ForbiddenDomainError(...)` message — nor any other user-facing string —
  in `src/app/features/posts/` mentions "username"; this is verified by search and
  recorded as a checked invariant, not a code change.

### Acceptance gate

- **F14.** The four existing outside-in tests for `create_post` (0055),
  `update_post` (0056), `erase_post` (0057), and `erase_db_post` (0058) pass green
  without modification after the removal, proving the method was genuinely unused.
- **F15.** The import-level smoke test (`tests/smoke/test_app_starts.py`) and the
  import-linter architecture gate (`lint-imports`) both pass after the removal.

## Non-functional requirements

- **N1.** `UserLookupAdapter` explicitly inherits from `UserLookupPort`
  (`class UserLookupAdapter(UserLookupPort):`). Per `agent_docs/architecture.md`
  § Terminology: port and adapter.
- **N2.** `UserLookupPort` carries `@runtime_checkable`. Per `CLAUDE.md` hard rules.
- **N3.** `UserLookupAdapter.get_active_user_by_id` contains no `try/except`; any
  infrastructure exception (e.g. `OperationalError`) propagates unchanged to the
  global handler. Per `agent_docs/error_handling.md` § Right shape: read-only query,
  no catch.
- **N4.** The modified `.py` files (`user_lookup_port.py`, `user_lookup_adapter.py`)
  retain their `# FEATURE: posts._shared — <purpose>` header on line 1. Per
  `agent_docs/stable_vs_feature.md`.
- **N5.** Files under `src/app/` use relative imports; test files use absolute imports
  through `app.*`. Per `agent_docs/architecture.md` § Import conventions.
- **N6.** No `HTTPException` is raised inside any use-case. Per `CLAUDE.md` hard rule 1.
- **N7.** No cross-slice imports; `posts/_shared/` is the only cross-use-case boundary
  within the feature. Per `CLAUDE.md` hard rule 7.
- **N8.** All I/O is `async def` + `await`; no synchronous DB calls. Per `CLAUDE.md`
  locked stack.
- **N9.** `mypy` strict passes for all modified files under `src/app/`. Per `CLAUDE.md`
  § Verifying changes.
- **N10.** `ruff format` and `ruff check` pass for all modified files. Per `CLAUDE.md`
  § Verifying changes.
- **N11.** `UserIdentity` (in `_shared/entities.py`) is unchanged and retains
  `model_config = ConfigDict(from_attributes=True)`, including its `username` field,
  which `get_active_user_by_id` still populates. Per `CLAUDE.md` locked stack
  (Pydantic v2) and PRD § What is explicitly NOT removed.
- **N12.** No STABLE file is modified by this slice; `bootstrap/container.py` wiring is
  unchanged (the single `user_lookup_adapter` provider still constructs
  `UserLookupAdapter`). Per `agent_docs/stable_vs_feature.md`.

## Out of scope

- Removing or renaming `UserIdentity.username` — retained (see N11).
- Any `User.username` display select in read adapters (`get_post`, `list_posts`,
  `list_all_posts`, `list_pending_posts`, `get_moderation_log`) or the `username`
  field in response bodies — frozen by the initiative.
- The `check_post_owner` policy — already id-based since slice 0055; unchanged here.
- Any route, schema, DI wiring, or behaviour change — dead-code removal only.
- Any database migration or ORM model change.
- The Flutter client — unaffected by an internal helper removal.

## Traceability

| Requirement | Verified by |
|---|---|
| F1, F2, F3 | code review (`_shared/user_lookup_port.py`) |
| F4, F6, F7 | code review (`_shared/user_lookup_adapter.py`) |
| F5 | `UserLookupAdapter` unit test (by-id behaviour cases) |
| F8 | code review (repo-wide grep for `get_active_user_by_username`) |
| F9, F11, F12 | `test_user_lookup_adapter.py` after prune (test inventory) |
| F10 | `UserLookupAdapter` unit test (`OperationalError` propagation, re-pointed to by-id) |
| F13 | code review (grep for "username" in posts `ForbiddenDomainError` messages) |
| F14 | four existing outside-in tests (primary acceptance gate) |
| F15 | `pytest tests/smoke/test_app_starts.py`; `lint-imports` |
| N1–N12 | code review checklist in `validation.md` |
