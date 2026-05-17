# 0009 · list_posts — Validation

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md
- Requirements: ./requirements.md

## Prerequisites

- App running locally (`uvicorn app.main:app --reload` from `src/`).
- Test Postgres running and migrated (`alembic upgrade head`).
- Redis running (cache decorator active).
- A registered user and a valid Bearer token at hand — see S0 below for setup.

## Manual scenarios

### S0 — Setup (run once before the scenarios below)

**Steps:**

1. Register a user:
```bash
curl -s -X POST http://localhost:8000/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{"name":"Alice","username":"alice","email":"alice@example.com","password":"Password123!"}'
```

2. Obtain a Bearer token:
```bash
curl -s -X POST http://localhost:8000/api/v1/auth/access-token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d 'username=alice&password=Password123!'
```
Save the returned `access_token` as `TOKEN`.

3. Create two posts:
```bash
curl -s -X POST http://localhost:8000/api/v1/alice/post \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"title":"First Post","text":"Content of the first post."}'

curl -s -X POST http://localhost:8000/api/v1/alice/post \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"title":"Second Post","text":"Content of the second post."}'
```

**Expected:** both `POST` calls return HTTP 201.

---

### S1 — Happy path: list posts for existing user

**Steps:**
```bash
curl -s http://localhost:8000/api/v1/alice/posts | python -m json.tool
```

**Expected:**

- Status 200.
- Body is a JSON object with keys `items`, `total_count`, `page`, `items_per_page`.
- `total_count` is 2.
- `items` contains 2 objects, each with `id`, `title`, `text`, `media_url`,
  `created_at`, `created_by_user_id`, and `username`.
- `username` in every item is `"alice"` (resolved via JOIN, not the URL parameter).
- `page` is 1, `items_per_page` is 10.

**Covers:** F1, F2, F3, F4.

---

### S2 — Non-existent username returns empty list

**Steps:**
```bash
curl -s http://localhost:8000/api/v1/nobody/posts | python -m json.tool
```

**Expected:**

- Status 200.
- `items: []`, `total_count: 0`, `page: 1`, `items_per_page: 10`.

**Covers:** F5.

---

### S3 — Existing user with no posts returns empty list

**Steps:**

1. Register a second user with no posts:
```bash
curl -s -X POST http://localhost:8000/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{"name":"Bob","username":"bob","email":"bob@example.com","password":"Password123!"}'
```

2. List their posts:
```bash
curl -s http://localhost:8000/api/v1/bob/posts | python -m json.tool
```

**Expected:**

- Status 200.
- `items: []`, `total_count: 0`.

**Covers:** F6.

---

### S4 — Soft-deleted posts are excluded

**Steps:**

1. Using S0, note the `id` of the first created post.
2. Soft-delete it (requires alice's Bearer token):
```bash
curl -s -X DELETE http://localhost:8000/api/v1/alice/post/<POST_ID> \
  -H "Authorization: Bearer $TOKEN"
```

3. List alice's posts:
```bash
curl -s http://localhost:8000/api/v1/alice/posts | python -m json.tool
```

**Expected:**

- Status 200.
- `total_count` is 1 (not 2).
- `items` contains only the non-deleted post.

**Covers:** F7.

---

### S5 — Pagination: correct page size and offset

**Steps:**

1. Using alice's token, create 8 additional posts so alice has 9 total
   non-deleted posts.
2. Request page 2 with 5 items per page:
```bash
curl -s "http://localhost:8000/api/v1/alice/posts?page=2&items_per_page=5" | python -m json.tool
```

**Expected:**

- Status 200.
- `total_count` is 9.
- `items` contains 4 posts (items 6–9 of 9).
- `page` is 2, `items_per_page` is 5.

**Covers:** F9, F10.

---

### S6 — Invalid `page` parameter

**Steps:**
```bash
curl -s "http://localhost:8000/api/v1/alice/posts?page=0"
```

**Expected:**

- Status 422.
- Body contains a Pydantic validation error message referencing `page`.

**Covers:** F11.

---

### S7 — Invalid `items_per_page` parameter (too low)

**Steps:**
```bash
curl -s "http://localhost:8000/api/v1/alice/posts?items_per_page=0"
```

**Expected:**

- Status 422.
- Body contains a Pydantic validation error message referencing `items_per_page`.

**Covers:** F12.

---

### S8 — Invalid `items_per_page` parameter (too high)

**Steps:**
```bash
curl -s "http://localhost:8000/api/v1/alice/posts?items_per_page=101"
```

**Expected:**

- Status 422.
- Body contains a Pydantic validation error message referencing `items_per_page`.

**Covers:** F12.

---

### S9 — Cache: repeated request is served from Redis

**Steps:**

1. Make the first request and note response time:
```bash
time curl -s http://localhost:8000/api/v1/alice/posts > /dev/null
```

2. Make the same request again within 60 seconds:
```bash
time curl -s http://localhost:8000/api/v1/alice/posts > /dev/null
```

3. Check Redis for the cached key (optional):
```bash
redis-cli keys "*alice_posts*"
```

**Expected:**

- Both requests return HTTP 200 with identical bodies.
- Second request is visibly faster (served from Redis, no DB round-trip).
- The Redis key matching `alice_posts:page_1:items_per_page_10` exists during
  the 60-second TTL.

**Covers:** F13.

---

### S10 — Cache key compatibility with write-side invalidation

**Steps:**

1. List alice's posts to warm the cache:
```bash
curl -s http://localhost:8000/api/v1/alice/posts > /dev/null
```

2. Patch a post (triggers cache invalidation):
```bash
curl -s -X PATCH http://localhost:8000/api/v1/alice/post/<POST_ID> \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"title":"Updated Title"}'
```

3. List alice's posts again:
```bash
curl -s http://localhost:8000/api/v1/alice/posts | python -m json.tool
```

**Expected:**

- Third request reflects the updated title (cache was invalidated by the patch).
- Response is not stale.

**Covers:** F14.

---

## Code review checklist

### Architecture

- [ ] Slice folder exists at `src/app/features/posts/list_posts/` with
      `domain/`, `data/`, and `presentation/` subfolders, each with an
      `__init__.py`.
- [ ] `ListPostsUseCase` is a class; its only public method is `__call__`,
      which takes a `ListPostsQuery` and returns a `PostPage`.
- [ ] `ListPostsPort` lives in `domain/ports/`, carries `@runtime_checkable`,
      and inherits from `typing.Protocol`.
- [ ] `ListPostsAdapter` class signature is `class ListPostsAdapter(ListPostsPort):` —
      explicit inheritance from the port is mandatory.
- [ ] `ListPostsAdapter` is the only place SQLAlchemy is imported in this slice.
- [ ] The router endpoint accepts `request: Request`, builds a `ListPostsQuery`,
      awaits the use-case, and returns a `ListPostsResponse` — no business logic
      in the endpoint function.
- [ ] No file in `list_posts/` imports from another slice's `domain/`, `data/`,
      or `presentation/` folder.
- [ ] All imports inside `src/app/features/posts/list_posts/` use **relative**
      paths (e.g. `from ..domain.commands import ListPostsQuery`). No `from app…`
      or `from src.app…` anywhere in source.
- [ ] `ListPostsUseCase` contains no import from FastAPI, SQLAlchemy, or any
      adapter module.
- [ ] No `HTTPException` is raised anywhere in the use-case.

### Query correctness

- [ ] The adapter performs a JOIN between `post` and `user` on
      `post.created_by_user_id = user.id` — not two separate sequential queries.
- [ ] Both the COUNT and the row queries filter `post.is_deleted == False` and
      `user.is_deleted == False`.
- [ ] The `username` field in each `PostItem` is taken from `user.username` in
      the query result, not from the `ListPostsQuery.username` path parameter.
- [ ] `total_count` is computed from a `SELECT COUNT(*)` with the same filters
      and JOIN as the row query — not from `len(items)`.
- [ ] Offset is computed as `(page - 1) * items_per_page`.

### Error handling

- [ ] `ListPostsAdapter.list` has **no `try/except`** — this is a read-only
      query with no business-meaningful exception path. Infrastructure failures
      propagate to the global handler.
- [ ] The use-case has no `try/except`.
- [ ] Adapter does not log exceptions.
- [ ] No new `DomainError` subclass was added in the slice folder.

### Cache

- [ ] The `@cache` decorator is applied to the `GET /{username}/posts` endpoint
      in `presentation/router.py`.
- [ ] The cache key prefix is exactly
      `{username}_posts:page_{page}:items_per_page:{items_per_page}` — matches
      the pattern targeted by existing `patch_post` and `erase_post` invalidators.
- [ ] `expiration=60` is set on the `@cache` decorator.
- [ ] `request: Request` is the first parameter of the endpoint function
      (required by the `@cache` decorator).

### Files and headers

- [ ] Every new `.py` file in `list_posts/` starts with
      `# FEATURE: list_posts — <purpose>` on line 1.
- [ ] `features/posts/router.py` now includes the `list_posts` router via
      `router.include_router(list_posts_router)` and the `read_posts` handler
      has been removed.
- [ ] `bootstrap/container.py` has `list_posts_adapter` and `list_posts_use_case`
      providers added.
- [ ] `bootstrap/router.py` is **unchanged**.
- [ ] Pydantic presentation schemas (`PostItemSchema`, `ListPostsResponse`) carry
      `model_config = ConfigDict(from_attributes=True)`.
- [ ] No `model.dict()` — only `model.model_dump()` if used.

### DI

- [ ] `list_posts_adapter` provider in `Container` is a `providers.Factory` that
      receives `session_factory`.
- [ ] `list_posts_use_case` provider in `Container` is a `providers.Factory` that
      receives `list_posts_adapter`.
- [ ] The router uses the `_get_list_posts_use_case()` lazy-import helper pattern
      (consistent with other slice routers in this codebase) — not the
      `Provide[Container.list_posts_use_case]` pattern, since `wiring_config` is
      not configured in the container.

### Tests

- [ ] Use-case unit test exists at
      `tests/features/posts/0009_list_posts/domain/test_use_case.py` and passes.
- [ ] Adapter unit test exists at
      `tests/features/posts/0009_list_posts/data/test_adapter.py`, uses real
      Postgres, covers: happy path with JOIN result, empty result for unknown
      username, empty result for user with no posts, exclusion of soft-deleted
      posts, exclusion of posts from soft-deleted users, and correct pagination.
- [ ] Endpoint integration test exists at
      `tests/features/posts/0009_list_posts/presentation/test_router.py` and uses
      `httpx.AsyncClient` with `db_session`.
- [ ] Outside-in test exists at
      `tests/features/posts/0009_list_posts/list_posts_outside_in_test.py` and is
      **GREEN**.
- [ ] No test calls `session.commit()` (defeats rollback fixture).

### Quality gates

Run from project root:

```
ruff format src/app tests
ruff check src/app tests
mypy src/app
pytest
```

All must pass. The smoke test (`tests/smoke/test_app_starts.py`) boots the app
via a real uvicorn subprocess. If it fails after this slice's changes are added,
the most likely cause is a relative import mistakenly written as an absolute
import inside `src/app/` — check every new file's import lines.
