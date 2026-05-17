# 0011 · create_post — Validation

## Inputs

- PRD: ./prd.md
- Plan: ./plan.md
- Requirements: ./requirements.md

## Prerequisites

- App running locally: `uvicorn app.main:app --reload` (from `src/`).
- Test database running and migrated (`alembic upgrade head`).
- At least one active user seeded. Replace `<TOKEN>` with a valid Bearer token
  obtained via `POST /api/v1/login`. Replace `alice` with the seeded username.
- A second user seeded for ownership-mismatch scenarios. Replace `<OTHER_TOKEN>`
  with that user's Bearer token.

## Manual scenarios

### S1 — Happy path: create post under own username

**Steps:**

```bash
curl -s -X POST http://localhost:8000/api/v1/alice/post \
  -H "Authorization: Bearer <TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{"title": "Hello world", "text": "My first post body.", "media_url": null}'
```

**Expected:**

- Status 201.
- Body is JSON with fields `id` (int), `title` ("Hello world"), `text` ("My first post body."),
  `media_url` (null), `created_by_user_id` (int matching alice's id), `created_at` (ISO datetime).
- No extra internal fields (e.g. `uuid`, `is_deleted`) appear in the response.

**Covers:** F1, F6, F9, F10, F13, F14.

---

### S2 — Happy path: create post with optional media_url

**Steps:**

```bash
curl -s -X POST http://localhost:8000/api/v1/alice/post \
  -H "Authorization: Bearer <TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{"title": "With media", "text": "See the image.", "media_url": "https://example.com/img.png"}'
```

**Expected:**

- Status 201.
- Body contains `"media_url": "https://example.com/img.png"`.

**Covers:** F4, F1.

---

### S3 — Happy path: media_url omitted entirely

**Steps:**

```bash
curl -s -X POST http://localhost:8000/api/v1/alice/post \
  -H "Authorization: Bearer <TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{"title": "No media", "text": "Plain text post."}'
```

**Expected:**

- Status 201.
- Body contains `"media_url": null`.

**Covers:** F4.

---

### S4 — Unknown username returns 404

**Steps:**

```bash
curl -s -X POST http://localhost:8000/api/v1/nonexistent_user_xyz/post \
  -H "Authorization: Bearer <TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{"title": "Test", "text": "Body text."}'
```

**Expected:**

- Status 404.
- Body `{"message": "User not found"}`.

**Covers:** F7, F11.

---

### S5 — Ownership mismatch returns 403

**Steps:**

1. Ensure `alice` and `bob` both exist as active users.
2. Obtain a token for `bob`.

```bash
curl -s -X POST http://localhost:8000/api/v1/alice/post \
  -H "Authorization: Bearer <BOB_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{"title": "Test", "text": "Body text."}'
```

**Expected:**

- Status 403.
- Body `{"message": "You can only post under your own username"}`.

**Covers:** F8.

---

### S6 — Missing required field `title` returns 422

**Steps:**

```bash
curl -s -X POST http://localhost:8000/api/v1/alice/post \
  -H "Authorization: Bearer <TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{"text": "Missing title."}'
```

**Expected:**

- Status 422.
- Body contains Pydantic validation error referencing `title`.

**Covers:** F2.

---

### S7 — Missing required field `text` returns 422

**Steps:**

```bash
curl -s -X POST http://localhost:8000/api/v1/alice/post \
  -H "Authorization: Bearer <TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{"title": "No body"}'
```

**Expected:**

- Status 422.
- Body contains Pydantic validation error referencing `text`.

**Covers:** F3.

---

### S8 — Empty title returns 422

**Steps:**

```bash
curl -s -X POST http://localhost:8000/api/v1/alice/post \
  -H "Authorization: Bearer <TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{"title": "", "text": "Body text."}'
```

**Expected:**

- Status 422.
- Body contains Pydantic validation error referencing `title`.

**Covers:** F2.

---

### S9 — Unknown extra field returns 422

**Steps:**

```bash
curl -s -X POST http://localhost:8000/api/v1/alice/post \
  -H "Authorization: Bearer <TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{"title": "Test", "text": "Body text.", "unknown_field": "oops"}'
```

**Expected:**

- Status 422.
- Body references the extra field `unknown_field`.

**Covers:** F5.

---

### S10 — No auth token returns 401

**Steps:**

```bash
curl -s -X POST http://localhost:8000/api/v1/alice/post \
  -H "Content-Type: application/json" \
  -d '{"title": "Test", "text": "Body text."}'
```

**Expected:**

- Status 401 or 403 (depending on OAuth2 dependency behaviour).
- No post is created in the database.

**Covers:** F6 (auth dependency gate).

---

### S11 — Old write_post handler is no longer reachable

**Steps:**

1. Confirm that `GET /api/v1/docs` (or `/openapi.json`) lists `POST /{username}/post`
   only once in the OpenAPI schema, served by `create_post_endpoint`.
2. Confirm there is no duplicate route registration for this path in the app.

**Expected:**

- Exactly one route entry for `POST /{username}/post`.
- The old `write_post` function is not importable from `features/posts/router.py`.

**Covers:** F15.

---

### S12 — DI container resolves correctly on startup

**Steps:**

```bash
curl -s http://localhost:8000/api/v1/health
```

**Expected:**

- Status 200.
- App started without import errors, container wiring errors, or missing provider errors.

**Covers:** F16.

## Code review checklist

For the reviewer (human or AI) to verify on the PR. Each line is a yes/no question.
Reject the PR until all are yes.

### Architecture

- [ ] Slice folder exists at `src/app/features/posts/create_post/` with `domain/`,
      `data/`, and `presentation/` subfolders.
- [ ] `CreatePostUseCase` is a class with a single public method `__call__(command:
      CreatePostCommand) -> CreatedPost`; invoked as `await use_case(command)`.
- [ ] `CreatePostPort` lives in `domain/ports/create_post_port.py`, carries
      `@runtime_checkable`, and inherits from `typing.Protocol`.
- [ ] `CreatePostAdapter` class signature is `class CreatePostAdapter(CreatePostPort):` —
      explicit inheritance from the port.
- [ ] `CreatePostAdapter` is the only file that imports SQLAlchemy models (`Post`, `User`).
- [ ] The router function converts `(username, current_user["username"], request fields)` →
      `CreatePostCommand`, awaits the use-case, converts `CreatedPost` →
      `CreatePostResponse`; no business logic in the router.
- [ ] No cross-slice imports outside the feature's `_shared/` (none expected for this slice).
- [ ] All imports inside `src/app/features/posts/create_post/` are **relative**
      (`from ..domain...`, `from .....bootstrap...`). No `from app...` or `from src.app...`
      anywhere inside `src/app/`.
- [ ] No `HTTPException` raised inside `CreatePostUseCase`.
- [ ] No `try/except` block in `CreatePostUseCase`.
- [ ] `features/posts/router.py` no longer defines `write_post`; `POST /{username}/post`
      is handled exclusively by `create_post_router`.
- [ ] `PostCreate` and `PostCreateInternal` remain in `posts/schemas.py` (not deleted).

### Error handling

- [ ] `CreatePostAdapter.get_user_by_username` has **no `try/except`** — it is a
      read-only SELECT; infrastructure failures propagate to the global handler.
- [ ] `CreatePostAdapter.create` has **no `try/except`** — no unique constraint maps to
      a business-meaningful domain concept for this operation; infrastructure failures
      propagate unchanged.
- [ ] No new `DomainError` subclass was added in the slice folder; only the existing
      `NotFoundDomainError` and `ForbiddenDomainError` from `app/domain/errors.py` are used.
- [ ] No `UnknownDomainError` or any catch-all domain error is introduced.
- [ ] `CreatePostAdapter` does not call `logger.error` or any logging function.

### Files and headers

- [ ] Every new `.py` file in `features/posts/create_post/` starts with
      `# FEATURE: create_post — <purpose>` on line 1.
- [ ] `bootstrap/container.py` was modified only by appending two new providers
      (`create_post_adapter`, `create_post_use_case`) and their two import lines.
      No other STABLE file was modified.
- [ ] `PostAuthor` and `CreatedPost` entities use
      `model_config = ConfigDict(from_attributes=True)`.
- [ ] `CreatePostResponse` uses `model_config = ConfigDict(from_attributes=True)`.
- [ ] No `model.dict()` used anywhere; only `model.model_dump()`.

### DI

- [ ] `create_post_adapter` provider is added to `Container` as `providers.Factory(
      CreatePostAdapter, session_factory=session_factory)`.
- [ ] `create_post_use_case` provider is added to `Container` as `providers.Factory(
      CreatePostUseCase, port=create_post_adapter)`.
- [ ] The router uses a local factory function `_get_create_post_use_case()` that
      calls `container.create_post_use_case()` — matching the `list_posts`/`list_all_posts`
      pattern. No `Provide[Container.xxx]` wiring is needed for this project.

### Tests

- [ ] Use-case unit test exists at
      `tests/features/posts/0011_create_post/domain/test_use_case.py` and passes.
- [ ] Use-case unit test covers: `None` from port → `NotFoundDomainError`;
      username mismatch → `ForbiddenDomainError`; happy path → `port.create` called
      with correct `CreatePostInternalCommand`.
- [ ] Adapter unit test exists at
      `tests/features/posts/0011_create_post/data/test_adapter.py` and passes against
      the test Postgres database.
- [ ] Adapter unit test covers: active user found, soft-deleted user returns `None`,
      unknown username returns `None`, `create` returns correct `CreatedPost`.
- [ ] Endpoint integration test exists at
      `tests/features/posts/0011_create_post/presentation/test_router.py` and uses
      `httpx.AsyncClient` against the running app with test Postgres.
- [ ] Outside-in test at
      `tests/features/posts/0011_create_post/create_post_outside_in_test.py` is GREEN.
- [ ] No test leaves uncommitted rows in the database (transaction rollback pattern used).

### Quality gates

Run from project root before approving:

```bash
ruff format src/app tests
ruff check src/app tests
mypy src/app
pytest
```

All must pass. The smoke test (`tests/smoke/test_app_starts.py`) boots the app in a
subprocess and pings `/api/v1/health`. If it fails, the slice is **not done** — it
typically means an accidental absolute import inside `src/app/` that works under pytest
but breaks under uvicorn.
