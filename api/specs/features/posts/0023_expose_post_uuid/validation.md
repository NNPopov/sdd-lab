# 0023 · expose_post_uuid — Validation

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md
- Requirements: ./requirements.md

## Prerequisites

- App running locally (`uvicorn app.main:app --reload` from `src/`).
- Test database seeded with a superuser (run `python -m scripts.create_first_superuser`).
- Register `alice` and obtain a Bearer token (see S1). Keep the token in a shell
  variable for reuse: `TOKEN=<value>`.
- Note the `id` and `post_uuid` of the created post for use in later scenarios.

---

## Manual scenarios

### S1 — Create a post and confirm `post_uuid` is present (F3, F5)

**Steps:**

```bash
# 1. Register alice
curl -s -X POST http://localhost:8000/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{"username": "alice", "email": "alice@example.com", "password": "Pa$$w0rd1"}' | jq .

# 2. Log in and capture token
TOKEN=$(curl -s -X POST http://localhost:8000/api/v1/login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=alice&password=Pa%24%24w0rd1" | jq -r '.access_token')

# 3. Create a post
curl -s -X POST http://localhost:8000/api/v1/alice/post \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"title": "Hello World", "text": "My first post content here."}' | jq .
```

**Expected:**

- Step 1: HTTP 201, response contains `id` and `username: "alice"`.
- Step 3: HTTP 201, response body contains `post_uuid` as a non-null UUID string
  (e.g. `"019xxx-..."`) alongside `id`, `title`, `text`, `status`.
- Save the `id` and `post_uuid` from step 3 for use in S2–S5.

**Covers:** F3, F5 (source of truth UUID for comparison in later scenarios).

---

### S2 — List user posts and confirm `post_uuid` in items (F1)

**Steps:**

```bash
# Approve the post directly in psql (or via a moderator account) so it appears
# in the public feed; as author, alice sees it regardless of status.
curl -s -X GET "http://localhost:8000/api/v1/alice/posts" \
  -H "Authorization: Bearer $TOKEN" | jq '.items[0]'
```

**Expected:**

- HTTP 200.
- First item in `items` contains `post_uuid` as a valid UUID string.
- The `post_uuid` value matches the one captured in S1 step 3.

**Covers:** F1, F5.

---

### S3 — List all posts (global feed) and confirm `post_uuid` in items (F2)

**Steps:**

```bash
# The post must be approved to appear in the public feed. If not done already,
# update it directly in the database: UPDATE post SET status = 'approved' WHERE ...
curl -s -X GET "http://localhost:8000/api/v1/posts" | jq '.items[0]'
```

**Expected:**

- HTTP 200.
- First item in `items` contains `post_uuid` as a valid UUID string.
- The `post_uuid` value matches the one captured in S1 step 3.

**Covers:** F2, F5.

---

### S4 — Read single post and confirm `post_uuid` in response (F4, F9)

**Steps:**

```bash
# Replace {id} with the post id captured in S1 step 3
curl -s -X GET "http://localhost:8000/api/v1/alice/post/{id}" | jq .
```

**Expected:**

- HTTP 200.
- Response body contains `post_uuid` as a valid UUID string.
- Response body does **not** contain a top-level `uuid` key (the ORM column
  name must not leak through; only `post_uuid` appears).
- The `post_uuid` value matches the one captured in S1 step 3.

**Covers:** F4, F5, F9.

---

### S5 — `patch_post` response does not include `post_uuid` (F10)

**Steps:**

```bash
curl -s -X PATCH "http://localhost:8000/api/v1/alice/post/{id}" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"title": "Updated Title"}' | jq .
```

**Expected:**

- HTTP 200.
- Response body is `{"message": "Post updated"}` — no `post_uuid` field.

**Covers:** F10.

---

### S6 — `erase_post` response does not include `post_uuid` (F10)

**Steps:**

```bash
# Create a second post to delete (reuse S1 step 3 with a different title)
curl -s -X POST http://localhost:8000/api/v1/alice/post \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"title": "To Delete", "text": "This will be deleted shortly."}' | jq .

# Delete it — replace {id2} with the new post id
curl -s -X DELETE "http://localhost:8000/api/v1/alice/post/{id2}" \
  -H "Authorization: Bearer $TOKEN" | jq .
```

**Expected:**

- DELETE returns HTTP 200 with `{"message": "Post deleted"}` — no `post_uuid`.

**Covers:** F10.

---

### S7 — Existing `list_pending_posts` response is unchanged (F11)

**Steps:**

```bash
# Log in as superuser or moderator
MOD_TOKEN=$(curl -s -X POST http://localhost:8000/api/v1/login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admin&password=<superuser_password>" | jq -r '.access_token')

curl -s -X GET "http://localhost:8000/api/v1/posts/pending" \
  -H "Authorization: Bearer $MOD_TOKEN" | jq '.items[0] | keys'
```

**Expected:**

- HTTP 200.
- Each item already contains `post_uuid` (from slice 0019); the key is present
  and the value is a valid UUID.
- No regression in the field list compared to pre-0023 behaviour.

**Covers:** F11.

---

## Code review checklist

This slice modifies existing files only — no new use-case, port, adapter class,
DI providers, or router is introduced. The checklist is adapted accordingly.

### Field mapping correctness

- [ ] `PostItem` in `posts/_shared/entities.py` has `post_uuid: uuid.UUID` (required,
      not `Optional`).
- [ ] `ListPostsAdapter.list()` passes `post_uuid=post.uuid` in every `PostItem(...)`
      constructor call; no item can be constructed without it.
- [ ] `ListAllPostsAdapter.list()` passes `post_uuid=post.uuid` in every `PostItem(...)`
      constructor call.
- [ ] `CreatePostAdapter.create()` uses explicit construction (not `model_validate(post)`)
      and passes `post_uuid=post.uuid`; matches the `list_pending_posts` pattern.
- [ ] `CreatedPost` in `create_post/domain/entities.py` has `post_uuid: uuid.UUID`.
- [ ] `CreatePostResponse` in `create_post/presentation/schemas.py` has `post_uuid: uuid.UUID`.
- [ ] `PostItemSchema` in `list_posts/presentation/schemas.py` has `post_uuid: uuid.UUID`.
- [ ] `PostItemSchema` in `list_all_posts/presentation/schemas.py` has `post_uuid: uuid.UUID`.
- [ ] `PostRead` in `posts/schemas.py` has `uuid: uuid_pkg.UUID = Field(exclude=True)` so
      FastCRUD selects the column but it is not serialised.
- [ ] `PostRead` has a `@computed_field @property post_uuid` that returns `self.uuid`; this
      is the only `post_uuid`-bearing field in the JSON response.
- [ ] The JSON response for `GET /api/v1/{username}/post/{id}` contains `post_uuid` and
      does **not** contain a top-level `uuid` key.

### No regressions introduced

- [ ] No STABLE file is modified: `Post` ORM model, `bootstrap/container.py`,
      `bootstrap/router.py`, and `domain/errors.py` are untouched.
- [ ] No new DI provider was added (none needed — existing providers absorb the change).
- [ ] No new router registration was added in `bootstrap/router.py`.
- [ ] No database migration file was added or modified.
- [ ] `list_pending_posts` files are untouched.
- [ ] `patch_post` and `erase_post` endpoint handlers are untouched.

### Error handling

- [ ] No new `try/except` block was added; field mapping is mechanical.
- [ ] No new `DomainError` subclass was introduced.
- [ ] No `HTTPException` is raised in any modified code path.
- [ ] Adapter does not log; global handler is the sole logging point.

### Code shape

- [ ] All modified `.py` files retain `# FEATURE: <slice> — <purpose>` on line 1.
- [ ] All new test `.py` files carry `# FEATURE: expose_post_uuid — <purpose>` on line 1.
- [ ] All imports inside `src/app/` are relative (`from ..domain...`); no `from app...`
      appears inside source files.
- [ ] Test files use absolute imports (`from app.features.posts...`).
- [ ] No `model.dict()` — only `model.model_dump()`.
- [ ] Pydantic schemas that wrap Pydantic entities via `model_validate` have
      `model_config = ConfigDict(from_attributes=True)`.

### Tests

- [ ] Adapter unit test (`test_adapters.py`) exists and verifies that `post_uuid` in the
      returned `PostItem` matches the seeded `Post.uuid` for both `list_posts` and
      `list_all_posts` adapters.
- [ ] Endpoint integration test (`test_router.py`) exists and asserts `post_uuid` is
      present and is a valid UUID in all four endpoint responses.
- [ ] Endpoint integration test asserts all four `post_uuid` values for the same post
      are identical.
- [ ] Outside-in test (`expose_post_uuid_outside_in_test.py`) exists, is the acceptance
      gate, and is GREEN.
- [ ] All previously green tests remain green, including:
      - `tests/features/posts/0009_list_posts/`
      - `tests/features/posts/0010_list_all_posts/`
      - `tests/features/posts/0011_create_post/`
      - `tests/features/posts/0022_list_all_posts_visibility/`
      - `tests/smoke/test_app_starts.py`

### Quality gates

Run from project root:

```
ruff format src/app tests
ruff check src/app tests
mypy src/app
pytest
```

All must pass. If the smoke test at `tests/smoke/test_app_starts.py` fails, the slice is
**not done** even if every other test is green — it usually means an accidental absolute
import inside `src/app/` that breaks under uvicorn.
