# 0010 · list_all_posts — Validation

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md
- Requirements: ./requirements.md

## Prerequisites

- App running locally (`uvicorn app.main:app --reload` from `src/`).
- Test Postgres running and migrated (`alembic upgrade head`).
- Redis running (cache decorator active).
- No Bearer token needed for the new endpoint; a token is required only for
  setup steps that create posts.

## Manual scenarios

### S0 — Setup (run once before the scenarios below)

**Steps:**

1. Register two users:
```bash
curl -s -X POST http://localhost:8000/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{"name":"Alice","username":"alice","email":"alice@example.com","password":"Password123!"}'

curl -s -X POST http://localhost:8000/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{"name":"Bob","username":"bob","email":"bob@example.com","password":"Password123!"}'
```

2. Obtain Bearer tokens for both:
```bash
curl -s -X POST http://localhost:8000/api/v1/auth/access-token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d 'username=alice&password=Password123!'
# Save as ALICE_TOKEN

curl -s -X POST http://localhost:8000/api/v1/auth/access-token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d 'username=bob&password=Password123!'
# Save as BOB_TOKEN
```

3. Create posts from both users (older posts first):
```bash
curl -s -X POST http://localhost:8000/api/v1/alice/post \
  -H "Authorization: Bearer $ALICE_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"title":"Alice Post 1","text":"Alices first post."}'

curl -s -X POST http://localhost:8000/api/v1/bob/post \
  -H "Authorization: Bearer $BOB_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"title":"Bob Post 1","text":"Bobs first post."}'

curl -s -X POST http://localhost:8000/api/v1/alice/post \
  -H "Authorization: Bearer $ALICE_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"title":"Alice Post 2","text":"Alices second post."}'
```

**Expected:** all three `POST` calls return HTTP 201.

---

### S1 — Happy path: all posts from all users

**Steps:**
```bash
curl -s http://localhost:8000/api/v1/posts | python -m json.tool
```

**Expected:**

- Status 200.
- Body is a JSON object with keys `items`, `total_count`, `page`,
  `items_per_page`.
- `total_count` is 3.
- `items` contains 3 objects, each with `id`, `title`, `text`, `media_url`,
  `created_at`, `created_by_user_id`, and `username`.
- `username` values are `"alice"` and `"bob"` as appropriate — posts from both
  users appear in the single response.
- `page` is 1, `items_per_page` is 10.

**Covers:** F1, F2, F3, F4, F5.

---

### S2 — Empty list when no posts exist

**Steps:**

1. Run this against a clean database (before S0), or temporarily rename the
   posts table to simulate an empty state:
```bash
curl -s http://localhost:8000/api/v1/posts | python -m json.tool
```

**Expected:**

- Status 200.
- `items: []`, `total_count: 0`, `page: 1`, `items_per_page: 10`.

**Covers:** F6.

---

### S3 — Newest-first ordering

**Steps:**

After S0, call:
```bash
curl -s http://localhost:8000/api/v1/posts | python -m json.tool
```

**Expected:**

- Status 200.
- The first item in `items` has the most recent `created_at` timestamp
  ("Alice Post 2"), and the last item has the oldest timestamp ("Alice Post 1").
- The ordering is strictly descending by `created_at` across all authors.

**Covers:** F11.

---

### S4 — Soft-deleted posts are excluded

**Steps:**

1. Using S0, note the `id` of "Alice Post 1".
2. Soft-delete it:
```bash
curl -s -X DELETE http://localhost:8000/api/v1/alice/post/<POST_ID> \
  -H "Authorization: Bearer $ALICE_TOKEN"
```

3. List all posts:
```bash
curl -s http://localhost:8000/api/v1/posts | python -m json.tool
```

**Expected:**

- Status 200.
- `total_count` is 2 (not 3).
- The deleted post's title does not appear in `items`.
- Both remaining posts (one from Alice, one from Bob) are present.

**Covers:** F7.

---

### S5 — Posts from soft-deleted users are excluded

**Steps:**

1. Soft-delete bob's account (requires superuser token `$SUPER_TOKEN`):
```bash
curl -s -X DELETE http://localhost:8000/api/v1/users/bob \
  -H "Authorization: Bearer $SUPER_TOKEN"
```

2. List all posts:
```bash
curl -s http://localhost:8000/api/v1/posts | python -m json.tool
```

**Expected:**

- Status 200.
- `total_count` reflects only Alice's non-deleted posts (Bob's post is gone).
- No item has `username: "bob"`.

**Covers:** F8.

---

### S6 — Pagination: correct total count and offset

**Steps:**

1. Restore the database to S0 state (3 posts from Alice and Bob).
2. Create 7 more posts (mix of Alice and Bob) so there are 10 total.
3. Request page 2 with 4 items per page:
```bash
curl -s "http://localhost:8000/api/v1/posts?page=2&items_per_page=4" | python -m json.tool
```

**Expected:**

- Status 200.
- `total_count` is 10.
- `items` contains 4 posts (items 5–8 of 10, newest-first order).
- `page` is 2, `items_per_page` is 4.
- Items are in `created_at DESC` order (the 5th-through-8th newest posts
  globally).

**Covers:** F9, F10.

---

### S7 — No authentication required

**Steps:**

Call the endpoint without any Authorization header:
```bash
curl -s http://localhost:8000/api/v1/posts | python -m json.tool
```

**Expected:**

- Status 200.
- Full `ListAllPostsResponse` body returned, identical to the authenticated
  response.
- No 401 or 403 error.

**Covers:** F14.

---

### S8 — Invalid `page` parameter

**Steps:**
```bash
curl -s "http://localhost:8000/api/v1/posts?page=0"
```

**Expected:**

- Status 422.
- Body contains a Pydantic validation error message referencing `page`.

**Covers:** F12.

---

### S9 — Invalid `items_per_page` (too low)

**Steps:**
```bash
curl -s "http://localhost:8000/api/v1/posts?items_per_page=0"
```

**Expected:**

- Status 422.
- Body contains a Pydantic validation error message referencing
  `items_per_page`.

**Covers:** F13.

---

### S10 — Invalid `items_per_page` (too high)

**Steps:**
```bash
curl -s "http://localhost:8000/api/v1/posts?items_per_page=101"
```

**Expected:**

- Status 422.
- Body contains a Pydantic validation error message referencing
  `items_per_page`.

**Covers:** F13.

---

### S11 — Cache: repeated request served from Redis

**Steps:**

1. Make the first request and note the response time:
```bash
time curl -s http://localhost:8000/api/v1/posts > /dev/null
```

2. Make the same request again within 60 seconds:
```bash
time curl -s http://localhost:8000/api/v1/posts > /dev/null
```

3. Optionally verify the key exists in Redis:
```bash
redis-cli keys "*all_posts*"
```

**Expected:**

- Both requests return HTTP 200 with identical bodies.
- The second request is visibly faster (served from Redis, no DB round-trip).
- A Redis key matching `all_posts:page_1:items_per_page:10` exists during the
  60-second TTL.

**Covers:** F15.

---

## Code review checklist

### Architecture

- [ ] Slice folder exists at `src/app/features/posts/list_all_posts/` with
      `domain/`, `data/`, and `presentation/` subfolders, each with an
      `__init__.py`.
- [ ] `ListAllPostsUseCase` is a class; its only public method is `__call__`,
      which takes a `ListAllPostsQuery` and returns a `PostPage`.
- [ ] `ListAllPostsPort` lives in `domain/ports/`, carries
      `@runtime_checkable`, and inherits from `typing.Protocol`.
- [ ] `ListAllPostsAdapter` class signature is
      `class ListAllPostsAdapter(ListAllPostsPort):` — explicit inheritance from
      the port is mandatory.
- [ ] `ListAllPostsAdapter` is the only place SQLAlchemy is imported in this
      slice.
- [ ] The router endpoint accepts `request: Request`, builds a
      `ListAllPostsQuery`, awaits the use-case, and returns a
      `ListAllPostsResponse` — no business logic in the endpoint function.
- [ ] No file in `list_all_posts/` imports from another slice's `domain/`,
      `data/`, or `presentation/` folder; cross-slice access goes only through
      `features/posts/_shared/`.
- [ ] All imports inside `src/app/features/posts/list_all_posts/` use
      **relative** paths. No `from app…` or `from src.app…` anywhere in source.
- [ ] `ListAllPostsUseCase` contains no import from FastAPI, SQLAlchemy, or
      any adapter module.
- [ ] No `HTTPException` is raised anywhere in the use-case.

### Shared entities migration

- [ ] `features/posts/_shared/entities.py` exists and defines `PostItem` and
      `PostPage`.
- [ ] `features/posts/_shared/entities.py` starts with
      `# FEATURE: posts._shared — PostItem and PostPage domain entities.` on
      line 1.
- [ ] `list_posts/domain/entities.py` no longer exists (file deleted).
- [ ] `list_posts/domain/ports/list_posts_port.py` imports `PostPage` from
      `_shared/entities.py` via a relative path (five dots from `ports/`).
- [ ] `list_posts/domain/use_case.py` imports `PostPage` from `_shared/entities.py`
      via a relative path (three dots from `domain/`).
- [ ] `list_posts/data/adapter.py` imports `PostItem` and `PostPage` from
      `_shared/entities.py` via a relative path (three dots from `data/`).
- [ ] All existing `list_posts` tests still pass after the migration.

### Query correctness

- [ ] The adapter performs a JOIN between `post` and `user` on
      `post.created_by_user_id = user.id`.
- [ ] Both the COUNT and the row queries filter `post.is_deleted == False` and
      `user.is_deleted == False`.
- [ ] No `WHERE user.username = ...` filter is present — all non-deleted users'
      posts are returned.
- [ ] The row query includes `.order_by(Post.created_at.desc())`.
- [ ] The `username` field in each `PostItem` is taken from `user.username` in
      the query result, not from any request parameter.
- [ ] `total_count` is computed from a `SELECT COUNT(*)` with the same filters
      and JOIN as the row query — not from `len(items)`.
- [ ] Offset is computed as `(page - 1) * items_per_page`.

### Error handling

- [ ] `ListAllPostsAdapter.list` has **no `try/except`** — this is a
      read-only query with no business-meaningful exception path. Infrastructure
      failures propagate to the global handler.
- [ ] The use-case has no `try/except`.
- [ ] Adapter does not log exceptions.
- [ ] No new `DomainError` subclass was added in the slice folder.

### Cache

- [ ] The `@cache` decorator is applied to the `GET /posts` endpoint in
      `presentation/router.py`.
- [ ] The cache key prefix is exactly
      `all_posts:page_{page}:items_per_page:{items_per_page}` (no username
      component).
- [ ] `expiration=60` is set on the `@cache` decorator.
- [ ] `request: Request` is the first parameter of the endpoint function
      (required by the `@cache` decorator).
- [ ] No `resource_id_name` is passed to `@cache` (there is no per-user
      resource ID for this endpoint).

### Files and headers

- [ ] Every new `.py` file in `list_all_posts/` starts with
      `# FEATURE: list_all_posts — <purpose>` on line 1.
- [ ] `features/posts/router.py` includes the `list_all_posts` router via
      `router.include_router(list_all_posts_router)`.
- [ ] `bootstrap/container.py` has `list_all_posts_adapter` and
      `list_all_posts_use_case` providers added.
- [ ] `bootstrap/router.py` is **unchanged**.
- [ ] Pydantic presentation schemas (`PostItemSchema`, `ListAllPostsResponse`)
      carry `model_config = ConfigDict(from_attributes=True)`.
- [ ] No `model.dict()` — only `model.model_dump()` if used.

### DI

- [ ] `list_all_posts_adapter` provider in `Container` is a `providers.Factory`
      that receives `session_factory`.
- [ ] `list_all_posts_use_case` provider in `Container` is a `providers.Factory`
      that receives `list_all_posts_adapter`.
- [ ] The router uses the `_get_list_all_posts_use_case()` lazy-import helper
      pattern (consistent with `list_posts` and other slice routers in this
      codebase).

### Tests

- [ ] Use-case unit test exists at
      `tests/features/posts/0010_list_all_posts/domain/test_use_case.py` and
      passes.
- [ ] Adapter unit test exists at
      `tests/features/posts/0010_list_all_posts/data/test_adapter.py`, uses real
      Postgres, and covers: happy path with JOIN result (multiple users), correct
      `ORDER BY created_at DESC`, exclusion of soft-deleted posts, exclusion of
      posts from soft-deleted users, and correct pagination offset.
- [ ] Endpoint integration test exists at
      `tests/features/posts/0010_list_all_posts/presentation/test_router.py` and
      uses `httpx.AsyncClient` with `db_session`.
- [ ] Outside-in test exists at
      `tests/features/posts/0010_list_all_posts/list_all_posts_outside_in_test.py`
      and is **GREEN**.
- [ ] No test calls `session.commit()` (defeats rollback fixture).
- [ ] All pre-existing `list_posts` tests remain GREEN after the `_shared/`
      entity migration.

### Quality gates

Run from project root:

```
ruff format src/app tests
ruff check src/app tests
mypy src/app
pytest
```

All must pass. The smoke test (`tests/smoke/test_app_starts.py`) boots the app
via a real uvicorn subprocess. If it fails after this slice's changes, the most
likely cause is a relative import mistakenly written as an absolute import inside
`src/app/` — check every new file's import lines, and also check the updated
`list_posts` files for import regressions introduced during the `_shared/`
migration.
