# 0059 · remove_username_user_lookup — Outside-in test spec

## Goal

Confirm that removing `get_active_user_by_username` from the shared
`UserLookupPort` / `UserLookupAdapter` leaves every post write endpoint behaving
identically (proving the method was dead), and that the shared adapter test suite
still verifies the surviving `get_active_user_by_id` behaviour plus the
infrastructure-exception-propagation guarantee.

## Outside-in test: opt-out rationale

This slice introduces **no user-visible behaviour change** and **no new HTTP entry
point**. Per the PRD:

> "No new outside-in test is written — this slice has no new HTTP entry point. The
> acceptance gate is that the existing outside-in tests for `create_post`,
> `update_post`, `erase_post`, and `erase_db_post` remain green, proving the
> removed method was genuinely unused."

The acceptance gate is the **existing** outside-in tests, which exercise the full
HTTP stack of each post write endpoint end-to-end. Both the original write-path
tests and their `{username}`→`{user_id}` migration successors must stay green:

| Existing test file | Endpoint exercised | Acceptance signal |
|---|---|---|
| `tests/features/posts/0011_create_post/create_post_outside_in_test.py` | create post | Green |
| `tests/features/posts/0028_update_post/update_post_outside_in_test.py` | update post | Green |
| `tests/features/posts/0029_erase_post/erase_post_outside_in_test.py` | soft delete post | Green |
| `tests/features/posts/0030_erase_db_post/erase_db_post_outside_in_test.py` | hard delete post | Green |
| `tests/features/posts/0055_migrate_create_post_route_username_to_user_id/migrate_create_post_route_username_to_user_id_outside_in_test.py` | `POST /{author_id}/post` | Green |
| `tests/features/posts/0056_migrate_update_post_route_username_to_user_id/migrate_update_post_route_username_to_user_id_outside_in_test.py` | `PATCH /post/{id}` | Green |
| `tests/features/posts/0057_migrate_erase_post_route_username_to_user_id/migrate_erase_post_route_username_to_user_id_outside_in_test.py` | `DELETE /post/{id}` | Green |
| `tests/features/posts/0058_migrate_erase_db_post_route_username_to_user_id/migrate_erase_db_post_route_username_to_user_id_outside_in_test.py` | `DELETE /post/{id}/db` | Green |

Run command:

```
pytest tests/features/posts/ -k "outside_in" -v
```

All must be green **without modifying the test files themselves**. Any regression
in any of them is a blocking failure for this slice. (The 0055–0058 test files
mention `get_active_user_by_username` only in their header comment narrative
describing each slice's historical red-state — comments, not calls — so they need
no change.)

**Covers requirement(s):** F14, F15.

---

## Modified test: `UserLookupAdapter` unit test (the only test file this slice changes)

This slice does not add a test file; it **prunes** the existing shared adapter test
module so that every remaining test exercises a method that still exists. The
`/slice-test-red` step records the target post-prune state of this module.

### File location

`tests/features/posts/0032_extract_user_lookup/data/test_user_lookup_adapter.py`

### Entry point

Direct calls to `UserLookupAdapter.get_active_user_by_id(...)` — against the test
Postgres for behaviour cases, and with a mocked async session factory for the
propagation case. Not an HTTP test.

### Wired real

- `UserLookupAdapter` (the class under test).
- `UserLookupPort` (the contract it now satisfies with a single method).
- Test Postgres via the slice's `oit_engine` / `async_client` fixtures for the
  behaviour cases (savepoint rollback per test).

### Mocked

- For the propagation case only: `async_sessionmaker[AsyncSession]` is replaced
  with a `MagicMock`/`AsyncMock` whose `session.execute(...)` raises
  `sqlalchemy.exc.OperationalError`. No Postgres, no FastAPI app, no HTTP client in
  that case.

### Fixtures used

- `el32_alice` (slice `conftest.py`): seeds an active user `el32alice` with a known
  integer `id`.
- `async_client` (slice `conftest.py`): per-test transaction rollback; used for the
  unknown-id and soft-deleted-by-id cases that seed/query the DB directly.

### Required changes to the module

1. **Remove** the three `get_active_user_by_username` behaviour tests:
   `..._returns_user_identity_for_active_user`,
   `..._returns_none_for_unknown_username`,
   `..._returns_none_for_soft_deleted_user`. (F9)
2. **Re-point** `test_get_active_user_by_username_propagates_operational_error` to
   `get_active_user_by_id` (rename to `..._by_id_propagates_operational_error`);
   keep the mocked `OperationalError` side effect and the `pytest.raises`
   assertion. (F10)
3. **Keep** unchanged the three `get_active_user_by_id` behaviour tests. (F11)
4. **Update** the module docstring header: drop the F5/F6/F7/F8 username coverage
   note; keep the by-id and N3 coverage note. (F12)

### Test scenarios (the surviving set)

#### Scenario 1: active user found by id → `UserIdentity` returned

**Setup:**

- DB contains active user `el32alice` (via `el32_alice` fixture) with a known `id`.

**Act:**

- Call `await adapter.get_active_user_by_id(el32_alice["id"])`.

**Expect:**

- Return value is a `UserIdentity` with `id == el32_alice["id"]` and
  `username == "el32alice"`.

**Covers requirement(s):** F5.

---

#### Scenario 2: unknown id → `None` returned

**Setup:**

- No user row with id `999999999`.

**Act:**

- Call `await adapter.get_active_user_by_id(999999999)`.

**Expect:**

- Return value is `None`.

**Covers requirement(s):** F5.

---

#### Scenario 3: user exists but is soft-deleted → `None` returned

**Setup:**

- Seed a user with `is_deleted=True` inside the test transaction; capture its `id`.

**Act:**

- Call `await adapter.get_active_user_by_id(deleted_id)`.

**Expect:**

- Return value is `None` (the `is_deleted = False` predicate excludes the row).

**Covers requirement(s):** F5.

---

#### Scenario 4: infrastructure exception propagates unchanged (re-pointed)

**Setup:**

- A mocked session factory whose `session.execute(...)` raises
  `sqlalchemy.exc.OperationalError`.

**Act:**

- Call `await adapter.get_active_user_by_id(123)`.

**Expect:**

- `OperationalError` propagates out of the adapter unchanged — not caught, not
  translated; no `DomainError` raised.

**Covers requirement(s):** F10, N3.

---

## Checked invariant (verification, not a test)

After the prune, a repo-wide grep confirms `get_active_user_by_username` has zero
references under `src/app/` (F8) and that no `ForbiddenDomainError` message under
`src/app/features/posts/` mentions "username" (F13). These are review-time
verifications, not pytest cases.

## Out of scope for this test

- A new outside-in test file for this slice (opted out per PRD decision).
- New use-case, adapter, or endpoint integration tests — no new behaviour, no new
  entry point; the four write use-cases already resolve the author via
  `get_active_user_by_id` and their existing unit tests are untouched.
- Field-level validation errors (no HTTP contract change).
- Performance, load, concurrency.
