# 0059 · remove_username_user_lookup — Validation

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md
- Requirements: ./requirements.md

## Nature of this slice

This is a **pure dead-code removal** with no HTTP contract, schema, or behaviour
change. There is therefore no new user-visible behaviour to poke with curl. The
manual scenarios below confirm the **negative**: that removing
`get_active_user_by_username` left every consumer endpoint working and the app
booting. The substantive verification is the code review checklist plus the
automated suite (full `pytest` + smoke + `lint-imports`).

## Prerequisites

- Test database up: `docker compose up test-db -d`.
- App running locally: `uvicorn src.app.main:app --reload` from `api/`.
- A seeded active user `alice` (note her integer `id`, call it `ALICE_ID`) and a
  valid Bearer token for her (`$TOKEN`). A second active user `bob` with a token
  (`$BOB_TOKEN`) for the forbidden case.

## Manual scenarios

### S1 — App boots after the symbol is removed

**Steps:**

1. Start the app: `uvicorn src.app.main:app --reload`.
2. `curl http://localhost:8000/api/v1/health`

**Expected:**

- The app imports cleanly (no `ImportError` / `AttributeError` about
  `get_active_user_by_username`) and starts.
- Status 200 from `/api/v1/health`.

**Covers:** F8, F15.

### S2 — create_post still works (by-id author resolution intact)

**Steps:**

1. `curl -X POST http://localhost:8000/api/v1/$ALICE_ID/post -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -d '{"title": "t", "text": "body"}'`

**Expected:**

- Status 201; body is the created post; DB has a `post` row with
  `created_by_user_id = ALICE_ID`.
- Author was resolved via `get_active_user_by_id`, not the removed method.

**Covers:** F5, F14.

### S3 — create_post forbidden under another user's id

**Steps:**

1. As bob, `curl -X POST http://localhost:8000/api/v1/$ALICE_ID/post -H "Authorization: Bearer $BOB_TOKEN" -H "Content-Type: application/json" -d '{"title": "t", "text": "body"}'`

**Expected:**

- Status 403; error message does **not** contain the word "username".

**Covers:** F13, F14.

### S4 — erase_post and erase_db_post still work

**Steps:**

1. Create a post as alice (S2), note its `post_id`.
2. Soft delete: `curl -X DELETE http://localhost:8000/api/v1/post/$POST_ID -H "Authorization: Bearer $TOKEN"`
3. Recreate, then hard delete: `curl -X DELETE http://localhost:8000/api/v1/post/$POST_ID/db -H "Authorization: Bearer $TOKEN"`

**Expected:**

- Both return their normal success status; ownership is resolved by id.
- No reference to a username-based lookup is exercised.

**Covers:** F14.

### S5 — unknown / soft-deleted author resolves to "User not found"

**Steps:**

1. `curl -X POST http://localhost:8000/api/v1/999999999/post -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -d '{"title": "t", "text": "body"}'`

**Expected:**

- Status 404, message "User not found" — produced by the by-id lookup returning
  `None`, confirming `get_active_user_by_id` still drives the not-found branch.

**Covers:** F5.

## Code review checklist

Each line is a yes/no question. Reject the PR until all are yes.

### Removal correctness

- [ ] `UserLookupPort` declares exactly one method, `get_active_user_by_id`; the
      `get_active_user_by_username` declaration is gone. (F1, F2)
- [ ] `UserLookupAdapter` has no `get_active_user_by_username` method. (F4)
- [ ] `get_active_user_by_id` is byte-for-byte unchanged (query, `is_deleted`
      filter, `model_validate`, `None` path). (F5)
- [ ] Repo-wide grep for `get_active_user_by_username` under `src/app/` returns
      **zero** hits. (F8)
- [ ] No unused import was left behind in `user_lookup_adapter.py` —
      `select`, `User`, `UserIdentity`, `UserLookupPort` are all still used. (F7)

### Architecture (unchanged invariants)

- [ ] `UserLookupAdapter` still inherits its port explicitly:
      `class UserLookupAdapter(UserLookupPort):`. (N1)
- [ ] `UserLookupPort` still carries `@runtime_checkable`. (N2)
- [ ] `get_active_user_by_id` has no `try/except`; infrastructure exceptions
      propagate to the global handler. (N3)
- [ ] All imports inside `src/app/` remain **relative**. No `from app...` or
      `from src.app...` introduced. (N5)
- [ ] No cross-slice imports outside `posts/_shared/`. (N7)
- [ ] All I/O remains `async def` + `await`. (N8)

### Files and headers

- [ ] `user_lookup_port.py` and `user_lookup_adapter.py` retain their
      `# FEATURE: posts._shared — …` header on line 1. (N4)
- [ ] **No STABLE file modified.** `bootstrap/container.py` is unchanged: the
      single `user_lookup_adapter` provider and the four use-case providers that
      receive `user_lookup=user_lookup_adapter` are untouched. (N12)
- [ ] `UserIdentity` in `_shared/entities.py` is unchanged, including its
      `username` field and `model_config = ConfigDict(from_attributes=True)`. (N11)
- [ ] No `model.dict()` introduced; no behaviour, route, schema, or migration
      change anywhere in the diff.

### Residual wording

- [ ] No `ForbiddenDomainError(...)` message (or other user-facing string) under
      `src/app/features/posts/` mentions "username". (F13)

### Tests

- [ ] `test_user_lookup_adapter.py` no longer references
      `get_active_user_by_username`. (F12)
- [ ] The three `get_active_user_by_username` behaviour tests are removed. (F9)
- [ ] The `OperationalError` propagation test is re-pointed to
      `get_active_user_by_id` and still asserts `pytest.raises(OperationalError)`. (F10)
- [ ] The three `get_active_user_by_id` behaviour tests are unchanged and pass. (F11)
- [ ] The four existing outside-in tests (0055/0056/0057/0058) pass **without
      modification**. (F14)
- [ ] No new use-case, integration, or outside-in test was added — opt-outs match
      `plan.md` § 6 (no new behaviour, no new entry point).

### Quality gates

Run from `api/`:

```
ruff format src/app tests
ruff check src/app tests
mypy src/app
pytest                       # includes tests/smoke/test_app_starts.py
```

And the architecture gate from `api/src` (UTF-8):

```
lint-imports
```

All must pass. Baseline the suite before and after the change and confirm **zero
net-new failures**. If `tests/smoke/test_app_starts.py` fails, the slice is **not
done** even if every other test is green — it usually means an import that works
under pytest but breaks under uvicorn.
