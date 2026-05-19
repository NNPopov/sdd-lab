# 0030 · erase_db_post — Validation

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md
- Requirements: ./requirements.md

## Prerequisites

- App running locally (`uvicorn src.app.main:app --reload` from the project
  root, or via Docker Compose).
- Test Postgres running and migrated (`alembic upgrade head`).
- Seed a regular user `alice` and a superuser `admin` (distinct username and
  email):

```bash
# Create alice (regular user)
curl -s -X POST http://localhost:8000/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{"username":"alice","email":"alice@example.com","password":"Password1!"}'

# Create admin (must be promoted to superuser directly in the DB, or via an
# existing admin endpoint if one exists)
curl -s -X POST http://localhost:8000/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","email":"admin@example.com","password":"Password1!"}'
```

- Obtain Bearer tokens:

```bash
ALICE_TOKEN=$(curl -s -X POST http://localhost:8000/api/v1/auth/token \
  -d "username=alice&password=Password1!" \
  -H "Content-Type: application/x-www-form-urlencoded" | jq -r .access_token)

ADMIN_TOKEN=$(curl -s -X POST http://localhost:8000/api/v1/auth/token \
  -d "username=admin&password=Password1!" \
  -H "Content-Type: application/x-www-form-urlencoded" | jq -r .access_token)
```

- Create a post as alice and capture its ID:

```bash
POST_ID=$(curl -s -X POST http://localhost:8000/api/v1/alice/post \
  -H "Authorization: Bearer $ALICE_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"title":"Test post","text":"Hello world","media_url":"https://example.com/img.jpg","tags":[],"post_type":"original"}' \
  | jq .id)
```

---

## Manual scenarios

### S1 — Happy path: superuser hard-deletes a valid post

**Steps:**

```bash
curl -s -X DELETE "http://localhost:8000/api/v1/alice/db_post/$POST_ID" \
  -H "Authorization: Bearer $ADMIN_TOKEN"
```

**Expected:**

- HTTP 200.
- Body: `{"message": "Post deleted from the database"}`.
- DB: no row in `post` with `id = $POST_ID` (the row is gone, not merely
  soft-deleted).

**Covers:** F1, F4, F7.

---

### S2 — Unknown username → 404

**Steps:**

```bash
curl -s -X DELETE "http://localhost:8000/api/v1/nobody/db_post/$POST_ID" \
  -H "Authorization: Bearer $ADMIN_TOKEN"
```

**Expected:**

- HTTP 404.
- Body: `{"message": "User not found"}`.

**Covers:** F2.

---

### S3 — Post does not exist → 404

**Steps:**

```bash
curl -s -X DELETE "http://localhost:8000/api/v1/alice/db_post/999999" \
  -H "Authorization: Bearer $ADMIN_TOKEN"
```

**Expected:**

- HTTP 404.
- Body: `{"message": "Post not found"}`.

**Covers:** F3.

---

### S4 — Wrong namespace: post belongs to a different user → 404

**Steps:**

1. Create a second user `bob` and a post as bob:

```bash
curl -s -X POST http://localhost:8000/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{"username":"bob","email":"bob@example.com","password":"Password1!"}'

BOB_TOKEN=$(curl -s -X POST http://localhost:8000/api/v1/auth/token \
  -d "username=bob&password=Password1!" \
  -H "Content-Type: application/x-www-form-urlencoded" | jq -r .access_token)

BOB_POST_ID=$(curl -s -X POST http://localhost:8000/api/v1/bob/post \
  -H "Authorization: Bearer $BOB_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"title":"Bob post","text":"Hi","media_url":"https://example.com/b.jpg","tags":[],"post_type":"original"}' \
  | jq .id)
```

2. Admin attempts to delete Bob's post through Alice's namespace:

```bash
curl -s -X DELETE "http://localhost:8000/api/v1/alice/db_post/$BOB_POST_ID" \
  -H "Authorization: Bearer $ADMIN_TOKEN"
```

**Expected:**

- HTTP 404.
- Body: `{"message": "Post not found"}`.
- DB: Bob's post row still exists.

**Covers:** F3, F11.

---

### S5 — Soft-deleted post → 404

**Steps:**

1. Alice soft-deletes her post first (using `DELETE /api/v1/alice/post/$POST_ID`).
2. Admin attempts to hard-delete the same post:

```bash
curl -s -X DELETE "http://localhost:8000/api/v1/alice/post/$POST_ID" \
  -H "Authorization: Bearer $ALICE_TOKEN"

curl -s -X DELETE "http://localhost:8000/api/v1/alice/db_post/$POST_ID" \
  -H "Authorization: Bearer $ADMIN_TOKEN"
```

**Expected:**

- Second call returns HTTP 404.
- Body: `{"message": "Post not found"}`.

**Covers:** F3.

---

### S6 — Non-superuser → 403

**Steps:**

```bash
curl -s -X DELETE "http://localhost:8000/api/v1/alice/db_post/$POST_ID" \
  -H "Authorization: Bearer $ALICE_TOKEN"
```

**Expected:**

- HTTP 403.

**Covers:** F8.

---

### S7 — Unauthenticated → 401

**Steps:**

```bash
curl -s -X DELETE "http://localhost:8000/api/v1/alice/db_post/$POST_ID"
```

**Expected:**

- HTTP 401.

**Covers:** F9.

---

### S8 — Cache invalidation: GET returns 404 after hard-delete

**Steps:**

1. Warm the cache: `GET /api/v1/alice/post/$POST_ID` (expects HTTP 200).
2. Admin hard-deletes: `DELETE /api/v1/alice/db_post/$POST_ID` (expects HTTP 200).
3. Repeat the GET:

```bash
curl -s -X GET "http://localhost:8000/api/v1/alice/post/$POST_ID" \
  -H "Authorization: Bearer $ALICE_TOKEN"
```

**Expected:**

- Step 1: HTTP 200 (post returned, potentially cached).
- Step 2: HTTP 200, `{"message": "Post deleted from the database"}`.
- Step 3: HTTP 404 (not served from stale cache).

**Covers:** F10.

---

## Code review checklist

### Architecture

- [ ] Slice folder exists at `src/app/features/posts/erase_db_post/` with
      `domain/`, `data/`, `presentation/` subfolders and `__init__.py` files.
- [ ] `EraseDbPostUseCase` is a class with `__call__(command: EraseDbPostCommand) -> None`.
- [ ] `EraseDbPostPort` lives in `domain/ports/erase_db_post_port.py`, carries
      `@runtime_checkable`, and inherits from `typing.Protocol`.
- [ ] `EraseDbPostPort` declares exactly three methods: `get_user_by_username`,
      `find_post`, `hard_delete`.
- [ ] `class EraseDbPostAdapter(EraseDbPostPort):` — explicit inheritance from
      the port is present (greppability + reader intent).
- [ ] `EraseDbPostAdapter` is the only place SQLAlchemy is used in this slice.
- [ ] Router accepts path params `username: str` and `id: int`, calls
      `get_current_superuser`, constructs `EraseDbPostCommand`, awaits use-case,
      returns `EraseDbPostResponse(message="Post deleted from the database")`.
- [ ] No cross-slice imports — only `posts/_shared/entities.py` (`PostAuthor`)
      is imported from outside this slice.
- [ ] All imports inside `src/app/` are relative (`from ..domain...`, etc.).
      No `from app...` or `from src.app...` anywhere in source files.
- [ ] `EraseDbPostUseCase` never raises `HTTPException`.
- [ ] No `try/except` in `EraseDbPostUseCase`.

### Error handling

- [ ] `EraseDbPostAdapter` contains **no `try/except` blocks** — there are no
      business-meaningful infrastructure exceptions to translate for a hard-delete.
- [ ] `find_post` filters by `Post.is_deleted.is_(False)` so soft-deleted posts
      return `None` (not a live-post result).
- [ ] `find_post` filters by `Post.created_by_user_id == owner_id` to close the
      ownership gap from the legacy flat function.
- [ ] `hard_delete` issues a permanent `DELETE FROM post WHERE id=:id` followed
      by `session.commit()` (not an UPDATE with `is_deleted=True`).
- [ ] `ForbiddenDomainError` is never raised by `EraseDbPostUseCase`. HTTP 403
      comes from `get_current_superuser` at the router layer, not the use case.
- [ ] Adapter does not log exceptions.
- [ ] No new `DomainError` subclass added inside the slice folder.

### Files and headers

- [ ] Every new `.py` file (commands, entities, port, use_case, adapter,
      schemas, router) starts with `# FEATURE: erase_db_post — <purpose>` on
      line 1.
- [ ] No STABLE file modified beyond `bootstrap/container.py` wiring entries
      and `.importlinter` `ignore_imports` line.
- [ ] `EraseDbPostResponse` uses `class EraseDbPostResponse(BaseModel): message: str`.
- [ ] `EraseDbPostCommand` uses two fields only: `username: str`, `post_id: int`.
      No `requester_username`.
- [ ] No `model.dict()` — only `model.model_dump()`.

### DI and import linter

- [ ] `erase_db_post_adapter` provider added to `Container` as
      `providers.Factory(EraseDbPostAdapter, session_factory=session_factory)`.
- [ ] `erase_db_post_use_case` provider added to `Container` as
      `providers.Factory(EraseDbPostUseCase, port=erase_db_post_adapter)`.
- [ ] `app.features.posts.erase_db_post.presentation.router` added to
      `Container.wiring_config.modules`.
- [ ] Router endpoint uses
      `Annotated[EraseDbPostUseCase, Depends(Provide[Container.erase_db_post_use_case])]`.
- [ ] `.importlinter` `ignore_imports` list contains
      `app.features.posts.erase_db_post.presentation.router -> app.bootstrap.container`.

### Flat router cleanup

- [ ] The `erase_db_post` function and its decorators have been removed from
      `src/app/features/posts/router.py`.
- [ ] `router.include_router(erase_db_post_router)` added to
      `features/posts/router.py`.
- [ ] Imports that were solely used by the removed flat function are cleaned up.

### Cache

- [ ] `@cache` decorator on `erase_db_post_endpoint` uses exactly
      `key_prefix="{username}_post_cache"`, `resource_id_name="id"`,
      `to_invalidate_extra={"{username}_posts": "{username}"}`.
- [ ] `request: Request` is the first parameter of `erase_db_post_endpoint`
      (required by the `@cache` decorator).

### Tests

- [ ] Use-case unit test exists at
      `tests/features/posts/0030_erase_db_post/domain/test_use_case.py` and passes.
- [ ] Adapter unit test exists at
      `tests/features/posts/0030_erase_db_post/data/test_adapter.py` and covers:
      `get_user_by_username` (active, missing, soft-deleted), `find_post`
      (found, missing, wrong owner, soft-deleted), `hard_delete` (row gone).
- [ ] Endpoint integration test exists at
      `tests/features/posts/0030_erase_db_post/presentation/test_router.py`
      and covers all seven status-code scenarios (F1, F2, F3, F8, F9, F11).
- [ ] Outside-in test exists at
      `tests/features/posts/0030_erase_db_post/erase_db_post_outside_in_test.py`
      and is GREEN.
- [ ] No test leaves rows in the DB (transaction rollback via `db_session` fixture).

### Quality gates

Run from project root:

```
ruff format src/app tests
ruff check src/app tests
mypy src/app
pytest
```

All must pass. The smoke test inside `pytest` (`tests/smoke/test_app_starts.py`)
boots the app via uvicorn in a subprocess and pings `/api/v1/health`. If it
fails, the slice is **not done** even if every other test is green — it catches
import paths that work under pytest but break under uvicorn (e.g. an accidental
`from app...` inside `src/app/`).
