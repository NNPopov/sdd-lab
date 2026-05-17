# 0022 · list_all_posts_visibility — Validation

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md
- Requirements: ./requirements.md

## Prerequisites

- App running locally (`uvicorn app.main:app --reload` from `src/`).
- Redis running (the `@cache` decorator needs a client).
- Test database available. A default superuser and tier exist (seeded via
  `python -m scripts.create_first_superuser` and `python -m scripts.create_first_tier`).
- `jq` installed for readable JSON output (optional).

### Prerequisite setup — seed data for all scenarios

Run these once before the manual scenarios. Replace `<SUPERUSER_TOKEN>` with the JWT
obtained by logging in as the superuser.

```bash
# 1. Obtain superuser token
curl -s -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admin&password=<SUPERUSER_PASSWORD>" | jq .access_token

# 2. Register alice (regular user)
curl -s -X POST http://localhost:8000/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{"name":"Alice","username":"alice22","email":"alice22@example.com","password":"Pa$$w0rd1"}' | jq .

# 3. Obtain alice token
curl -s -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=alice22&password=Pa$$w0rd1" | jq .access_token

# 4. alice creates two posts (both start as pending_review)
curl -s -X POST http://localhost:8000/api/v1/posts \
  -H "Authorization: Bearer <ALICE_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{"title":"Pending Post","text":"Still under review."}' | jq .

curl -s -X POST http://localhost:8000/api/v1/posts \
  -H "Authorization: Bearer <ALICE_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{"title":"Approved Post","text":"Cleared by mod."}' | jq .

# 5. Set the second post to approved via the moderate-post endpoint
#    (Replace <POST_ID> with the id returned in step 4b)
curl -s -X PATCH http://localhost:8000/api/v1/posts/<POST_ID>/moderate \
  -H "Authorization: Bearer <SUPERUSER_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{"decision":"approve"}' | jq .

# 6. Register mod (regular user, then assign moderator role)
curl -s -X POST http://localhost:8000/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{"name":"Mod","username":"mod22","email":"mod22@example.com","password":"Pa$$w0rd2"}' | jq .

curl -s -X POST http://localhost:8000/api/v1/users/mod22/moderator \
  -H "Authorization: Bearer <SUPERUSER_TOKEN>" | jq .

# 7. Obtain mod token
curl -s -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=mod22&password=Pa$$w0rd2" | jq .access_token
```

After setup: two posts exist — one `pending_review`, one `approved`.

---

## Manual scenarios

### S1 — Unauthenticated caller sees only approved posts

**Steps:**

```bash
curl -s http://localhost:8000/api/v1/posts | jq .
```

**Expected:**

- Status 200.
- `total_count == 1`.
- `items` contains exactly one post with `title == "Approved Post"` and
  `status == "approved"`.
- The `pending_review` post is absent.

**Covers:** F1, F2, F6, F8.

---

### S2 — Authenticated regular user sees only approved posts

**Steps:**

```bash
curl -s http://localhost:8000/api/v1/posts \
  -H "Authorization: Bearer <ALICE_TOKEN>" | jq .
```

**Expected:**

- Status 200.
- `total_count == 1`.
- `items` contains exactly one post with `status == "approved"`.
- The `pending_review` post is absent.

**Covers:** F1, F3, F6, F8.

---

### S3 — Moderator sees all posts regardless of status

**Steps:**

```bash
curl -s http://localhost:8000/api/v1/posts \
  -H "Authorization: Bearer <MOD_TOKEN>" | jq .
```

**Expected:**

- Status 200.
- `total_count == 2`.
- `items` contains both posts; one with `status == "approved"` and one with
  `status == "pending_review"`.

**Covers:** F1, F4, F6, F8.

---

### S4 — Superuser sees all posts regardless of status

**Steps:**

```bash
curl -s http://localhost:8000/api/v1/posts \
  -H "Authorization: Bearer <SUPERUSER_TOKEN>" | jq .
```

**Expected:**

- Status 200.
- `total_count == 2`.
- Both posts appear in `items`.

**Covers:** F1, F5, F6, F8.

---

### S5 — Empty result when no approved posts and caller is unauthenticated

**Steps:**

1. Use a fresh database state (or temporarily revert the approval from setup step 5 by
   sending a `changes_requested` decision on the approved post).
2. `curl -s http://localhost:8000/api/v1/posts | jq .`

**Expected:**

- Status 200.
- `items == []`.
- `total_count == 0`.

**Covers:** F1, F7.

---

### S6 — `status` field present in every response item for all callers

**Steps:**

```bash
curl -s http://localhost:8000/api/v1/posts | jq '.items[].status'
curl -s http://localhost:8000/api/v1/posts \
  -H "Authorization: Bearer <MOD_TOKEN>" | jq '.items[].status'
```

**Expected:**

- Both commands return non-null string values for every item.
- First command returns `"approved"` for the single visible item.
- Second command returns `"approved"` and `"pending_review"` across the two items.

**Covers:** F8.

---

### S7 — Newest-first ordering is preserved after visibility filter

**Steps:**

```bash
# Create a third post as alice, then approve it
curl -s -X POST http://localhost:8000/api/v1/posts \
  -H "Authorization: Bearer <ALICE_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{"title":"Second Approved Post","text":"Also approved."}' | jq .id

# Approve the new post (replace <NEW_POST_ID>)
curl -s -X PATCH http://localhost:8000/api/v1/posts/<NEW_POST_ID>/moderate \
  -H "Authorization: Bearer <SUPERUSER_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{"decision":"approve"}' | jq .

# Query as unauthenticated caller
curl -s http://localhost:8000/api/v1/posts | jq '[.items[].title]'
```

**Expected:**

- "Second Approved Post" appears before "Approved Post" (newest first).
- The `pending_review` post remains absent.

**Covers:** F9.

---

### S8 — 0010 outside-in test remains green

**Steps:**

1. After updating the 0010 conftest to set `status='approved'` on seeded posts, run:
   ```bash
   pytest tests/features/posts/0010_list_all_posts/list_all_posts_outside_in_test.py -v
   ```

**Expected:**

- All tests in the 0010 file pass.
- `total_count == 3` still asserts correctly because all three seeded posts are now
  `approved`.

**Covers:** F14.

---

### S9 — Cache entries are segregated by view

**Steps:**

```bash
# 1. Call the endpoint unauthenticated (populates public cache entry)
curl -s http://localhost:8000/api/v1/posts | jq .total_count

# 2. Call the endpoint as moderator (populates privileged cache entry)
curl -s http://localhost:8000/api/v1/posts \
  -H "Authorization: Bearer <MOD_TOKEN>" | jq .total_count
```

**Expected:**

- Step 1 returns `total_count == 1` (only approved).
- Step 2 returns `total_count == 2` (all posts).
- The moderator's response never returns `1`, confirming the cache is not shared.

**Note:** direct Redis key inspection (`redis-cli keys "all_posts:*"`) can confirm
the two separate key patterns (`all_posts:public:*` and `all_posts:privileged:*`)
are written, but this is optional for manual validation.

**Covers:** F12, F13.

---

## Code review checklist

### Architecture

- [ ] The three modified files (`commands.py`, `adapter.py`, `router.py`) all retain
      their `# FEATURE:` header on line 1.
- [ ] No new files are created inside `list_all_posts/`; this is a modification-only
      slice.
- [ ] `ListAllPostsUseCase` is unchanged — it remains a thin pass-through. No business
      logic was added to the use-case.
- [ ] `ListAllPostsAdapter` explicitly inherits from `ListAllPostsPort`
      (`class ListAllPostsAdapter(ListAllPostsPort):`). The inheritance line is
      unchanged.
- [ ] Adapter is the only place the `status = 'approved'` filter is applied; the
      use-case and router do not replicate the filtering logic.
- [ ] `get_optional_user` is imported from `features/users/dependencies.py` using a
      relative import inside `list_all_posts/presentation/router.py`.
- [ ] No cross-slice imports other than the one `get_optional_user` import from the
      users feature's `dependencies.py` (a shared dependency, permitted per
      `agent_docs/architecture.md`).
- [ ] All imports inside `src/app/` are relative (`from .....features.users.dependencies
      import get_optional_user`, etc.). No `from app...` or `from src.app...` inside
      source.
- [ ] No `HTTPException` raised in `ListAllPostsUseCase` or `ListAllPostsAdapter`.

### Error handling

- [ ] `ListAllPostsAdapter.list()` has no `try/except` block — it is a read-only query
      with no business-meaningful exception path (per `agent_docs/error_handling.md`
      § Right shape: read-only query, no catch).
- [ ] No new `DomainError` subclass was added anywhere in the slice folder. No new
      subclass was added to `app/domain/errors.py` either (none is needed).

### Query and filter

- [ ] The `WHERE status = 'approved'` clause is applied to **both** the count query
      and the rows query when `query.requester_is_privileged` is `False`.
- [ ] When `query.requester_is_privileged` is `True`, neither the count query nor the
      rows query carries the status filter.
- [ ] `total_count` reflects the filtered count for non-privileged callers and the
      unfiltered count for privileged callers.
- [ ] `status=post.status` is present in the `PostItem` constructor inside the list
      comprehension (mapping in place from slice 0021 — confirm it was not removed).

### Cache key

- [ ] The `@cache` key_prefix is
      `"all_posts:{view}:page_{page}:items_per_page:{items_per_page}"`.
- [ ] `view` is injected as an endpoint parameter via `Depends(_get_view)` so the
      cache decorator can interpolate it from kwargs.
- [ ] `_get_view` returns `"privileged"` when `is_moderator` or `is_superuser` is
      truthy; `"public"` otherwise.
- [ ] Any existing cache invalidation patterns on write/patch/delete endpoints use
      `all_posts:*`, confirming they still cover both `all_posts:public:*` and
      `all_posts:privileged:*` without modification.

### DI and STABLE files

- [ ] `bootstrap/container.py` was **not** modified (no new providers needed).
- [ ] `bootstrap/router.py` was **not** modified (endpoint path unchanged).
- [ ] No Alembic migration was generated (no new columns or tables).

### Pre-condition: 0010 fixture update

- [ ] `tests/features/posts/0010_list_all_posts/conftest.py` sets `status='approved'`
      on every post created in `seed_users_and_posts`.
- [ ] The 0010 outside-in test (`list_all_posts_outside_in_test.py`) is green after
      the conftest update.
- [ ] The conftest update was committed **before** any production code change.

### Tests

- [ ] Use-case unit test is explicitly opted out (use-case is a pass-through; no new
      logic) and the opt-out is documented in `tests.md` or test folder README.
- [ ] Adapter unit test exists at
      `tests/features/posts/0022_list_all_posts_visibility/data/test_adapter.py`
      and uses a real async session (no mocks for the DB).
- [ ] Adapter unit test asserts both privilege levels (`requester_is_privileged=False`
      and `requester_is_privileged=True`) and verifies `total_count` and `status`
      field mapping for each.
- [ ] Endpoint integration test exists at
      `tests/features/posts/0022_list_all_posts_visibility/presentation/test_router.py`
      and covers unauthenticated, regular user, moderator, superuser, and empty-result
      scenarios.
- [ ] Outside-in test exists at
      `tests/features/posts/0022_list_all_posts_visibility/list_all_posts_visibility_outside_in_test.py`
      and is **green** (acceptance gate).
- [ ] All pre-existing outside-in tests remain green (run full `pytest`).

### Quality gates

Run from project root:

```
ruff format src/app tests
ruff check src/app tests
mypy src/app
pytest
```

All must pass. The smoke test inside `pytest` boots the app and pings `/api/v1/health`.
If it fails, the slice is **not done** — typically caused by an accidental absolute
import (`from app...`) inside `src/app/`.
