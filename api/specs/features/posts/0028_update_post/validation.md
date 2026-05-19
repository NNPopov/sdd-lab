# 0028 · update_post — Validation

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md
- Requirements: ./requirements.md

## Prerequisites

- App running locally: `uvicorn src.app.main:app --reload` from the project root.
- Test Postgres running and migrated (`alembic upgrade head`).
- A user created and a valid Bearer token obtained via `POST /api/v1/login`.
- A post created under that user via `POST /api/v1/{username}/post` (status must be `approved` or owned by the requester for GET to return it).
- A second user created for ownership-mismatch scenarios.
- Variables used in curl examples below:
  - `TOKEN` — Bearer token for the primary user (`alice`)
  - `TOKEN2` — Bearer token for the second user (`bob`)
  - `USERNAME` — `alice`
  - `POST_ID` — integer id of the post created under `alice`

---

## Manual scenarios

### S1 — Happy path: partial update (title only)

**Steps:**

```bash
curl -s -X PATCH http://localhost:8000/api/v1/alice/post/$POST_ID \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"title": "Updated title"}'
```

**Expected:**

- Status `200`.
- Body: `{"message": "Post updated"}`.
- `GET /api/v1/alice/post/$POST_ID` returns the post with `title` changed to `"Updated title"` and `text`, `media_url` unchanged.
- `updated_at` field on the post is now populated.

**Covers:** F1, F9.

---

### S2 — Happy path: update all fields

**Steps:**

```bash
curl -s -X PATCH http://localhost:8000/api/v1/alice/post/$POST_ID \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"title": "New title", "text": "New body text.", "media_url": "https://example.com/img.png"}'
```

**Expected:**

- Status `200`.
- Body: `{"message": "Post updated"}`.
- Subsequent GET returns all three fields updated.

**Covers:** F1, F9.

---

### S3 — Happy path: empty body (no-op update)

**Steps:**

```bash
curl -s -X PATCH http://localhost:8000/api/v1/alice/post/$POST_ID \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{}'
```

**Expected:**

- Status `200`.
- Body: `{"message": "Post updated"}`.
- Post fields unchanged; `updated_at` is set (the update still runs).

**Covers:** F1, F9.

---

### S4 — Unauthenticated request

**Steps:**

```bash
curl -s -X PATCH http://localhost:8000/api/v1/alice/post/$POST_ID \
  -H "Content-Type: application/json" \
  -d '{"title": "Should fail"}'
```

**Expected:**

- Status `401`.
- Body contains a `message` field explaining missing/invalid credentials.

**Covers:** F2.

---

### S5 — Forbidden: authenticated as wrong user

**Steps:**

```bash
curl -s -X PATCH http://localhost:8000/api/v1/alice/post/$POST_ID \
  -H "Authorization: Bearer $TOKEN2" \
  -H "Content-Type: application/json" \
  -d '{"title": "Attempted hijack"}'
```

**Expected:**

- Status `403`.
- Body: `{"message": ""}` or similar forbidden message.
- Post title unchanged (verify with GET using `$TOKEN`).

**Covers:** F4.

---

### S6 — Not found: username does not exist

**Steps:**

```bash
curl -s -X PATCH http://localhost:8000/api/v1/nonexistent_user/post/$POST_ID \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"title": "Ghost"}'
```

**Expected:**

- Status `404`.
- Body: `{"message": "User not found"}`.

**Covers:** F3.

---

### S7 — Not found: post id does not exist

**Steps:**

```bash
curl -s -X PATCH http://localhost:8000/api/v1/alice/post/999999 \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"title": "Ghost post"}'
```

**Expected:**

- Status `404`.
- Body: `{"message": "Post not found"}`.

**Covers:** F5.

---

### S8 — Validation failure: title too short

**Steps:**

```bash
curl -s -X PATCH http://localhost:8000/api/v1/alice/post/$POST_ID \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"title": "x"}'
```

**Expected:**

- Status `422`.
- Body contains Pydantic validation error naming the `title` field.

**Covers:** F11.

---

### S9 — Validation failure: invalid media_url

**Steps:**

```bash
curl -s -X PATCH http://localhost:8000/api/v1/alice/post/$POST_ID \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"media_url": "not-a-url"}'
```

**Expected:**

- Status `422`.
- Body contains Pydantic validation error naming the `media_url` field.

**Covers:** F11.

---

### S10 — Cache invalidation: GET reflects PATCH

**Steps:**

1. `GET /api/v1/alice/post/$POST_ID` — note the current `title`. The result is cached.
2. `PATCH /api/v1/alice/post/$POST_ID` with `{"title": "Cache-busted title"}`.
3. `GET /api/v1/alice/post/$POST_ID` — verify the new title is returned, not the stale cached value.

**Expected:**

- Third response shows `"Cache-busted title"`, not the old value, confirming the `@cache` decorator invalidated the key on PATCH.

**Covers:** F10.

---

## Code review checklist

### Architecture

- [ ] Slice folder exists at `src/app/features/posts/update_post/` with `domain/`, `data/`, `presentation/` subfolders.
- [ ] `UpdatePostUseCase` is a class with `__call__(command: UpdatePostCommand) -> None`; called as `await use_case(command)`.
- [ ] `UpdatePostPort` lives in `domain/ports/update_post_port.py`, carries `@runtime_checkable`, and inherits from `typing.Protocol`.
- [ ] `UpdatePostAdapter` signature is `class UpdatePostAdapter(UpdatePostPort):` — explicit inheritance from the port is mandatory.
- [ ] Adapter is the only place SQLAlchemy is used in the slice.
- [ ] Router converts `UpdatePostRequest` → `UpdatePostCommand`, awaits use-case, returns `UpdatePostResponse`. No business logic in the router.
- [ ] No cross-slice imports. `PostAuthor` and `PostItem` are imported from `posts/_shared/entities.py`. No imports from `create_post/`, `get_post/`, or any other sibling slice's `domain/`, `data/`, or `presentation/`.
- [ ] All imports inside `src/app/` are **relative**. No `from app...` or `from src.app...` anywhere in the new source files.
- [ ] No `HTTPException` raised inside `UpdatePostUseCase`.
- [ ] `PostAuthor` is defined once in `posts/_shared/entities.py` and the local copy in `create_post/domain/entities.py` is removed (replaced with a relative `_shared` import).

### Error handling

- [ ] `get_user_by_username` and `get_post_by_id` adapter methods have **no `try/except`** — read-only, nothing business-meaningful to translate.
- [ ] `update` adapter method has **no `try/except`** — a plain UPDATE on owned content cannot raise a domain-meaningful integrity error; infrastructure failures propagate to the global handler.
- [ ] No broad `except Exception` blocks in any adapter method.
- [ ] Adapter does **not** log exceptions.
- [ ] No new `DomainError` subclass added in the slice folder. Only existing subclasses (`NotFoundDomainError`, `ForbiddenDomainError`) are used.

### Files and headers

- [ ] Every new `.py` file starts with `# FEATURE: update_post — <purpose>` on line 1.
- [ ] `posts/_shared/entities.py` header remains `# FEATURE: posts._shared — ...`.
- [ ] No STABLE file was modified beyond `bootstrap/container.py` (two new providers + wiring entry).
- [ ] `UpdatePostRequest` uses `model_config = ConfigDict(extra="forbid")`.
- [ ] `PostAuthor` and `PostItem` use `model_config = ConfigDict(from_attributes=True)`.
- [ ] No `model.dict()` — only `model.model_dump()`.

### DI

- [ ] `update_post_adapter` provider added to `Container` as `providers.Factory(UpdatePostAdapter, session_factory=session_factory)`.
- [ ] `update_post_use_case` provider added to `Container` as `providers.Factory(UpdatePostUseCase, port=update_post_adapter)`.
- [ ] Router module path `app.features.posts.update_post.presentation.router` added to `Container.wiring_config.modules`.
- [ ] Endpoint uses `Annotated[UpdatePostUseCase, Depends(Provide[Container.update_post_use_case])]`.

### Router migration

- [ ] `update_post_router` is `include_router`'d in `features/posts/router.py`.
- [ ] The old inline `patch_post` handler (lines 35–57 of the original `router.py`) is deleted.
- [ ] Unused imports (`PostUpdate`, etc.) removed from `features/posts/router.py` if no longer referenced by remaining inline handlers.

### Cache

- [ ] `@cache("{username}_post_cache", resource_id_name="id", pattern_to_invalidate_extra=["{username}_posts:*"])` is applied to the endpoint.
- [ ] `request: Request` is the first parameter of the endpoint function (required by the `@cache` decorator).
- [ ] Decorator order on the endpoint is: `@router.patch` → `@cache` → `@inject`.

### Tests

- [ ] Use-case unit test covers: user not found → 404, ownership mismatch → 403, post not found → 404, happy path calls `port.update`.
- [ ] Adapter unit test covers: `get_user_by_username` (found / not found / soft-deleted), `get_post_by_id` (found / not found / soft-deleted), `update` (fields written + `updated_at` set).
- [ ] Endpoint integration test covers: 200, 401, 403, 404 (user), 404 (post), 422.
- [ ] Outside-in test exists, is GREEN, and confirms the full path (PATCH then GET shows updated value).
- [ ] No test calls `session.commit()` directly — relies on the `db_session` fixture rollback.

### Quality gates

Run from the project root and confirm all pass:

```
ruff format src/app tests
ruff check src/app tests
mypy src/app
pytest
```

The smoke test (`tests/smoke/test_app_starts.py`) boots the app as `uvicorn` would. If it fails after this slice, the most likely cause is an accidental `from app...` absolute import inside one of the new source files.
