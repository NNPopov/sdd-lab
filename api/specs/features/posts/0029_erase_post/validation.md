# 0029 · erase_post — Validation

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md
- Requirements: ./requirements.md

## Prerequisites

- App running locally (`uvicorn app.main:app --reload` from `src/`).
- Test Postgres and Redis reachable (env vars from `.env`).
- Two users seeded: **alice** and **bob**, each with a valid Bearer token.
- A post created by alice (obtain `{alice_post_id}` from the create response).

Seed commands (adapt credentials to local `.env`):

```bash
# Register alice
curl -s -X POST http://localhost:8000/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{"username": "alice", "email": "alice@example.com", "password": "AlicePass1!"}'

# Register bob
curl -s -X POST http://localhost:8000/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{"username": "bob", "email": "bob@example.com", "password": "BobPass1!"}'

# Login as alice → save token
ALICE_TOKEN=$(curl -s -X POST http://localhost:8000/api/v1/login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=alice&password=AlicePass1!" | jq -r '.access_token')

# Login as bob → save token
BOB_TOKEN=$(curl -s -X POST http://localhost:8000/api/v1/login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=bob&password=BobPass1!" | jq -r '.access_token')

# Alice creates a post → save id
ALICE_POST_ID=$(curl -s -X POST http://localhost:8000/api/v1/alice/posts \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ALICE_TOKEN" \
  -d '{"title": "Hello", "text": "World"}' | jq -r '.id')
```

## Manual scenarios

### S1 — Happy path: owner deletes own post

**Steps:**

```bash
curl -s -X DELETE "http://localhost:8000/api/v1/alice/post/$ALICE_POST_ID" \
  -H "Authorization: Bearer $ALICE_TOKEN"
```

**Expected:**

- Status `200`.
- Body `{"message": "Post deleted"}`.
- DB: `posts` row with `id = $ALICE_POST_ID` has `is_deleted = true` and
  `deleted_at` is non-null.

**Covers:** F1, F6, F9.

---

### S2 — Unauthenticated request

**Steps:**

```bash
curl -s -o /dev/null -w "%{http_code}" \
  -X DELETE "http://localhost:8000/api/v1/alice/post/$ALICE_POST_ID"
```

**Expected:**

- Status `401`.

**Covers:** F2.

---

### S3 — Unknown username in path

**Steps:**

```bash
curl -s -X DELETE "http://localhost:8000/api/v1/nobody/post/$ALICE_POST_ID" \
  -H "Authorization: Bearer $ALICE_TOKEN"
```

**Expected:**

- Status `404`.
- Body contains `"message": "User not found"`.

**Covers:** F3.

---

### S4 — Requester is not the path user (forbidden)

**Steps:**

```bash
# Bob is authenticated but the path names alice
curl -s -X DELETE "http://localhost:8000/api/v1/alice/post/$ALICE_POST_ID" \
  -H "Authorization: Bearer $BOB_TOKEN"
```

**Expected:**

- Status `403`.
- Body contains `"message"` key (exact wording from `ForbiddenDomainError()`
  default).

**Covers:** F4, F10.

---

### S5 — Post id does not exist

**Steps:**

```bash
curl -s -X DELETE "http://localhost:8000/api/v1/alice/post/99999" \
  -H "Authorization: Bearer $ALICE_TOKEN"
```

**Expected:**

- Status `404`.
- Body contains `"message": "Post not found"`.

**Covers:** F5.

---

### S6 — Post exists but belongs to a different user (ownership gap fix)

**Steps:**

```bash
# Bob tries to delete alice's post using his own path segment
curl -s -X DELETE "http://localhost:8000/api/v1/bob/post/$ALICE_POST_ID" \
  -H "Authorization: Bearer $BOB_TOKEN"
```

**Expected:**

- Status `404`.
- Body contains `"message": "Post not found"` (not 403; post ownership is
  enforced by the DB filter, so the post simply isn't found under bob).

**Covers:** F5, F8.

---

### S7 — Cache invalidated after deletion

**Steps:**

1. Ensure `$ALICE_POST_ID` is not yet deleted (or recreate the post).
2. Warm the cache with a GET:
   ```bash
   curl -s "http://localhost:8000/api/v1/alice/post/$ALICE_POST_ID"
   ```
3. Delete the post (S1).
4. Re-issue the GET:
   ```bash
   curl -s -o /dev/null -w "%{http_code}" \
     "http://localhost:8000/api/v1/alice/post/$ALICE_POST_ID"
   ```

**Expected:**

- Step 2: Status `200` (or `404` if post is not approved and caller is not
  privileged — ensure status is `approved` if testing cache directly, or use
  alice's token).
- Step 4: Status `404` (cache entry for the post is invalidated; subsequent
  read finds no live row).

**Covers:** F11.

---

### S8 — Delete already-deleted post

**Steps:**

1. Run S1 to delete the post.
2. Attempt to delete the same post again:
   ```bash
   curl -s -X DELETE "http://localhost:8000/api/v1/alice/post/$ALICE_POST_ID" \
     -H "Authorization: Bearer $ALICE_TOKEN"
   ```

**Expected:**

- Status `404`.
- Body contains `"message": "Post not found"` (soft-deleted post is filtered
  out by `is_deleted == False` in `find_post`).

**Covers:** F5, F8.

## Code review checklist

### Architecture

- [ ] Slice folder exists at `src/app/features/posts/erase_post/` with
      `domain/`, `data/`, `presentation/` subfolders and `__init__.py` in
      each.
- [ ] `posts/_shared/policies.py` is created with `check_post_owner`; no
      logic is duplicated inside the use case itself.
- [ ] `ErasePostUseCase` is a class with `__call__(command) -> None`; called
      as `await use_case(command)`.
- [ ] `ErasePostPort` lives in `domain/ports/erase_post_port.py`, carries
      `@runtime_checkable`, and inherits from `typing.Protocol`.
- [ ] `class ErasePostAdapter(ErasePostPort):` — explicit port inheritance is
      present on the class line.
- [ ] `ErasePostAdapter` is the only place `SQLAlchemy` is touched for this
      slice.
- [ ] Router converts path params + auth dict to `ErasePostCommand`, awaits
      use case, returns `ErasePostResponse(message="Post deleted")`. No
      business logic in the router.
- [ ] No import from any other slice's `domain/`, `data/`, or
      `presentation/` directory (only `posts/_shared/` imports are allowed
      across slices within the posts feature).
- [ ] All imports inside `src/app/` are **relative** (`from ..domain...`,
      `from ...._shared...`). No `from app...` or `from src.app...` inside
      source files.
- [ ] No `HTTPException` raised inside `ErasePostUseCase`.

### Error handling

- [ ] `ErasePostAdapter` has **no `try/except`** block — a soft-delete UPDATE
      and read-only SELECTs have no business-meaningful exceptions to
      translate; infrastructure failures propagate to the global handler.
- [ ] `check_post_owner` raises `ForbiddenDomainError()` (no message needed
      beyond the HTTP 403 status); it does not catch any exception.
- [ ] No new `DomainError` subclass was added inside the `erase_post` slice
      folder; all domain errors live in `app/domain/errors.py`.
- [ ] No `UnknownDomainError` or similar catch-all domain error is introduced.
- [ ] Adapter does not log exceptions.

### Files and headers

- [ ] `posts/_shared/policies.py` starts with
      `# FEATURE: posts._shared — ownership policy.` on line 1.
- [ ] Every new `.py` file under `erase_post/` starts with
      `# FEATURE: erase_post — <purpose>.` on line 1.
- [ ] `PostAuthor` (returned by `get_user_by_username`) has
      `model_config = ConfigDict(from_attributes=True)` — already on the
      shared entity; verify it is not stripped.
- [ ] `ErasePostRecord` is a plain `BaseModel` with no `from_attributes`
      needed (it is constructed explicitly, not from an ORM row).
- [ ] No `model.dict()` usage; only `model.model_dump()`.
- [ ] No STABLE file was modified beyond `bootstrap/container.py` wiring
      entries.

### DI

- [ ] `erase_post_adapter = providers.Factory(ErasePostAdapter, session_factory=session_factory)`
      is present in `Container`.
- [ ] `erase_post_use_case = providers.Factory(ErasePostUseCase, port=erase_post_adapter)`
      is present in `Container`.
- [ ] `f"{_app_pkg}.features.posts.erase_post.presentation.router"` is in
      `Container.wiring_config.modules`.
- [ ] Endpoint uses `Annotated[ErasePostUseCase, Depends(Provide[Container.erase_post_use_case])]`.

### Cache

- [ ] `@cache` decorator is placed between `@router.delete(...)` and `@inject`
      (same order as `update_post` and the old flat `erase_post` function).
- [ ] Cache arguments match the old flat function exactly:
      `key_prefix="{username}_post_cache"`, `resource_id_name="id"`,
      `to_invalidate_extra={"{username}_posts": "{username}"}`.
- [ ] `request: Request` is the first parameter in the endpoint signature
      (required by the `@cache` decorator).

### Flat router cleanup

- [ ] The `erase_post` flat function and its `@router.delete` / `@cache`
      decorators are removed from `features/posts/router.py`.
- [ ] `ForbiddenDomainError` import is removed from `features/posts/router.py`
      if it was only used by `erase_post` (verify against `erase_db_post`).
- [ ] `from .erase_post.presentation.router import router as erase_post_router`
      and `router.include_router(erase_post_router)` are added.
- [ ] No other imports in `features/posts/router.py` were unintentionally
      removed (check that `erase_db_post` still compiles).

### Tests

- [ ] `tests/features/posts/0029_erase_post/domain/test_use_case.py` exists
      and covers all four branches (user not found, forbidden, post not found,
      happy path).
- [ ] `tests/features/posts/0029_erase_post/data/test_adapter.py` exists and
      covers `get_user_by_username` (active, missing, soft-deleted),
      `find_post` (found, missing, wrong owner, soft-deleted), and
      `soft_delete` (row state after call).
- [ ] `tests/features/posts/0029_erase_post/presentation/test_router.py`
      exists and covers 200, 401, 403, 404-user, 404-post.
- [ ] Outside-in test at
      `tests/features/posts/0029_erase_post/erase_post_outside_in_test.py`
      is GREEN.
- [ ] All pre-existing outside-in tests remain GREEN after the change.

### Quality gates

Run from project root and confirm all pass:

```bash
ruff format src/app tests
ruff check src/app tests
mypy src/app
pytest
```

The smoke test inside `pytest` (`tests/smoke/test_app_starts.py`) boots the
app in a subprocess and pings `/health`. If it fails the slice is **not done**
even if every other test is green — it usually indicates an import inside
`src/app/` that uses an absolute `from app...` path instead of a relative one.
